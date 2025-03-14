import 'dart:convert';
import 'dart:typed_data';

import '../executor.dart';
import '../utils/browser_http_client.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

abstract class WebCrawler<ParsedItem> {
  /// If the HTTP client receive a 3XX code, you can decide if
  /// the client should follow the redirection or not
  final bool shouldFollowRedirects;

  /// Give a name to the crawler. Used by the logger
  final String name;

  WebCrawler({this.shouldFollowRedirects = true, required this.name});

  /// Define the headers that the HTTP client should send to the pages
  Map<String, String> getHeaders() {
    return {};
  }

  /// Generate the URLS to be visited by the executor.
  ///
  /// The URLS are gathered one by one.
  Stream<CrawlRequest> getUrls();

  /// Parse the response returned by the HTML client.
  ///
  /// It contains a [response] with the information of the HTTP request/response
  /// and a [document] that can be used to query the DOM
  Stream<ParseResult> parseResponse(
    CrawlResponse response,
    CrawlDocument document,
  );

  /// Prepare the crawler before the crawling. It can be use to call a database
  /// or to fetch an initial page with [httpClient]
  Future<void> beforeCrawl(BrowserHttpClient httpClient);

  /// Execute code when the crawler has done his job
  Future<void> afterCrawl();

  /// Define the duration to wait between 2 requests.
  /// It is always called so the delay can be dynamic.
  Duration getDelayBetweenRequests();
}

/// The static web crawler is a crawler that is based on HTTP requests only.
/// It's light and fast but it cannot run Javascript.
///
/// You should use it to crawl an API or a static website.
abstract class StaticWebCrawler<ParsedItem> extends WebCrawler<ParsedItem> {
  final int concurrentRequests;

  /// Limits how many levels deep the crawler will go when following links.
  /// If null, it will keep crawling without a depth limit.
  final int? maxDepth;

  StaticWebCrawler({
    super.shouldFollowRedirects = true,
    required super.name,
    this.concurrentRequests = 1,
    this.maxDepth,
  });

  @override
  Future<void> beforeCrawl(BrowserHttpClient httpClient) async {}

  @override
  Future<void> afterCrawl() async {}

  @override
  Duration getDelayBetweenRequests() {
    return Duration.zero;
  }
}

sealed class CrawlDocument {}

class HTMLDocument extends CrawlDocument {
  final Document document;

  HTMLDocument.body(String body) : document = parse(body);
}

class JsonDocument extends CrawlDocument {
  final dynamic data;

  JsonDocument.body(String body) : data = jsonDecode(body);
}

class FileDocument extends CrawlDocument {
  final Uint8List blob;

  FileDocument.body(this.blob);
}

class TextDocument extends CrawlDocument {
  final String text;

  TextDocument.body(this.text);
}
