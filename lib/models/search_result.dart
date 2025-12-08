/// Search result models for global search functionality
/// Represents the response from GET /search endpoint

class SearchResult {
  final List<ProductSearchItem> products;
  final List<CollectionSearchItem> collections;
  final List<CategorySearchItem> categories;

  SearchResult({
    required this.products,
    required this.collections,
    required this.categories,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      products: (json['products'] as List? ?? [])
          .map((p) => ProductSearchItem.fromJson(p))
          .toList(),
      collections: (json['collections'] as List? ?? [])
          .map((c) => CollectionSearchItem.fromJson(c))
          .toList(),
      categories: (json['categories'] as List? ?? [])
          .map((c) => CategorySearchItem.fromJson(c))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((p) => p.toJson()).toList(),
      'collections': collections.map((c) => c.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
    };
  }

  /// Check if search returned no results
  bool get isEmpty =>
      products.isEmpty && collections.isEmpty && categories.isEmpty;

  /// Check if search has results
  bool get isNotEmpty => !isEmpty;

  /// Get total count of all results
  int get totalCount =>
      products.length + collections.length + categories.length;

  /// Get result summary for display
  String get summary {
    final parts = <String>[];
    if (products.isNotEmpty) {
      parts.add('${products.length} product${products.length == 1 ? '' : 's'}');
    }
    if (collections.isNotEmpty) {
      parts.add(
          '${collections.length} collection${collections.length == 1 ? '' : 's'}');
    }
    if (categories.isNotEmpty) {
      parts.add(
          '${categories.length} categor${categories.length == 1 ? 'y' : 'ies'}');
    }
    return parts.isEmpty ? 'No results' : parts.join(', ');
  }
}

class ProductSearchItem {
  final int id;
  final String name;
  final String slug;
  final double price;
  final double? compareAtPrice;
  final String? primaryImage;
  final int availableQuantity;
  final String? categoryName;
  final String? shortDescription;

  ProductSearchItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.compareAtPrice,
    this.primaryImage,
    required this.availableQuantity,
    this.categoryName,
    this.shortDescription,
  });

  factory ProductSearchItem.fromJson(Map<String, dynamic> json) {
    return ProductSearchItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      price: _parseDouble(json['price'] ?? json['current_price']),
      compareAtPrice: json['compare_at_price'] != null
          ? _parseDouble(json['compare_at_price'])
          : null,
      primaryImage: json['primary_image'] ?? json['main_image'],
      availableQuantity: json['available_quantity'] ?? 0,
      categoryName: json['category_name'],
      shortDescription: json['short_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'price': price,
      if (compareAtPrice != null) 'compare_at_price': compareAtPrice,
      if (primaryImage != null) 'primary_image': primaryImage,
      'available_quantity': availableQuantity,
      if (categoryName != null) 'category_name': categoryName,
      if (shortDescription != null) 'short_description': shortDescription,
    };
  }

  /// Check if product has a discount
  bool get hasDiscount =>
      compareAtPrice != null && compareAtPrice! > price;

  /// Get discount percentage if available
  int get discountPercentage {
    if (!hasDiscount) return 0;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  /// Check if product is in stock
  bool get isInStock => availableQuantity > 0;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class CollectionSearchItem {
  final int id;
  final String name;
  final String slug;
  final double price;
  final String? primaryImage;
  final String? shortDescription;

  CollectionSearchItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.primaryImage,
    this.shortDescription,
  });

  factory CollectionSearchItem.fromJson(Map<String, dynamic> json) {
    return CollectionSearchItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      price: ProductSearchItem._parseDouble(json['price']),
      primaryImage: json['primary_image'] ?? json['main_image'],
      shortDescription: json['short_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'price': price,
      if (primaryImage != null) 'primary_image': primaryImage,
      if (shortDescription != null) 'short_description': shortDescription,
    };
  }
}

class CategorySearchItem {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final int? productCount;

  CategorySearchItem({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.productCount,
  });

  factory CategorySearchItem.fromJson(Map<String, dynamic> json) {
    return CategorySearchItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'],
      productCount: json['product_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (icon != null) 'icon': icon,
      if (productCount != null) 'product_count': productCount,
    };
  }
}
