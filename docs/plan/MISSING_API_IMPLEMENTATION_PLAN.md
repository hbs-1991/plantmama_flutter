# Implementation Plan: Missing API Endpoints

> **Created:** December 8, 2024
> **Status:** Ready for Implementation
> **Estimated Effort:** 7-8 hours

## Overview

Based on the API documentation analysis (`api-docs/flutter-api-documentation.yaml`), the following endpoints are documented but **not yet implemented** in the Flutter app.

---

## Current Implementation Status

### Implemented Endpoints

| Category | Endpoint | Service File |
|----------|----------|--------------|
| Auth | `POST /token/` (login) | `authService.dart` |
| Auth | `POST /users/register/` | `authService.dart` |
| Auth | `POST /token/refresh/` | `authService.dart` |
| Auth | `POST /users/change_password/` | `authService.dart` |
| User | `GET /users/me/` | `authService.dart` |
| User | `PUT /users/update_profile/` | `authService.dart` |
| Addresses | CRUD operations | `addressService.dart` |
| Products | `GET /products/` | `apiTest.dart` |
| Products | `GET /products/{id}/` | `apiTest.dart` |
| Products | `GET /products/categories/` | `apiTest.dart` |
| Products | `GET /products/sections/` | `apiTest.dart` |
| Cart | Add/Remove/Update/Clear | `cartService.dart` |
| Orders | CRUD + Cancel | `orderService.dart` |
| Reviews | Get & Create | `reviewService.dart` |
| Favorites | Add/Remove/Check | `cartService.dart` |

### Missing Endpoints (To Implement)

| Priority | Endpoint | Description |
|----------|----------|-------------|
| HIGH | `POST /auth/logout` | Server-side token invalidation |
| HIGH | `POST /cart/validate` | Pre-checkout cart validation |
| HIGH | `GET /search` | Global search functionality |
| MEDIUM | `GET /collections` | List product collections |
| MEDIUM | `GET /collections/{id}` | Get collection details |
| MEDIUM | `GET /regions` | List available regions |
| MEDIUM | `GET /regions/current` | Get current region |
| MEDIUM | `GET /cart/delivery-fee` | Calculate delivery fee |
| LOW | `GET /products/{id}/images` | Get product images (already in product details) |

---

## Phase 1: High Priority (Security & Checkout Critical)

### 1.1 Server-Side Logout

**Current State:** App only clears local tokens via `logout()` method
**Risk:** Tokens remain valid on server until expiration (security vulnerability)

#### Files to Modify

| File | Changes |
|------|---------|
| `lib/services/interfaces/i_auth_service.dart` | Add `logoutFromServer()` method signature |
| `lib/services/authService.dart` | Implement `logoutFromServer()` |

#### Interface Addition

```dart
// Add to i_auth_service.dart
Future<bool> logoutFromServer();
```

#### Implementation

```dart
// Add to authService.dart
@override
Future<bool> logoutFromServer() async {
  try {
    final token = await getToken();
    if (token == null) {
      await logout(); // Clear local anyway
      return true;
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/logout'),
      headers: AppConfig.withNgrokBypass({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }),
    );

    // Always clear local storage regardless of server response
    await logout();
    return response.statusCode == 200;
  } catch (e) {
    // Fail gracefully - always clear local tokens
    await logout();
    AppLogger.warning('Server logout failed, local tokens cleared', tag: 'AuthService');
    return false;
  }
}
```

#### Usage

```dart
// Update all logout calls in the app
await authService.logoutFromServer(); // Instead of authService.logout()
```

---

### 1.2 Cart Validation

**Current State:** No pre-checkout validation
**Risk:** Users may checkout with out-of-stock or price-changed items

#### New Files to Create

| File | Purpose |
|------|---------|
| `lib/models/cart_validation.dart` | Response model for cart validation |

#### Files to Modify

| File | Changes |
|------|---------|
| `lib/services/interfaces/i_cart_service.dart` | Add `validateCart()` method signature |
| `lib/services/cartService.dart` | Implement `validateCart()` |

#### New Model

```dart
// lib/models/cart_validation.dart
import 'dart:convert';

class CartValidationResult {
  final List<CartValidationItem> items;
  final double subtotal;
  final double estimatedDeliveryFee;
  final bool allItemsAvailable;

  CartValidationResult({
    required this.items,
    required this.subtotal,
    required this.estimatedDeliveryFee,
    required this.allItemsAvailable,
  });

  factory CartValidationResult.fromJson(Map<String, dynamic> json) {
    return CartValidationResult(
      items: (json['items'] as List)
          .map((item) => CartValidationItem.fromJson(item))
          .toList(),
      subtotal: _parseDouble(json['subtotal']),
      estimatedDeliveryFee: _parseDouble(json['estimated_delivery_fee']),
      allItemsAvailable: json['all_items_available'] ?? false,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class CartValidationItem {
  final int productId;
  final bool available;
  final int quantityAvailable;
  final double currentPrice;
  final String? unavailableReason;

  CartValidationItem({
    required this.productId,
    required this.available,
    required this.quantityAvailable,
    required this.currentPrice,
    this.unavailableReason,
  });

  factory CartValidationItem.fromJson(Map<String, dynamic> json) {
    return CartValidationItem(
      productId: json['product_id'] ?? 0,
      available: json['available'] ?? false,
      quantityAvailable: json['quantity_available'] ?? 0,
      currentPrice: CartValidationResult._parseDouble(json['current_price']),
      unavailableReason: json['unavailable_reason'],
    );
  }
}
```

#### Interface Addition

```dart
// Add to i_cart_service.dart
Future<CartValidationResult?> validateCart({
  required List<Map<String, dynamic>> items,
  String deliveryMethod = 'delivery',
  String? regionCode,
});
```

#### Implementation

```dart
// Add to cartService.dart
@override
Future<CartValidationResult?> validateCart({
  required List<Map<String, dynamic>> items,
  String deliveryMethod = 'delivery',
  String? regionCode,
}) async {
  final token = await _getToken();
  if (token == null) return null;

  try {
    final headers = AppConfig.withNgrokBypass({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (regionCode != null) {
      headers['X-Region-Code'] = regionCode;
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/cart/validate'),
      headers: headers,
      body: json.encode({
        'items': items.map((item) => {
          'product_id': item['productId'] ?? item['product_id'],
          'quantity': item['quantity'],
        }).toList(),
        'delivery_method': deliveryMethod,
        if (regionCode != null) 'region_code': regionCode,
      }),
    );

    if (response.statusCode == 200) {
      if (_looksLikeHtml(response.body, response.headers)) return null;
      final data = json.decode(response.body);
      return CartValidationResult.fromJson(data['data'] ?? data);
    }

    final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'validateCart');
    ErrorReporter.reportNow(appEx);
    return null;
  } catch (e) {
    final appEx = ErrorHandler.handle(e, context: 'validateCart');
    ErrorReporter.reportNow(appEx);
    return null;
  }
}
```

---

### 1.3 Global Search

**Current State:** No search functionality
**Impact:** Users cannot search for products

#### New Files to Create

| File | Purpose |
|------|---------|
| `lib/models/search_result.dart` | Search result models |
| `lib/services/interfaces/i_search_service.dart` | Search service interface |
| `lib/services/searchService.dart` | Search service implementation |

#### Files to Modify

| File | Changes |
|------|---------|
| `lib/di/locator.dart` | Register `ISearchService` |

#### New Model

```dart
// lib/models/search_result.dart

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

  bool get isEmpty => products.isEmpty && collections.isEmpty && categories.isEmpty;
  int get totalCount => products.length + collections.length + categories.length;
}

class ProductSearchItem {
  final int id;
  final String name;
  final String slug;
  final double price;
  final double? compareAtPrice;
  final String? primaryImage;
  final int availableQuantity;

  ProductSearchItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.compareAtPrice,
    this.primaryImage,
    required this.availableQuantity,
  });

  factory ProductSearchItem.fromJson(Map<String, dynamic> json) {
    return ProductSearchItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      price: _parseDouble(json['price']),
      compareAtPrice: json['compare_at_price'] != null
          ? _parseDouble(json['compare_at_price'])
          : null,
      primaryImage: json['primary_image'] ?? json['main_image'],
      availableQuantity: json['available_quantity'] ?? 0,
    );
  }

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

  CollectionSearchItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.primaryImage,
  });

  factory CollectionSearchItem.fromJson(Map<String, dynamic> json) {
    return CollectionSearchItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      price: ProductSearchItem._parseDouble(json['price']),
      primaryImage: json['primary_image'] ?? json['main_image'],
    );
  }
}

class CategorySearchItem {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  CategorySearchItem({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory CategorySearchItem.fromJson(Map<String, dynamic> json) {
    return CategorySearchItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'],
    );
  }
}
```

#### New Interface

```dart
// lib/services/interfaces/i_search_service.dart
import '../../models/search_result.dart';

abstract class ISearchService {
  /// Perform global search across products, collections, and categories
  ///
  /// [query] - Search term (min 2 characters)
  /// [type] - Filter by result type: 'products', 'collections', 'categories', 'all'
  /// [limit] - Number of results per type (default: 10)
  /// [regionCode] - Optional region code for region-specific results
  Future<SearchResult?> search({
    required String query,
    String type = 'all',
    int limit = 10,
    String? regionCode,
  });
}
```

#### New Service Implementation

```dart
// lib/services/searchService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_result.dart';
import '../config.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';
import '../utils/http_cache_client.dart';
import './interfaces/i_search_service.dart';

class SearchService implements ISearchService {
  @override
  Future<SearchResult?> search({
    required String query,
    String type = 'all',
    int limit = 10,
    String? regionCode,
  }) async {
    // Validate query length
    if (query.trim().length < 2) {
      return SearchResult(products: [], collections: [], categories: []);
    }

    try {
      final queryParams = {
        'q': query.trim(),
        'type': type,
        'limit': limit.toString(),
      };

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/search')
          .replace(queryParameters: queryParams);

      final headers = AppConfig.withNgrokBypass({
        'Accept': 'application/json',
      });

      if (regionCode != null) {
        headers['X-Region-Code'] = regionCode;
      }

      // Use cached client for search results (short TTL)
      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        enableCache: true,
        ttlSeconds: 60, // Cache search results for 1 minute
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          return null;
        }

        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'] ?? jsonBody;
        return SearchResult.fromJson(data);
      }

      final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'search');
      ErrorReporter.reportNow(appEx);
      return null;
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'search');
      ErrorReporter.reportNow(appEx);
      return null;
    }
  }

  bool _looksLikeHtml(String body, Map<String, String> headers) {
    final contentType = headers['content-type'] ?? '';
    return body.trim().startsWith('<!DOCTYPE') ||
        body.trim().startsWith('<html') ||
        contentType.contains('text/html');
  }
}
```

#### Register in Locator

```dart
// Add to lib/di/locator.dart
import '../services/interfaces/i_search_service.dart';
import '../services/searchService.dart';

// In setupLocator():
locator.registerSingleton<ISearchService>(SearchService());
```

---

## Phase 2: Medium Priority (Feature Enhancement)

### 2.1 Collections Service

**Current State:** Collections not implemented
**Impact:** Cannot browse curated bouquets/gift sets

#### New Files to Create

| File | Purpose |
|------|---------|
| `lib/models/collection.dart` | Collection model |
| `lib/services/interfaces/i_collection_service.dart` | Collection service interface |
| `lib/services/collectionService.dart` | Collection service implementation |

#### New Model

```dart
// lib/models/collection.dart

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

  String get mainImage {
    final mainImg = images.firstWhere(
      (img) => img.isMain,
      orElse: () => images.isNotEmpty ? images.first : CollectionImage.empty(),
    );
    return mainImg.imageUrl;
  }

  bool get isInStock => inventory?.isOutOfStock != true;

  int get availableQuantity => inventory?.availableQuantity ?? 0;

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
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

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
}

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
}

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
}

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
}
```

#### New Interface

```dart
// lib/services/interfaces/i_collection_service.dart
import '../../models/collection.dart';

abstract class ICollectionService {
  /// Get paginated list of collections
  Future<List<Collection>> getCollections({
    int skip = 0,
    int limit = 20,
    String? search,
    int? sectionId,
    bool? isFeatured,
    bool? inStock,
    double? minPrice,
    double? maxPrice,
    String? regionCode,
  });

  /// Get collection details by ID
  Future<Collection?> getCollectionDetails(int collectionId, {String? regionCode});
}
```

#### New Service Implementation

```dart
// lib/services/collectionService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/collection.dart';
import '../config.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';
import '../utils/http_cache_client.dart';
import './interfaces/i_collection_service.dart';

class CollectionService implements ICollectionService {
  @override
  Future<List<Collection>> getCollections({
    int skip = 0,
    int limit = 20,
    String? search,
    int? sectionId,
    bool? isFeatured,
    bool? inStock,
    double? minPrice,
    double? maxPrice,
    String? regionCode,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (sectionId != null) queryParams['section_id'] = sectionId.toString();
      if (isFeatured != null) queryParams['is_featured'] = isFeatured.toString();
      if (inStock != null) queryParams['in_stock'] = inStock.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/collections')
          .replace(queryParameters: queryParams);

      final headers = AppConfig.withNgrokBypass({
        'Accept': 'application/json',
      });

      if (regionCode != null) {
        headers['X-Region-Code'] = regionCode;
      }

      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        enableCache: true,
        ttlSeconds: 300, // Cache for 5 minutes
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          return [];
        }

        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'] ?? jsonBody['results'] ?? [];
        return (data as List).map((c) => Collection.fromJson(c)).toList();
      }

      final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'getCollections');
      ErrorReporter.reportNow(appEx);
      return [];
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'getCollections');
      ErrorReporter.reportNow(appEx);
      return [];
    }
  }

  @override
  Future<Collection?> getCollectionDetails(int collectionId, {String? regionCode}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/collections/$collectionId');

      final headers = AppConfig.withNgrokBypass({
        'Accept': 'application/json',
      });

      if (regionCode != null) {
        headers['X-Region-Code'] = regionCode;
      }

      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        enableCache: true,
        ttlSeconds: 300, // Cache for 5 minutes
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          return null;
        }

        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'] ?? jsonBody;
        return Collection.fromJson(data);
      }

      if (response.statusCode == 404) {
        return null;
      }

      final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'getCollectionDetails');
      ErrorReporter.reportNow(appEx);
      return null;
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'getCollectionDetails');
      ErrorReporter.reportNow(appEx);
      return null;
    }
  }

  bool _looksLikeHtml(String body, Map<String, String> headers) {
    final contentType = headers['content-type'] ?? '';
    return body.trim().startsWith('<!DOCTYPE') ||
        body.trim().startsWith('<html') ||
        contentType.contains('text/html');
  }
}
```

---

### 2.2 Regions Service

**Current State:** No multi-region support
**Impact:** Cannot show region-specific products/pricing

#### New Files to Create

| File | Purpose |
|------|---------|
| `lib/models/region.dart` | Region model |
| `lib/services/interfaces/i_region_service.dart` | Region service interface |
| `lib/services/regionService.dart` | Region service implementation |

#### New Model

```dart
// lib/models/region.dart

class Region {
  final int id;
  final String code;
  final String name;
  final String timezone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Region({
    required this.id,
    required this.code,
    required this.name,
    required this.timezone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      timezone: json['timezone'] ?? 'UTC',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'timezone': timezone,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

#### New Interface

```dart
// lib/services/interfaces/i_region_service.dart
import '../../models/region.dart';

abstract class IRegionService {
  /// Get all available regions
  Future<List<Region>> getRegions({bool? isActive});

  /// Get current region based on header or default
  Future<Region?> getCurrentRegion({String? regionCode});

  /// Get saved region code from local storage
  Future<String?> getSavedRegionCode();

  /// Save region code to local storage
  Future<void> saveRegionCode(String regionCode);
}
```

#### New Service Implementation

```dart
// lib/services/regionService.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/region.dart';
import '../config.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';
import '../utils/http_cache_client.dart';
import './interfaces/i_region_service.dart';

class RegionService implements IRegionService {
  static const String _regionCodeKey = 'selected_region_code';
  static const String _cachedRegionsKey = 'cached_regions';

  @override
  Future<List<Region>> getRegions({bool? isActive}) async {
    try {
      final queryParams = <String, String>{};
      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/regions')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final headers = AppConfig.withNgrokBypass({
        'Accept': 'application/json',
      });

      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        enableCache: true,
        ttlSeconds: 3600, // Cache for 1 hour (regions rarely change)
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          return await _getCachedRegions();
        }

        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'] ?? jsonBody['results'] ?? [];
        final regions = (data as List).map((r) => Region.fromJson(r)).toList();

        // Cache regions locally for offline access
        await _cacheRegions(regions);

        return regions;
      }

      final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'getRegions');
      ErrorReporter.reportNow(appEx);
      return await _getCachedRegions();
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'getRegions');
      ErrorReporter.reportNow(appEx);
      return await _getCachedRegions();
    }
  }

  @override
  Future<Region?> getCurrentRegion({String? regionCode}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/regions/current');

      final headers = AppConfig.withNgrokBypass({
        'Accept': 'application/json',
      });

      final code = regionCode ?? await getSavedRegionCode();
      if (code != null) {
        headers['X-Region-Code'] = code;
      }

      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        enableCache: true,
        ttlSeconds: 3600,
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          return null;
        }

        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'] ?? jsonBody;
        return Region.fromJson(data);
      }

      return null;
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'getCurrentRegion');
      ErrorReporter.reportNow(appEx);
      return null;
    }
  }

  @override
  Future<String?> getSavedRegionCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_regionCodeKey);
  }

  @override
  Future<void> saveRegionCode(String regionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionCodeKey, regionCode);
  }

  Future<void> _cacheRegions(List<Region> regions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = regions.map((r) => json.encode(r.toJson())).toList();
    await prefs.setStringList(_cachedRegionsKey, jsonList);
  }

  Future<List<Region>> _getCachedRegions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_cachedRegionsKey) ?? [];
    return jsonList.map((s) => Region.fromJson(json.decode(s))).toList();
  }

  bool _looksLikeHtml(String body, Map<String, String> headers) {
    final contentType = headers['content-type'] ?? '';
    return body.trim().startsWith('<!DOCTYPE') ||
        body.trim().startsWith('<html') ||
        contentType.contains('text/html');
  }
}
```

---

### 2.3 Delivery Fee Calculation

**Current State:** Static delivery fee in order service
**Impact:** Cannot calculate dynamic delivery costs

#### Files to Modify

| File | Changes |
|------|---------|
| `lib/services/interfaces/i_cart_service.dart` | Add `calculateDeliveryFee()` method |
| `lib/services/cartService.dart` | Implement `calculateDeliveryFee()` |

#### New Model (add to cart_validation.dart)

```dart
// Add to lib/models/cart_validation.dart

class DeliveryFeeResult {
  final double deliveryFee;
  final double freeDeliveryThreshold;
  final bool isFreeDelivery;

  DeliveryFeeResult({
    required this.deliveryFee,
    required this.freeDeliveryThreshold,
    required this.isFreeDelivery,
  });

  factory DeliveryFeeResult.fromJson(Map<String, dynamic> json) {
    return DeliveryFeeResult(
      deliveryFee: CartValidationResult._parseDouble(json['delivery_fee']),
      freeDeliveryThreshold: CartValidationResult._parseDouble(json['free_delivery_threshold']),
      isFreeDelivery: json['is_free_delivery'] ?? false,
    );
  }
}
```

#### Interface Addition

```dart
// Add to i_cart_service.dart
Future<DeliveryFeeResult?> calculateDeliveryFee({
  required double subtotal,
  String? regionCode,
  String? postalCode,
});
```

#### Implementation

```dart
// Add to cartService.dart
@override
Future<DeliveryFeeResult?> calculateDeliveryFee({
  required double subtotal,
  String? regionCode,
  String? postalCode,
}) async {
  final token = await _getToken();
  if (token == null) return null;

  try {
    final queryParams = <String, String>{
      'subtotal': subtotal.toString(),
    };

    if (regionCode != null) queryParams['region_code'] = regionCode;
    if (postalCode != null) queryParams['postal_code'] = postalCode;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/cart/delivery-fee')
        .replace(queryParameters: queryParams);

    final headers = AppConfig.withNgrokBypass({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    final response = await CachedHttpClient.instance.get(
      uri,
      headers: headers,
      enableCache: true,
      ttlSeconds: 300, // Cache for 5 minutes
      cacheAuthorizedRequests: true,
    );

    if (response.statusCode == 200) {
      if (_looksLikeHtml(response.body, response.headers)) return null;
      final data = json.decode(response.body);
      return DeliveryFeeResult.fromJson(data['data'] ?? data);
    }

    final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'calculateDeliveryFee');
    ErrorReporter.reportNow(appEx);
    return null;
  } catch (e) {
    final appEx = ErrorHandler.handle(e, context: 'calculateDeliveryFee');
    ErrorReporter.reportNow(appEx);
    return null;
  }
}
```

---

## Phase 3: Low Priority

### 3.1 Product Images Endpoint

**Current State:** Images already included in product details response
**Note:** This is an optimization endpoint - only implement if you need to fetch images separately

---

## Updated Service Locator

After implementing all services, update `lib/di/locator.dart`:

```dart
import '../services/interfaces/i_auth_service.dart';
import '../services/interfaces/i_order_service.dart';
import '../services/interfaces/i_cart_service.dart';
import '../services/interfaces/i_address_service.dart';
import '../services/interfaces/i_product_api_service.dart';
import '../services/interfaces/i_review_service.dart';
import '../services/interfaces/i_search_service.dart';      // NEW
import '../services/interfaces/i_collection_service.dart';  // NEW
import '../services/interfaces/i_region_service.dart';      // NEW

import '../services/authService.dart';
import '../services/orderService.dart' show OrderService;
import '../services/cartService.dart';
import '../services/addressService.dart' show AddressApiService;
import '../services/apiTest.dart';
import '../services/reviewService.dart';
import '../services/searchService.dart';      // NEW
import '../services/collectionService.dart';  // NEW
import '../services/regionService.dart';      // NEW

// ... ServiceLocator class ...

void setupLocator() {
  locator.reset();

  // Core services
  locator.registerSingleton<IAuthService>(AuthService());

  // Services that depend on auth
  locator.registerSingleton<IOrderService>(
    OrderService(authService: locator.get<IAuthService>()),
  );
  locator.registerSingleton<IAddressService>(AddressApiService());

  // Other services
  locator.registerSingleton<ICartService>(CartService());
  locator.registerSingleton<IProductApiService>(ProductApiService());
  locator.registerSingleton<IReviewService>(ReviewApiService());

  // NEW services
  locator.registerSingleton<ISearchService>(SearchService());
  locator.registerSingleton<ICollectionService>(CollectionService());
  locator.registerSingleton<IRegionService>(RegionService());
}
```

---

## Implementation Checklist

### Phase 1: High Priority (COMPLETED)
- [x] 1.1 Add `logoutFromServer()` to AuthService
- [x] 1.2 Create `cart_validation.dart` model
- [x] 1.2 Add `validateCart()` to CartService
- [x] 1.3 Create `search_result.dart` model
- [x] 1.3 Create SearchService with interface
- [x] 1.3 Register SearchService in locator
- [x] 2.3 Add `DeliveryFeeResult` model (included in Phase 1)
- [x] 2.3 Add `calculateDeliveryFee()` to CartService (included in Phase 1)

### Phase 2: Medium Priority (COMPLETED)
- [x] 2.1 Create `collection.dart` model
- [x] 2.1 Create CollectionService with interface
- [x] 2.1 Register CollectionService in locator
- [x] 2.2 Create `region.dart` model
- [x] 2.2 Create RegionService with interface
- [x] 2.2 Register RegionService in locator

### Testing
- [ ] Test server-side logout flow
- [ ] Test cart validation before checkout
- [ ] Test search with various queries
- [ ] Test collections list and details
- [ ] Test regions list and current
- [ ] Test delivery fee calculation

---

## Important Notes

### 1. Endpoint Path Verification

Your current implementation uses different paths than documented:
- Docs: `/auth/login` → App uses: `/token/`
- Docs: `/auth/refresh` → App uses: `/token/refresh/`

**Verify with backend team** which paths are correct for new endpoints.

### 2. Error Handling Pattern

Follow the existing pattern in your codebase:
```dart
final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'methodName');
ErrorReporter.reportNow(appEx);
```

### 3. Caching Strategy

| Endpoint | Cache TTL | Rationale |
|----------|-----------|-----------|
| Regions | 1 hour | Rarely changes |
| Collections list | 5 minutes | Moderate changes |
| Search results | 1 minute | Fresh results preferred |
| Cart validation | No cache | Must be real-time |
| Delivery fee | 5 minutes | Based on subtotal |

### 4. Offline Fallback

Implement fallback for:
- **Regions:** Store last known list in SharedPreferences
- **Collections:** Cache recent data for offline browsing

---

## Estimated Effort

| Phase | Task | Time |
|-------|------|------|
| 1.1 | Server-side logout | 30 min |
| 1.2 | Cart validation | 1 hour |
| 1.3 | Search service | 1.5 hours |
| 2.1 | Collections service | 1.5 hours |
| 2.2 | Regions service | 1 hour |
| 2.3 | Delivery fee | 30 min |
| - | Testing & integration | 1-2 hours |
| **Total** | | **7-8 hours** |

---

## Next Steps

1. **Verify endpoints** with backend team (path naming conventions)
2. **Start with Phase 1** (security and checkout critical)
3. **Create UI components** for search and collections
4. **Add region selector** to app settings/header
5. **Integrate cart validation** into checkout flow
