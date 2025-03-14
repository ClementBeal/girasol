import 'package:girasol/girasol.dart';
import 'package:html/dom.dart';

/// Represents a product from an e-commerce website.
/// Contains all common product data like name, price, description, etc.
class EcommerceItem implements JsonItem {
  final String name;
  final String url;
  final String? id;
  final String? description;
  final String? imageUrl;
  final double? price;
  final double? originalPrice;
  final String? currency;
  final bool? inStock;
  final int? stock;
  final double? rating;
  final int? reviewCount;
  final String? brand;
  final String? category;
  final List<String>? tags;
  final String? seller;
  final DateTime? lastUpdated;

  EcommerceItem({
    required this.name,
    required this.url,
    this.id,
    this.currency,
    this.description,
    this.imageUrl,
    this.price,
    this.originalPrice,
    this.inStock = true,
    this.stock,
    this.rating,
    this.reviewCount,
    this.brand,
    this.category,
    this.tags,
    this.seller,
    this.lastUpdated,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'url': url,
    'imageUrl': imageUrl,
    'price': price,
    'originalPrice': originalPrice,
    'currency': currency,
    'inStock': inStock,
    'stock': stock,
    'rating': rating,
    'reviewCount': reviewCount,
    'brand': brand,
    'category': category,
    'tags': tags,
    'seller': seller,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };
}

/// Defines all CSS selectors needed to extract product data from an e-commerce website.
class ECommerceCrawlerSelectors {
  /// CSS selector for the container of each product in a listing
  final String productBoxSelector;

  /// Selector for product ID (typically data attributes)
  final String? idSelector;

  /// Selector for product name or title
  final String nameSelector;

  /// Selector for product description
  final String? descriptionSelector;

  /// Selector for product image
  final String? imageUrlSelector;

  /// Selector for current selling price
  final String? priceSelector;

  /// Selector for original price (before discount)
  final String? originalPriceSelector;

  /// Currency symbol used on the site
  final String? currencySymbol;

  /// Selector for stock status information
  final String? inStockSelector;

  /// Selector for quantity available
  final String? stockSelector;

  /// Selector for product ratings
  final String? ratingSelector;

  /// Selector for number of reviews
  final String? reviewCountSelector;

  /// Selector for brand/manufacturer name
  final String? brandSelector;

  /// Selector for product category
  final String? categorySelector;

  /// Selector for product tags
  final String? tagsSelector;

  /// Selector for merchant/seller information
  final String? sellerSelector;

  ECommerceCrawlerSelectors({
    required this.productBoxSelector,
    this.idSelector,
    required this.nameSelector,
    this.descriptionSelector,
    this.imageUrlSelector,
    this.priceSelector,
    this.originalPriceSelector,
    this.currencySymbol,
    this.inStockSelector,
    this.stockSelector,
    this.ratingSelector,
    this.reviewCountSelector,
    this.brandSelector,
    this.categorySelector,
    this.tagsSelector,
    this.sellerSelector,
  });
}

/// Crawler designed specifically for e-commerce websites.
/// Extracts product information using provided CSS selectors.
/// Navigates pagination and can optionally visit product detail pages.
class ECommerceCrawler<T extends EcommerceItem> extends StaticWebCrawler<T> {
  /// Main URL of the e-commerce site
  final Uri mainUrl;

  /// Whether to visit each product's detail page
  final bool navigateToProductPage;

  /// For collecting navigation menu links
  final NavbarCollector? navbarCollector;

  /// Starting URLs for crawling
  final List<Uri> initialUris;

  /// For collecting pagination links
  final PaginationCollector? paginationCollector;

  /// All CSS selectors for data extraction
  final ECommerceCrawlerSelectors selectors;

  /// Factory function to create custom EcommerceItem instances
  final T Function(
    String? id,
    String name,
    String url,
    String? currency,
    String? description,
    String? imageUrl,
    double? price,
    double? originalPrice,
    bool? inStock,
    int? stock,
    double? rating,
    int? reviewCount,
    String? brand,
    String? category,
    List<String>? tags,
    String? seller,
    DateTime? lastUpdated,
  )
  itemFactory;

  ECommerceCrawler({
    required super.name,
    required super.concurrentRequests,
    required this.selectors,
    required this.mainUrl,
    required this.itemFactory,
    this.initialUris = const [],
    this.navbarCollector,
    this.paginationCollector,
    this.navigateToProductPage = false,
  });

  /// Generates initial URLs to crawl from navbar and initial URIs
  @override
  Stream<CrawlRequest> getUrls() async* {
    if (navbarCollector != null) {
      final client = BrowserHttpClient();
      final response = await client.send(CrawlRequest.get(mainUrl));
      for (final link in navbarCollector!.collect(parse(response.body))) {
        yield CrawlRequest.get(link);
      }
    }

    for (final link in initialUris) {
      yield CrawlRequest.get(link);
    }
  }

  @override
  Stream<ParseResult> parseResponse(
    CrawlResponse response,
    CrawlDocument document,
  ) async* {
    if (document is! HTMLDocument) return;

    final dom = document.document;
    final isProductPage = response.request.depth == 2;

    // Handle pagination on listing pages
    if (!isProductPage && paginationCollector != null) {
      final nextPage = paginationCollector!.collect(dom);
      if (nextPage != null) {
        yield ParsedLink(
          CrawlRequest.get(
            Uri.parse(nextPage),
            depth: response.request.depth + 1,
          ),
        );
      }
    }

    // Handle product detail page
    if (isProductPage) {
      yield ParsedData(
        _extractProduct(response, dom.querySelector("body")!, true),
      );
      return;
    }

    // Handle listing page with multiple products
    for (final productBox in dom.querySelectorAll(
      selectors.productBoxSelector,
    )) {
      if (navigateToProductPage) {
        final link = productBox.querySelector("a")!.attributes["href"];
        yield ParsedLink(
          CrawlRequest.get(
            response.request.url.replace(path: link),
            depth: response.request.depth,
          ),
        );
        continue;
      }

      yield ParsedData(_extractProduct(response, productBox, false));
    }
  }

  /// Extracts all product data from an HTML element using selectors
  T _extractProduct(
    CrawlResponse response,
    Element productBox,
    bool isProductPage,
  ) {
    // Helper function for text extraction
    String? extractText(String? selector) =>
        selector != null ? _getElementText(productBox, selector) : null;

    // Extract all product data with simplified approach
    return itemFactory(
      selectors.idSelector != null ? _extractId(productBox) : null,
      _getElementText(productBox, selectors.nameSelector),
      isProductPage
          ? response.request.url.toString()
          : _extractUrl(productBox, "a", response.request.url),
      "\$",
      extractText(selectors.descriptionSelector),
      selectors.imageUrlSelector != null
          ? _extractAttribute(productBox, selectors.imageUrlSelector!, "src")
          : null,
      selectors.priceSelector != null
          ? _extractPrice(productBox, selectors.priceSelector!)
          : null,
      selectors.originalPriceSelector != null
          ? _extractPrice(productBox, selectors.originalPriceSelector!)
          : null,
      selectors.inStockSelector != null
          ? !_getElementText(
            productBox,
            selectors.inStockSelector!,
          ).contains(RegExp(r'out of stock|sold out', caseSensitive: false))
          : true,
      selectors.stockSelector != null
          ? _extractNumber(productBox, selectors.stockSelector!)
          : null,
      selectors.ratingSelector != null
          ? _extractRating(productBox, selectors.ratingSelector!)
          : null,
      selectors.reviewCountSelector != null
          ? _extractNumber(productBox, selectors.reviewCountSelector!)
          : null,
      extractText(selectors.brandSelector),
      extractText(selectors.categorySelector),
      selectors.tagsSelector != null
          ? _extractTags(productBox, selectors.tagsSelector!)
          : null,
      extractText(selectors.sellerSelector),
      DateTime.now(),
    );
  }

  /// Gets text content from an element matching the selector
  String _getElementText(Element element, String selector) {
    try {
      final selected = element.querySelector(selector);
      return selected != null ? selected.text.trim() : "";
    } catch (_) {
      return "";
    }
  }

  /// Extracts product ID from various possible sources
  String? _extractId(Element element) {
    if (selectors.idSelector == null) return null;
    return _extractAttribute(
          element,
          selectors.idSelector!,
          "data-product-id",
        ) ??
        _extractAttribute(element, selectors.idSelector!, "id") ??
        _getElementText(element, selectors.idSelector!);
  }

  /// Extracts and normalizes URL from element
  String _extractUrl(Element element, String selector, Uri baseUrl) {
    try {
      final link = element.querySelector(selector);
      if (link != null) {
        final href = link.attributes["href"];
        if (href != null) {
          return href.startsWith('http')
              ? href
              : baseUrl.resolve(href).toString();
        }
      }
      return baseUrl.toString();
    } catch (_) {
      return baseUrl.toString();
    }
  }

  /// Extracts an attribute value from an element
  String? _extractAttribute(
    Element element,
    String selector,
    String attribute,
  ) {
    try {
      final selected = element.querySelector(selector);
      return selected?.attributes[attribute]?.trim();
    } catch (_) {
      return null;
    }
  }

  /// Extracts and parses price value
  double? _extractPrice(Element element, String selector) {
    try {
      final priceText = _getElementText(
        element,
        selector,
      ).replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
      return double.tryParse(priceText);
    } catch (_) {
      return null;
    }
  }

  /// Extracts and parses numeric values
  int? _extractNumber(Element element, String selector) {
    try {
      return int.tryParse(
        _getElementText(element, selector).replaceAll(RegExp(r'[^\d]'), ''),
      );
    } catch (_) {
      return null;
    }
  }

  /// Extracts and normalizes rating value
  double? _extractRating(Element element, String selector) {
    try {
      final ratingText = _getElementText(
        element,
        selector,
      ).replaceAll(RegExp(r'[^\d.,/]'), '').replaceAll(',', '.');

      if (ratingText.contains('/')) {
        final parts = ratingText.split('/');
        if (parts.length == 2) {
          final rating = double.tryParse(parts[0]);
          final scale = double.tryParse(parts[1]);
          if (rating != null && scale != null && scale > 0) {
            return (rating / scale) * 5;
          }
        }
      }
      return double.tryParse(ratingText);
    } catch (_) {
      return null;
    }
  }

  /// Extracts multiple tags from elements
  List<String>? _extractTags(Element element, String selector) {
    try {
      final tagElements = element.querySelectorAll(selector);
      return tagElements.isNotEmpty
          ? tagElements
              .map((e) => e.text.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : null;
    } catch (_) {
      return null;
    }
  }
}
