class Product {
  final int id;
  final String name;
  final String slug;
  final String sku;
  final int? categoryId;
  final String categoryName;
  final int? sectionId;        // New: API returns section_id
  final String sectionName;
  final String sectionSlug;    // Keep for backward compatibility, derived from section_id or direct
  final String shortDescription;
  final String? description;   // New: Full description
  final double price;
  final double? discountPrice;
  final double currentPrice;
  final int discountPercentage;
  final bool isFeatured;
  final bool isActive;         // New: from API
  final double rating;
  final int reviewCount;
  final String mainImage;
  final int stock;
  final List<ProductImage>? images; // New: from API

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.sku,
    this.categoryId,
    required this.categoryName,
    this.sectionId,
    required this.sectionName,
    required this.sectionSlug,
    required this.shortDescription,
    this.description,
    required this.price,
    this.discountPrice,
    required this.currentPrice,
    required this.discountPercentage,
    required this.isFeatured,
    this.isActive = true,
    required this.rating,
    required this.reviewCount,
    required this.mainImage,
    required this.stock,
    this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse price - API may return string or number
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Extract main image from images array if available
    String extractMainImage(Map<String, dynamic> json) {
      // First try direct main_image field
      if (json['main_image'] != null && json['main_image'].toString().isNotEmpty) {
        return json['main_image'];
      }
      // Try primary_image field (from ProductListItem schema)
      if (json['primary_image'] != null && json['primary_image'].toString().isNotEmpty) {
        return json['primary_image'];
      }
      // Try images array
      if (json['images'] is List && (json['images'] as List).isNotEmpty) {
        final images = json['images'] as List;
        // Find primary image
        final primaryImage = images.firstWhere(
          (img) => img['is_primary'] == true,
          orElse: () => images.first,
        );
        return primaryImage['image_url'] ?? '';
      }
      return '';
    }

    // Extract stock from inventory object if available
    int extractStock(Map<String, dynamic> json) {
      if (json['stock'] != null) return json['stock'] as int;
      if (json['available_quantity'] != null) return json['available_quantity'] as int;
      if (json['inventory'] is Map) {
        final inventory = json['inventory'] as Map<String, dynamic>;
        return inventory['available_quantity'] ?? inventory['quantity'] ?? 0;
      }
      return 0;
    }

    // Parse images array
    List<ProductImage>? parseImages(dynamic imagesJson) {
      if (imagesJson is! List) return null;
      return imagesJson.map((img) => ProductImage.fromJson(img)).toList();
    }

    final price = parsePrice(json['price']);
    final compareAtPrice = parsePrice(json['compare_at_price']);
    final discountPrice = json['discount_price'] != null ? parsePrice(json['discount_price']) : null;

    // Calculate current price
    double currentPrice;
    if (discountPrice != null && discountPrice > 0) {
      currentPrice = discountPrice;
    } else if (json['current_price'] != null) {
      currentPrice = parsePrice(json['current_price']);
    } else {
      currentPrice = price;
    }

    // Calculate discount percentage
    int discountPercentage = json['discount_percentage'] ?? 0;
    if (discountPercentage == 0 && compareAtPrice > 0 && price < compareAtPrice) {
      discountPercentage = ((compareAtPrice - price) / compareAtPrice * 100).round();
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      sku: json['sku'] ?? '',
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? '',
      sectionId: json['section_id'],
      sectionName: json['section_name'] ?? '',
      // Handle both section_slug and section_id for filtering
      sectionSlug: json['section_slug'] ?? (json['section_id']?.toString() ?? ''),
      shortDescription: json['short_description'] ?? '',
      description: json['description'],
      price: price,
      discountPrice: discountPrice ?? (compareAtPrice > price ? compareAtPrice : null),
      currentPrice: currentPrice,
      discountPercentage: discountPercentage,
      isFeatured: json['is_featured'] ?? false,
      isActive: json['is_active'] ?? true,
      rating: parsePrice(json['rating']),
      reviewCount: json['review_count'] ?? 0,
      mainImage: extractMainImage(json),
      stock: extractStock(json),
      images: parseImages(json['images']),
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
      'section_id': sectionId,
      'section_name': sectionName,
      'section_slug': sectionSlug,
      'short_description': shortDescription,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'current_price': currentPrice,
      'discount_percentage': discountPercentage,
      'is_featured': isFeatured,
      'is_active': isActive,
      'rating': rating,
      'review_count': reviewCount,
      'main_image': mainImage,
      'stock': stock,
    };
  }
}

/// Product image model matching API schema
class ProductImage {
  final int id;
  final String imageUrl;
  final String? altText;
  final bool isPrimary;
  final int displayOrder;

  ProductImage({
    required this.id,
    required this.imageUrl,
    this.altText,
    required this.isPrimary,
    required this.displayOrder,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      altText: json['alt_text'],
      isPrimary: json['is_primary'] ?? false,
      displayOrder: json['display_order'] ?? 0,
    );
  }
}