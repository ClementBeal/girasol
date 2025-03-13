import 'dart:io';
import '../pipeline.dart';
import 'package:xml/xml.dart';

/// Necessary for the item that must be processed by the XML pipeline
abstract class XmlItem {
  /// Convert the item to an XML element
  void toXmlElement(XmlBuilder builder);

  /// The name of the root element for this item
  String get elementName;
}

/// The XML pipeline is able to receive an item and save it
/// into an XML file.
///
/// The item must implement the [XmlItem] interface.
class XMLPipeline<Item extends XmlItem> extends Pipeline<Item> {
  /// The path where the `.xml` file will be stored
  final String outputFile;

  /// The name of the root element that will contain all items
  final String rootElementName;

  late final XmlBuilder builder;
  late final IOSink writer;
  final List<Item> _items = [];

  XMLPipeline({required this.outputFile, required this.rootElementName}) {
    final file = File(outputFile);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    writer = file.openWrite();

    builder = XmlBuilder();
    // Write XML declaration
    builder.processing("xml", 'version="1.0" encoding="UTF-8"');
  }

  @override
  Future<void> receiveData(Item data) async {
    _items.add(data);
  }

  @override
  Future<void> clean() async {
    builder.element(
      rootElementName,
      nest: () {
        for (var item in _items) {
          item.toXmlElement(builder);
        }
      },
    );

    // Write the XML document to the file
    writer.write(builder.buildDocument().toXmlString(pretty: true));

    await writer.flush();
    await writer.close();
  }
}
