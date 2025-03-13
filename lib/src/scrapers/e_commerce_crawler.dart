import 'package:girasol/girasol.dart';
import 'package:html/dom.dart';

class EcommerceItem implements JsonItem {
  final String id;
  final String name;
  final String? description;
  final String url;
  final String? imageUrl;
  final double? price;
  final double? originalPrice;
  final String currency;
  final bool inStock;
  final int? stock;
  final double? rating;
  final int? reviewCount;
  final String? brand;
  final String? category;
  final List<String>? tags;
  final String? seller;
  final DateTime? lastUpdated;

  EcommerceItem({
    required this.id,
    required this.name,
    required this.url,
    required this.currency,
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
  Map<String, dynamic> toJson() {
    return {
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
      'lastUpdated':
          lastUpdated?.toIso8601String(), // Convert DateTime to ISO string
    };
  }
}

/// The [ECommerceCrawler] is able to scrape a usual e-commerce static website
/// It works in 2 steps. First, it gathers all the categories
class ECommerceCrawler<T extends EcommerceItem> extends StaticWebCrawler<T> {
  final Uri mainUrl;

  /// This collector will collect all the links from the navbar.
  final NavbarCollector? navbarCollector;

  /// A bunch of initial URIs that the crawler will use
  final List<Uri> initialUris;

  /// This collector collects all the links from the pagination bar
  final PaginationCollector paginationCollector;

  /// CSS selector to select a product card that also contains all the data.
  /// This is the main container for each product on a listing page.
  /// Examples: 'div.product', 'li.product-item', '.product-card'
  final String productBoxSelector;

  /// Selector for extracting the product ID.
  /// This often targets data attributes or specific ID elements.
  /// Examples: '[data-product-id]', '.sku', '.product-id'
  final String idSelector;

  /// Selector for extracting the product name.
  /// This typically targets heading elements within the product card.
  /// Examples: 'h2.product-name', '.product-title', 'a.product-link'
  final String nameSelector;

  /// Selector for extracting the product description.
  /// This targets elements containing short product descriptions on listing pages.
  /// Examples: 'p.description', '.product-excerpt', '.short-desc'
  final String? descriptionSelector;

  /// Selector for extracting the product image URL.
  /// This typically targets the main product image element.
  /// Examples: 'img.product-image', '.thumbnail img', '.product-photo'
  final String? imageUrlSelector;

  /// Selector for extracting the current price.
  /// This targets elements displaying the active selling price.
  /// Examples: '.price', 'span.current-price', '.sale-price'
  final String? priceSelector;

  /// Selector for extracting the original price (for discounted items).
  /// This targets elements showing the pre-discount or regular price.
  /// Examples: '.original-price', 'del.price', '.regular-price'
  final String? originalPriceSelector;

  /// The currency symbol used on the site.
  /// This is a static value rather than extracted, for consistency.
  /// Examples: '$', '€', '£', '¥'
  final String currencySymbol;

  /// Selector for determining if the product is in stock.
  /// This targets elements that display stock status information.
  /// Examples: '.stock-status', '.availability', 'span.in-stock'
  /// Note: The crawler checks for text like "out of stock" or "sold out"
  final String? inStockSelector;

  /// Selector for extracting the quantity in stock.
  /// This targets elements showing the specific number of items available.
  /// Examples: '.stock-quantity', 'span.qty', '.inventory-count'
  final String? stockSelector;

  /// Selector for extracting the product rating.
  /// This targets elements displaying customer ratings (stars, numbers, etc.).
  /// Examples: '.rating', '.stars', 'span.star-rating'
  final String? ratingSelector;

  /// Selector for extracting the number of reviews.
  /// This targets elements showing how many customer reviews exist.
  /// Examples: '.review-count', 'span.reviews', '.rating-count'
  final String? reviewCountSelector;

  /// Selector for extracting the product brand.
  /// This targets elements displaying the manufacturer or brand name.
  /// Examples: '.brand', 'span.manufacturer', '.vendor'
  final String? brandSelector;

  /// Selector for extracting the product category.
  /// This targets elements showing which category the product belongs to.
  /// Examples: '.category', 'span.product-type', '.breadcrumb'
  final String? categorySelector;

  /// Selector for extracting product tags.
  /// This targets multiple elements containing tag information.
  /// Examples: '.tag', 'span.product-tag', '.labels span'
  final String? tagsSelector;

  /// Selector for extracting the seller information.
  /// This targets elements showing the merchant or seller name (for marketplaces).
  /// Examples: '.seller', 'span.store-name', '.merchant-info'
  final String? sellerSelector;

  /// Function that creates a custom instance of T (EcommerceItem subclass)
  /// This allows users to provide their own factory for creating custom EcommerceItem subclasses
  final T Function(
    String id,
    String name,
    String url,
    String currency,
    String? description,
    String? imageUrl,
    double? price,
    double? originalPrice,
    bool inStock,
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
    List<Uri>? initialUris,
    required this.navbarCollector,
    required this.paginationCollector,
    required this.mainUrl,
    required this.productBoxSelector,
    required this.idSelector,
    required this.nameSelector,
    required this.currencySymbol,
    this.descriptionSelector,
    this.imageUrlSelector,
    this.priceSelector,
    this.originalPriceSelector,
    this.inStockSelector,
    this.stockSelector,
    this.ratingSelector,
    this.reviewCountSelector,
    this.brandSelector,
    this.categorySelector,
    this.tagsSelector,
    this.sellerSelector,
    required this.itemFactory,
  }) : initialUris = initialUris ?? [];

  @override
  Stream<CrawlRequest> getUrls() async* {
    if (navbarCollector != null) {
      final client = BrowserHttpClient();
      final response = await client.send(CrawlRequest.get(mainUrl));
      final links = navbarCollector!.collect(parse(response.body));
      for (final link in links) {
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
    final nextPage = paginationCollector.collect(dom);

    if (nextPage != null) {
      yield ParsedLink(CrawlRequest(url: Uri.parse(nextPage)));
    }

    final productBoxes = dom.querySelectorAll(productBoxSelector);
    for (final productBox in productBoxes) {
      // Extract required fields
      final id = _extractId(productBox);
      final name = _extractText(productBox, nameSelector);
      final url = _extractUrl(productBox, "a", response.request.url);

      // Extract optional fields
      final description =
          descriptionSelector != null
              ? _extractText(productBox, descriptionSelector!)
              : null;

      final imageUrl =
          imageUrlSelector != null
              ? _extractAttribute(productBox, imageUrlSelector!, "src")
              : null;

      final price =
          priceSelector != null
              ? _extractPrice(productBox, priceSelector!)
              : null;

      final originalPrice =
          originalPriceSelector != null
              ? _extractPrice(productBox, originalPriceSelector!)
              : null;

      final inStock =
          inStockSelector != null
              ? !(_extractText(
                    productBox,
                    inStockSelector!,
                  ).contains("out of stock") ||
                  _extractText(
                    productBox,
                    inStockSelector!,
                  ).contains("sold out"))
              : true;

      final stock =
          stockSelector != null
              ? _extractNumber(productBox, stockSelector!)
              : null;

      final rating =
          ratingSelector != null
              ? _extractRating(productBox, ratingSelector!)
              : null;

      final reviewCount =
          reviewCountSelector != null
              ? _extractNumber(productBox, reviewCountSelector!)
              : null;

      final brand =
          brandSelector != null
              ? _extractText(productBox, brandSelector!)
              : null;

      final category =
          categorySelector != null
              ? _extractText(productBox, categorySelector!)
              : null;

      final tags =
          tagsSelector != null ? _extractTags(productBox, tagsSelector!) : null;

      final seller =
          sellerSelector != null
              ? _extractText(productBox, sellerSelector!)
              : null;

      final item = itemFactory(
        id,
        name,
        url,
        currencySymbol,
        description,
        imageUrl,
        price,
        originalPrice,
        inStock,
        stock,
        rating,
        reviewCount,
        brand,
        category,
        tags,
        seller,
        DateTime.now(),
      );

      yield ParsedData(item);
    }
  }

  // Helper methods for extraction
  String _extractId(Element element) {
    final idText =
        _extractAttribute(element, idSelector, "data-product-id") ??
        _extractAttribute(element, idSelector, "id") ??
        _extractText(element, idSelector);
    return idText.trim();
  }

  String _extractText(Element element, String selector) {
    try {
      final selected = element.querySelector(selector);
      return selected != null ? selected.text.trim() : "";
    } catch (e) {
      return "";
    }
  }

  String _extractUrl(Element element, String selector, Uri baseUrl) {
    try {
      final link = element.querySelector(selector);
      if (link != null) {
        final href = link.attributes["href"];
        if (href != null) {
          if (href.startsWith('http')) {
            return href;
          } else {
            return baseUrl.resolve(href).toString();
          }
        }
      }
      return baseUrl.toString();
    } catch (e) {
      return baseUrl.toString();
    }
  }

  String? _extractAttribute(
    Element element,
    String selector,
    String attribute,
  ) {
    try {
      final selected = element.querySelector(selector);
      return selected != null ? selected.attributes[attribute]?.trim() : null;
    } catch (e) {
      return null;
    }
  }

  double? _extractPrice(Element element, String selector) {
    try {
      final priceText = _extractText(element, selector)
          .replaceAll(
            RegExp(r'[^\d.,]'),
            '',
          ) // Remove currency symbols and other characters
          .replaceAll(',', '.'); // Standardize decimal separator

      return double.tryParse(priceText);
    } catch (e) {
      return null;
    }
  }

  int? _extractNumber(Element element, String selector) {
    try {
      final text = _extractText(
        element,
        selector,
      ).replaceAll(RegExp(r'[^\d]'), ''); // Keep only digits

      return int.tryParse(text);
    } catch (e) {
      return null;
    }
  }

  double? _extractRating(Element element, String selector) {
    try {
      // Try extracting from text first
      final ratingText = _extractText(element, selector)
          .replaceAll(
            RegExp(r'[^\d.,/]'),
            '',
          ) // Keep only digits, dots, commas, and slashes
          .replaceAll(',', '.'); // Standardize decimal separator

      // Check if it's in format like "4.5/5"
      if (ratingText.contains('/')) {
        final parts = ratingText.split('/');
        if (parts.length == 2) {
          final rating = double.tryParse(parts[0]);
          final scale = double.tryParse(parts[1]);
          if (rating != null && scale != null && scale > 0) {
            return (rating / scale) * 5; // Normalize to 5-star scale
          }
        }
      }

      return double.tryParse(ratingText);
    } catch (e) {
      return null;
    }
  }

  List<String>? _extractTags(Element element, String selector) {
    try {
      final tagElements = element.querySelectorAll(selector);
      if (tagElements.isNotEmpty) {
        return tagElements
            .map((e) => e.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
