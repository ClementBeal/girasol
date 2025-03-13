import 'package:girasol/girasol.dart';
import 'package:girasol/src/executor.dart';
import 'package:girasol/src/scrapers/scraper.dart';
import 'package:girasol/src/utils/browser_http_client.dart';

class PastebinItem implements JsonItem {
  final String title;
  final Uri link;
  final DateTime createdAt;

  PastebinItem({
    required this.title,
    required this.link,
    required this.createdAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      "createdAt": createdAt.toIso8601String(),
      "title": title,
      "link": link.toString(),
    };
  }
}

class PastebinCrawler extends StaticWebCrawler<PastebinItem> {
  PastebinCrawler() : super(name: "PasteBin");

  @override
  Stream<CrawlRequest> getUrls() async* {
    yield CrawlRequest.get(Uri.parse("https://pastebin.com/archive"));
  }

  @override
  parseResponse(CrawlResponse response, CrawlDocument crawlDocument) async* {
    if (crawlDocument is! HTMLDocument) return;

    final document = crawlDocument.document;
    // the first row is the headers, we skip it
    final tableRows = document.querySelectorAll("tbody > tr").skip(1);

    for (final row in tableRows) {
      final [cell1, cell2, cell3] = row.querySelectorAll("td");

      yield ParsedData(
        PastebinItem(
          link: Uri.parse(cell1.querySelector("a")!.attributes["href"]!),
          title: cell1.text,
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}

Future<void> main() async {
  final crawler = PastebinCrawler();

  final pipelines = {
    PastebinItem: [JSONPipeline<PastebinItem>(outputFile: "pastebin.json")],
  };

  final scraper = Girasol(crawlers: [crawler], pipelines: pipelines);

  await scraper.execute();
}
