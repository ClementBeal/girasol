import 'dart:io';
import '../../utils/browser_http_client.dart';
import 'package:path/path.dart' as path;
import '../pipeline.dart';

abstract class FileItem {
  Uri get uri;
}

class FilePipeline<Item extends FileItem> extends Pipeline<Item> {
  final Directory storageFolder;

  /// Generate the filename
  final String Function(String url)? nameGenerator;

  FilePipeline({required this.storageFolder, this.nameGenerator}) {
    if (!storageFolder.existsSync()) {
      storageFolder.createSync(recursive: true);
    }
  }

  @override
  Future<Item> receiveData(Item data) async {
    try {
      final fileName = data.uri.toString().split("/").last;
      final filePath = path.join(storageFolder.path, fileName);
      final file = File(filePath);

      // Download the file
      final client = BrowserHttpClient();
      final response = await client.send(CrawlRequest.get(data.uri));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        // You might want to modify the data object to include the local file path
        // This would require extending your FileItem class
      } else {
        // Handle error - log it or throw an exception
        print('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions
      print('Error downloading file: $e');
    }

    return data;
  }

  @override
  Future<void> clean() async {}
}
