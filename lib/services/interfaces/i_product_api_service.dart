import 'dart:async';
import '../../models/product.dart';
import '../../models/section.dart';
import '../../models/category.dart';

/// Interface for product-related API operations.
///
/// Implements FastAPI backend endpoints with response format:
/// `{success: true, data: [...], meta: {page, page_size, total, total_pages}}`
abstract class IProductApiService {
  /// Fetches products with optional filtering.
  ///
  /// Parameters match FastAPI `/products` endpoint:
  /// - [skip]: Items to skip for pagination (default: 0)
  /// - [limit]: Max items per page (default: 100, max: 100)
  /// - [search]: Search in name/description
  /// - [sectionId]: Filter by section (section_id)
  /// - [categoryId]: Filter by category (category_id)
  /// - [isFeatured]: Filter featured products only
  /// - [inStock]: Filter in-stock products only
  /// - [minPrice], [maxPrice]: Price range filter
  /// - [regionCode]: X-Region-Code header value
  Future<List<Product>> getProducts({
    int skip = 0,
    int limit = 100,
    String? search,
    int? sectionId,
    int? categoryId,
    bool? isFeatured,
    bool? inStock,
    double? minPrice,
    double? maxPrice,
    String? regionCode,
  });

  /// Fetches a single product by ID.
  Future<Product?> getProductById(int id);

  /// Fetches sections with optional filtering.
  ///
  /// Parameters match FastAPI `/product-sections` endpoint:
  /// - [skip], [limit]: Pagination
  /// - [isActive]: Filter active sections only
  /// - [regionCode]: X-Region-Code header value
  Future<List<Section>> getSections({
    int skip = 0,
    int limit = 50,
    bool? isActive,
    String? regionCode,
  });

  /// Fetches categories with optional filtering.
  ///
  /// Parameters match FastAPI `/products/categories` endpoint:
  /// - [skip], [limit]: Pagination
  /// - [sectionId]: Filter by section
  /// - [parentId]: Filter by parent category (for hierarchical)
  /// - [isActive]: Filter active categories only
  /// - [regionCode]: X-Region-Code header value
  Future<List<Category>> getCategories({
    int skip = 0,
    int limit = 50,
    int? sectionId,
    int? parentId,
    bool? isActive,
    String? regionCode,
  });
}


