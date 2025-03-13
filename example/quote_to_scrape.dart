import 'package:girasol/src/executor.dart';
import 'package:girasol/src/pipelines/format/json_pipeline.dart';
import 'package:girasol/src/scrapers/scraper.dart';
import 'package:girasol/src/utils/browser_http_client.dart';

class Quote implements JsonItem {
  final String author;
  final List<String> tags;
  final String quote;

  Quote({required this.author, required this.tags, required this.quote});

  @override
  Map<String, dynamic> toJson() => {
    "author": author,
    "tags": tags,
    "quote": quote,
  };
}

class QuoteCrawler extends StaticWebCrawler<Quote> {
  QuoteCrawler() : super(name: "Quotes");

  @override
  Stream<CrawlRequest> getUrls() async* {
    for (int i = 1; i < 10; i++) {
      yield CrawlRequest.get(Uri.parse("http://quotes.toscrape.com/page/$i/"));
    }
  }

  @override
  parseResponse(CrawlResponse response, CrawlDocument document) async* {
    if (document is! HTMLDocument) return;

    final dom = document.document;

    final cards = dom.querySelectorAll("div.quote");

    for (final card in cards) {
      yield ParsedData(
        Quote(
          author: card.querySelector("small.author")!.text,
          tags:
              card
                  .querySelectorAll("div.tags > a.tag")
                  .map((link) => link.text)
                  .toList(),
          quote: card.querySelector("span.text")!.text,
        ),
      );
    }
  }
}

Future<void> main() async {
  final crawler = QuoteCrawler();

  final pipelines = {
    Quote: [JSONPipeline<Quote>(outputFile: "quote.json")],
  };

  final scraper = Girasol(crawlers: [crawler], pipelines: pipelines);

  await scraper.execute();
}
