# girasol

*Girasol* is a web scraper framework made in Dart.

## How to install

```bash
dart pub add girasol
```

## Write your first scraper

```dart
import 'package:girasol/girasol.dart';
import 'package:girasol/src/executor.dart';
import 'package:girasol/src/pipelines/pipeline.dart';
import 'package:html/dom.dart';

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
  @override
  Stream<Uri> getUrls() async* {
    yield Uri.parse("https://pastebin.com/archive");
  }

  @override
  parseResponse(CrawlResponse response, Document document) async* {
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

  final scraper = GirasolScraper(crawlers: [crawler], pipelines: pipelines);

  await scraper.execute();
}

```