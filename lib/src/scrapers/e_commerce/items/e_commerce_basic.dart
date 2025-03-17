import 'package:girasol/girasol.dart';

part 'e_commerce_clothe.dart';

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
