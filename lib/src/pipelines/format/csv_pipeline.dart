import 'dart:io';

import '../pipeline.dart';

/// Necessary for the item that must be processed by the CSV pipeline
abstract class CsvItem {
  /// The data of a row
  List<String> toCsvRow();

  /// The header of the CSV
  List<String> get csvHeaders;
}

/// The CSV pipeline is able to receive an item and save it
/// into a CSV file
///
/// The item must implements the [CsvItem]
class CSVPipeline<Item extends CsvItem> extends Pipeline<Item> {
  /// The path where the `.csv` file will be stored
  final String outputFile;

  late final IOSink writer;
  bool _isFirstItem = true;

  CSVPipeline({required this.outputFile}) {
    final file = File(outputFile);

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }

    writer = file.openWrite(mode: FileMode.write);
  }

  @override
  Future<void> receiveData(Item data) async {
    if (_isFirstItem) {
      writer.writeln(data.csvHeaders.join(","));
      _isFirstItem = false;
    }

    writer.writeln(data.toCsvRow().join(","));
  }

  @override
  Future<void> clean() async {
    await writer.flush();
    await writer.close();
  }
}
