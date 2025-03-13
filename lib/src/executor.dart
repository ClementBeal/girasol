import 'dart:async';
import 'dart:isolate';
import '../girasol.dart';
import 'scrapers/scraper.dart';
import 'utils/browser_http_client.dart';

/// Base class for crawling results
abstract class ParseResult {}

/// A result containing data extracted from a page
class ParsedData<T> extends ParseResult {
  final T data;
  ParsedData(this.data);
}

/// A result containing a discovered link to crawl
class ParsedLink extends ParseResult {
  final CrawlRequest request;
  ParsedLink(this.request);
}

class ParsedEmpty extends ParseResult {}

class _CrawlerInitMessage {
  final WebCrawler crawler;
  final SendPort resultPort;

  _CrawlerInitMessage({required this.crawler, required this.resultPort});
}

/// It's the orchestrator of the crawlers.
///
/// It will use the [crawlers], run them into separated environments
/// and passed their scraped items to the [pipelines].
class Girasol {
  ///
  final List<WebCrawler> crawlers;
  final Map<Type, List<Pipeline>> pipelines;

  /// This port will be used by the crawlers to send messages
  /// to the main isolate
  final ReceivePort _mainReceivePort = ReceivePort();

  final _workers = <_CrawlerWorker>[];

  Girasol({required this.crawlers, required this.pipelines});

  /// Executes all crawlers and their associated pipelines
  Future<void> execute() async {
    final workerFutures = <Future<void>>[];

    // creates all the crawler isolates
    for (final crawler in crawlers) {
      final worker = _CrawlerWorker(
        crawler: crawler,
        mainReceivePort: _mainReceivePort.sendPort,
      );

      _workers.add(worker);

      workerFutures.add(worker.spawn());
    }

    await Future.wait(workerFutures);

    _listenForResults();

    // wait for the completion of the crawlers
    await Future.wait(_workers.map((worker) => worker.completed));

    await _cleanup();
  }

  /// Kill the isolates and clean up the pipelines
  Future<void> _cleanup() async {
    _mainReceivePort.close();

    for (final worker in _workers) {
      worker.close();
    }

    final cleanFutures = <Future<void>>[];

    for (final MapEntry(:value) in pipelines.entries) {
      for (var p in value) {
        cleanFutures.add(p.clean());
      }
    }

    await Future.wait(cleanFutures);
  }

  /// When a message is received from a crawler, we pass it to the pipeline
  void _listenForResults() {
    _mainReceivePort.listen((message) async {
      if (message is ParsedData) {
        final dataType = message.data.runtimeType;
        final pipeline = pipelines[dataType];

        if (pipeline != null) {
          for (final p in pipeline) {
            await p.receiveData(message.data);
          }
        }
      }
    });
  }
}

class _CrawlerWorker {
  final WebCrawler crawler;

  /// Enable the sending of messages to the main isolate
  final SendPort mainReceivePort;

  final ReceivePort _responsePort = ReceivePort();

  Isolate? _isolate;
  final Completer<void> _completionCompleter = Completer<void>();

  _CrawlerWorker({required this.mainReceivePort, required this.crawler});

  /// Indicate if the crawler has completed his job
  Future<void> get completed => _completionCompleter.future;

  /// Close the isolate and so, kill the crawler
  void close() {
    _isolate?.kill(priority: Isolate.immediate);
    _responsePort.close();
  }

  /// Spawn an isolate that will run the [crawler]
  Future<void> spawn() async {
    _responsePort.listen(_handleResponsesFromIsolate);

    await Isolate.spawn(
      _startCrawlerIsolate,
      _CrawlerInitMessage(crawler: crawler, resultPort: _responsePort.sendPort),
    );
  }

  void _handleResponsesFromIsolate(dynamic message) {
    if (message is ParseResult) {
      // Forward parsed results to the main isolate
      mainReceivePort.send(message);
    } else if (message == "COMPLETED") {
      // Mark the crawler as completed
      if (!_completionCompleter.isCompleted) {
        _completionCompleter.complete();
      }
    }
  }

  /// Entry point for the crawler isolate
  static void _startCrawlerIsolate(_CrawlerInitMessage message) {
    print("Isolate created for the crawler : ${message.crawler.name}");

    final executor = _CrawlerExecutor(
      crawler: message.crawler as StaticWebCrawler,
      resultPort: message.resultPort,
    );

    // Run the crawler executor
    executor
        .run()
        .then((_) {
          message.resultPort.send("COMPLETED");
        })
        .catchError((e) {
          print("Error in crawler isolate: $e");
          message.resultPort.send("COMPLETED");
        });
  }
}

class _CrawlerExecutor {
  // TODO: in the future, when the BrowserCrawler is ready, replace the type here
  final StaticWebCrawler crawler;

  /// Enable the communication with the main isolate. This port will send
  /// the Items returned by the [crawler]
  final SendPort resultPort;

  /// All the non-visited URLs returned by the crawler
  /// They are visited during the second pass
  final nonVisitedUrls = <CrawlRequest>[];

  _CrawlerExecutor({required this.crawler, required this.resultPort});

  Future<void> run() async {
    try {
      // Setup phase
      final setupClient = BrowserHttpClient();
      await crawler.beforeCrawl(setupClient);
      setupClient.close();

      final batch = <CrawlRequest>[];

      // Visit all the URLs generated by the crawler and store the
      // returned URLS into [nonVisitedUrls]
      await for (final url in crawler.getUrls()) {
        batch.add(url);

        if (batch.length >= crawler.concurrentRequests) {
          await _processBatch(batch);

          batch.clear();
        }
      }

      // It's possible that the batch hasn't reach the limit of concurrent requests
      // If so, we process the incomplete batch
      if (batch.isNotEmpty) {
        await _processBatch(batch);
        batch.clear();
      }

      // We visit every non-visited urls
      while (nonVisitedUrls.isNotEmpty) {
        final url = nonVisitedUrls.removeAt(0);
        batch.add(url);

        if (batch.length >= crawler.concurrentRequests ||
            (batch.length < crawler.concurrentRequests &&
                nonVisitedUrls.isEmpty)) {
          await _processBatch(batch);

          batch.clear();
        }
      }
    } catch (e, stackTrace) {
      print('Error in crawler ${crawler.runtimeType}: $e');
      print(stackTrace);
    } finally {
      await _cleanup(crawler);
    }
  }

  /// Visit a batch of URLS and add the new urls to the [nonVisitedUrls].
  /// If the crawler has a delay between the batches, we wait.
  Future<void> _processBatch(List<CrawlRequest> batch) async {
    await Future.wait(
      batch.map((request) async {
        final result = await _processSingleUrl(request, crawler);

        if (result.newUrls.isNotEmpty) {
          nonVisitedUrls.addAll(result.newUrls);
        }
      }),
    );

    final delay = crawler.getDelayBetweenRequests();

    if (delay != Duration.zero) {
      await Future.delayed(delay);
    }
  }

  /// Process a single URL and return its results
  Future<_UrlProcessResult> _processSingleUrl(
    CrawlRequest request,
    WebCrawler crawler,
  ) async {
    final newUrls = <CrawlRequest>[];

    try {
      final client = BrowserHttpClient(additionalHeaders: crawler.getHeaders());

      print("Parsing URL: ${request.url.toString()}");
      final response = await client.send(request);

      final contentType =
          response.headers["Content-Type"] ??
          response.headers["content-type"] ??
          "";

      final document = switch (contentType) {
        String type when type.contains("text/html") => HTMLDocument.body(
          response.body,
        ),
        String type when type.contains("application/json") => JsonDocument.body(
          response.body,
        ),
        String type when type.contains("text/plain") => TextDocument.body(
          response.body,
        ),
        String type
            when type.contains("image/") ||
                type.contains("video/") ||
                type.contains("application/octet-stream") =>
          FileDocument.body(response.bodyBytes),
        _ => HTMLDocument.body(response.body),
      };

      final responseStream = crawler.parseResponse(response, document);

      // Process each result
      await for (final ParseResult result in responseStream) {
        if (result is ParsedLink) {
          newUrls.add(result.request);
        } else if (result is ParsedData) {
          resultPort.send(result);
        }
      }

      client.close();
    } catch (e, stackTrace) {
      print('Error processing URL ${request.url}: $e');
      print(stackTrace);
    }

    return _UrlProcessResult(newUrls: newUrls);
  }

  /// Clean up resources after crawling
  Future<void> _cleanup(WebCrawler crawler) async {
    try {
      await crawler.afterCrawl();
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }
}

/// Helper class to track processing results
class _UrlProcessResult {
  final List<CrawlRequest> newUrls;

  _UrlProcessResult({required this.newUrls});
}
