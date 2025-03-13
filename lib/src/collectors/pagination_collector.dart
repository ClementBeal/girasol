import 'package:html/dom.dart';

class PaginationCollector {
  final Uri url;
  final String paginationContainerSelector;
  final String activePaginationSelector;
  final String nextPageSelector;

  PaginationCollector({
    required this.url,
    required this.paginationContainerSelector,
    required this.activePaginationSelector,
    required this.nextPageSelector,
  });

  String? collect(Document document) {
    final pagination = document.querySelector(paginationContainerSelector);

    if (pagination == null) {
      return null;
    }

    final activePage = pagination.querySelector(activePaginationSelector)?.text;

    if (activePage == null) {
      return null;
    }

    final nextPage = pagination.querySelector(nextPageSelector);

    if (nextPage == null) {
      return null;
    }

    final href = nextPage.attributes["href"]!;

    if (href.startsWith("/")) {
      return url
          .replace(path: Uri.parse(href).path, query: Uri.parse(href).query)
          .toString();
    }

    return href;
  }
}
