import 'package:girasol/src/executor.dart';
import 'package:girasol/src/pipelines/format/json_pipeline.dart';
import 'package:girasol/src/scrapers/scraper.dart';
import 'package:girasol/src/utils/browser_http_client.dart';

class News implements JsonItem {
  final String title;
  final String author;
  final Uri articleUrl;
  final int points;
  final DateTime createdAt;
  final int nbComments;

  News({
    required this.title,
    required this.author,
    required this.articleUrl,
    required this.points,
    required this.createdAt,
    required this.nbComments,
  });

  @override
  Map<String, dynamic> toJson() => {
    "title": title,
    "author": author,
    "articleUrl": articleUrl.toString(),
    "points": points,
    "createdAt": createdAt.toIso8601String(),
    "nbComments": nbComments,
  };
}

class HackerNews extends StaticWebCrawler<News> {
  HackerNews() : super(name: "Hacker News");

  @override
  Stream<CrawlRequest> getUrls() async* {
    for (int i = 1; i < 10; i++) {
      yield CrawlRequest.get(Uri.parse("https://news.ycombinator.com/?p=$i"));
    }
  }

  @override
  parseResponse(CrawlResponse response, CrawlDocument document) async* {
    if (document is! HTMLDocument) return;

    final dom = document.document;

    final rows = dom.querySelectorAll("tr.submission");

    for (final row in rows) {
      final nextRow = row.nextElementSibling!;
      final a = row.querySelector("td.title > span.titleline > a")!;

      final sublineLinks = nextRow.querySelectorAll(
        "td.subtext > span.subline > a",
      );
      final author = sublineLinks.firstOrNull?.text ?? "";
      final score = nextRow.querySelector("span.score")?.text.split(" ").first;
      final commentsString = sublineLinks.lastOrNull?.text;
      final comments = RegExp(
        r"(\d+)",
      ).firstMatch(commentsString ?? "")?.group(1);

      yield ParsedData(
        News(
          title: a.text,
          author: author,
          articleUrl: Uri.tryParse(a.attributes["href"] ?? "") ?? Uri(),
          points: int.tryParse(score ?? "0") ?? 0,
          createdAt:
              DateTime.tryParse(
                nextRow
                        .querySelector("span.age")
                        ?.attributes["title"]
                        ?.split(" ")
                        .first ??
                    "",
              ) ??
              DateTime(1970), // Default fallback
          nbComments: int.tryParse(comments ?? "0") ?? 0,
        ),
      );
    }
  }
}

Future<void> main() async {
  final crawler = HackerNews();

  final pipelines = {
    News: [JSONPipeline<News>(outputFile: "news.json")],
  };

  final scraper = Girasol(crawlers: [crawler], pipelines: pipelines);

  await scraper.execute();
}
