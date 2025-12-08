/// Model representing a curated product collection (e.g., bouquets, gift sets)
///
/// Collections bundle multiple products together at a set price, often with
/// a discount compared to buying items individually.
class Collection {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? shortDescription;
  final double price;
  final double? compareAtPrice;
  final int? sectionId;
  final bool isActive;
  final bool isFeatured;
  final List<CollectionItem> items;
  final List<CollectionImage> images;
  final CollectionInventory? inventory;
  final double? componentsTotal;
  final double? discountFromComponents;
  final DateTime createdAt;
  final DateTime updatedAt;

  Collection({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.shortDescription,
    required this.price,
    this.compareAtPrice,
    this.sectionId,
    required this.isActive,
    required this.isFeatured,
    required this.items,
    required this.images,
    this.inventory,
    this.componentsTotal,
    this.discountFromComponents,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns the main display image URL for this collection
  String get mainImage {
    final mainImg = images.firstWhere(
      (img) => img.isMain,
      orElse: () => images.isNotEmpty ? images.first : CollectionImage.empty(),
    );
    return mainImg.imageUrl;
  }

  /// Whether the collection is currently in stock
  bool get isInStock => inventory?.isOutOfStock != true;

  /// Number of units available for purchase
  int get availableQuantity => inventory?.availableQuantity ?? 0;

  /// Whether this collection has a discount (compare_at_price > price)
  bool get hasDiscount =>
      compareAtPrice != null && compareAtPrice! > price;

  /// The discount percentage if applicable
  double get discountPercentage {
    if (!hasDiscount) return 0.0;
    return ((compareAtPrice! - price) / compareAtPrice! * 100);
  }

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      shortDescription: json['short_description'],
      price: _parseDouble(json['price']),
      compareAtPrice: json['compare_at_price'] != null
          ? _parseDouble(json['compare_at_price'])
          : null,
      sectionId: json['section_id'],
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      items: (json['items'] as List? ?? [])
          .map((item) => CollectionItem.fromJson(item))
          .toList(),
      images: (json['images'] as List? ?? [])
          .map((img) => CollectionImage.fromJson(img))
          .toList(),
      inventory: json['inventory'] != null
          ? CollectionInventory.fromJson(json['inventory'])
          : null,
      componentsTotal: json['components_total'] != null
          ? _parseDouble(json['components_total'])
          : null,
      discountFromComponents: json['discount_from_components'] != null
          ? _parseDouble(json['discount_from_components'])
          : null,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'short_description': shortDescription,
      'price': price,
      'compare_at_price': compareAtPrice,
      'section_id': sectionId,
      'is_active': isActive,
      'is_featured': isFeatured,
      'items': items.map((i) => i.toJson()).toList(),
      'images': images.map((i) => i.toJson()).toList(),
      'inventory': inventory?.toJson(),
      'components_total': componentsTotal,
      'discount_from_components': discountFromComponents,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Represents a single item (product) within a collection
class CollectionItem {
  final int id;
  final int productId;
  final int quantity;
  final int displayOrder;
  final CollectionItemProduct? product;

  CollectionItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.displayOrder,
    this.product,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 1,
      displayOrder: json['display_order'] ?? 0,
      product: json['product'] != null
          ? CollectionItemProduct.fromJson(json['product'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'display_order': displayOrder,
      'product': product?.toJson(),
    };
  }
}

/// Simplified product info embedded in collection items
class CollectionItemProduct {
  final int id;
  final String name;
  final double price;

  CollectionItemProduct({
    required this.id,
    required this.name,
    required this.price,
  });

  factory CollectionItemProduct.fromJson(Map<String, dynamic> json) {
    return CollectionItemProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: Collection._parseDouble(json['price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }
}

/// Represents an image associated with a collection
class CollectionImage {
  final int id;
  final String imageUrl;
  final String? altText;
  final bool isMain;

  CollectionImage({
    required this.id,
    required this.imageUrl,
    this.altText,
    required this.isMain,
  });

  /// Creates an empty placeholder image
  factory CollectionImage.empty() => CollectionImage(
        id: 0,
        imageUrl: '',
        isMain: false,
      );

  factory CollectionImage.fromJson(Map<String, dynamic> json) {
    return CollectionImage(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      altText: json['alt_text'],
      isMain: json['is_main'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'alt_text': altText,
      'is_main': isMain,
    };
  }
}

/// Inventory tracking for a collection
class CollectionInventory {
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
  final bool isLowStock;
  final bool isOutOfStock;

  CollectionInventory({
    required this.quantity,
    required this.reservedQuantity,
    required this.availableQuantity,
    required this.isLowStock,
    required this.isOutOfStock,
  });

  factory CollectionInventory.fromJson(Map<String, dynamic> json) {
    return CollectionInventory(
      quantity: json['quantity'] ?? 0,
      reservedQuantity: json['reserved_quantity'] ?? 0,
      availableQuantity: json['available_quantity'] ?? 0,
      isLowStock: json['is_low_stock'] ?? false,
      isOutOfStock: json['is_out_of_stock'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'reserved_quantity': reservedQuantity,
      'available_quantity': availableQuantity,
      'is_low_stock': isLowStock,
      'is_out_of_stock': isOutOfStock,
    };
  }
}
