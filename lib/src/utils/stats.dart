import 'package:girasol/girasol.dart';

class CrawlerStats {
  final WebCrawler crawler;
  int i = 0;
  int totalRequests = 0;
  int bytesDownload = 0;
  int totalBytesDownloaded = 0;
  DateTime lastPrint = DateTime.now();
  DateTime startTime = DateTime.now();

  CrawlerStats({required this.crawler});

  void addUrl(CrawlResponse response) {
    i++;
    totalRequests++;
    bytesDownload += response.bodyBytes.lengthInBytes;
    totalBytesDownloaded += response.bodyBytes.lengthInBytes;
  }

  void printAndReset() {
    final callDate = DateTime.now();
    final runningDuring = callDate.difference(startTime);
    final timeDiff = callDate.difference(lastPrint);
    lastPrint = callDate;

    final ratePerSecond = i / (timeDiff.inSeconds > 0 ? timeDiff.inSeconds : 1);
    final ratePerMinute = ratePerSecond * 60;

    final uptime = "${runningDuring.inMinutes}:${runningDuring.inSeconds % 60}";

    print(
      "[Crawler ${crawler.name}] $i request(s) - ${ratePerMinute.toStringAsFixed(2)} request(s) per minute "
      "($bytesDownload bytes) | Uptime $uptime",
    );

    i = 0;
    bytesDownload = 0;
  }

  void stop() {
    final totalRunTime = DateTime.now().difference(startTime);
    final totalRatePerSecond =
        totalRequests /
        (totalRunTime.inSeconds > 0 ? totalRunTime.inSeconds : 1);
    final totalRatePerMinute = totalRatePerSecond * 60;
    final totalUptime =
        "${totalRunTime.inMinutes}:${totalRunTime.inSeconds % 60}";

    print(
      "[Crawler ${crawler.name}] Session completed!\n"
      "Total Requests: $totalRequests\n"
      "Total Bytes Downloaded: $totalBytesDownloaded bytes\n"
      "Average Rate: ${totalRatePerMinute.toStringAsFixed(2)} requests per minute\n"
      "Total Uptime: $totalUptime",
    );
  }
}
