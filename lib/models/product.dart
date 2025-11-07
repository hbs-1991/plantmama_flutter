class Product {
  final int id;
  final String name;
  final String slug;
  final String sku;
  final int categoryId;
  final String categoryName;
  final String sectionName;
  final String sectionSlug;
  final String shortDescription;
  final double price;
  final double? discountPrice;
  final double currentPrice;
  final int discountPercentage;
  final bool isFeatured;
  final double rating;
  final int reviewCount;
  final String mainImage;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.sku,
    required this.categoryId,
    required this.categoryName,
    required this.sectionName,
    required this.sectionSlug,
    required this.shortDescription,
    required this.price,
    this.discountPrice,
    required this.currentPrice,
    required this.discountPercentage,
    required this.isFeatured,
    required this.rating,
    required this.reviewCount,
    required this.mainImage,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      sku: json['sku'] ?? '',
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      sectionName: json['section_name'] ?? '',
      sectionSlug: json['section_slug'] ?? '',
      shortDescription: json['short_description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discount_price'] != null ? (json['discount_price']).toDouble() : null,
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      discountPercentage: json['discount_percentage'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      mainImage: json['main_image'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'sku': sku,
      'category_id': categoryId,
      'category_name': categoryName,
      'section_name': sectionName,
      'section_slug': sectionSlug,
      'short_description': shortDescription,
      'price': price,
      'discount_price': discountPrice,
      'current_price': currentPrice,
      'discount_percentage': discountPercentage,
      'is_featured': isFeatured,
      'rating': rating,
      'review_count': reviewCount,
      'main_image': mainImage,
      'stock': stock,
    };
  }
}