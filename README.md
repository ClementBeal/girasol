# Dart Web Crawler

A powerful and parallel web crawler for Dart, inspired by [Scrapy](https://scrapy.org/). This package allows you to scrape websites efficiently using `girasol` instances and export data in multiple formats.

## Features

- **Parallel Web Crawlers**: Scrape multiple pages concurrently for high efficiency.
- **Customizable Pipelines**: Export scraped data to CSV, XML, or JSON.
- **File Downloading**: Built-in support for downloading files during scraping.
- **Flexible Parsing**: Easily extract and process data from web pages.

## Installation

Add the package to your `pubspec.yaml`:

```sh
dart pub add girasol
```

## Usage

### Define a Web Crawler

```dart
import 'package:girasol/girasol.dart';

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
```

### Export Data

Configure pipelines to export scraped data:

```dart
final pipelines = {
  PastebinItem: [
    CSVFilePipeline<PastebinItem>(outputFile: "output.csv"), 
    JSONPipeline<PastebinItem>(outputFile: "output.json")
  ],
};
```

### Download Files

```dart
final pipelines = {
  FileDownloadPipeline(storageFolder: Directory("downloads/"))
};
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

MIT License

