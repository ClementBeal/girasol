import 'dart:convert';
import 'dart:io';

import '../pipeline.dart';

/// Necessary for the item that must be processed by the JSON pipeline
abstract class JsonItem {
  Map<String, dynamic> toJson();
}

/// The JSON pipeline is able to receive an item data and
/// save it into an [outputFile]
///
/// The item must implements [JsonItem]
class JSONPipeline<Item extends JsonItem> extends Pipeline<Item> {
  /// The path where the `.json` file will be stored
  final String outputFile;

  late final IOSink writer;
  bool _isFirstItem = true;

  JSONPipeline({required this.outputFile}) {
    final file = File(outputFile);

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }

    writer = file.openWrite();
    writer.write("[");
  }

  @override
  Future<void> receiveData(Item data) async {
    if (!_isFirstItem) {
      writer.write(",");
    }
    _isFirstItem = false;
    writer.write(jsonEncode(data.toJson()));
  }

  @override
  Future<void> clean() async {
    writer.write("]");
    await writer.flush();
    await writer.close();
  }
}
