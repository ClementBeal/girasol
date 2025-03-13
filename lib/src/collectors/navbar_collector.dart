import 'package:html/dom.dart';

class NavbarCollector {
  final Uri url;
  final String navbarSelector;
  final String linkSelector;
  final Uri Function(String link) onLinkExtracted;

  NavbarCollector({
    required this.url,
    required this.navbarSelector,
    required this.linkSelector,
    required this.onLinkExtracted,
  });

  List<Uri> collect(Document document) {
    final navbar = document.querySelector(navbarSelector);

    if (navbar == null) return [];

    return navbar
        .querySelectorAll(linkSelector)
        .map((linkTag) => linkTag.attributes["href"]!)
        .map(onLinkExtracted)
        .toList();
  }
}
