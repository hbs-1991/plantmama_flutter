import 'dart:async';
import '../../models/search_result.dart';

/// Interface for global search functionality
/// Provides search across products, collections, and categories
abstract class ISearchService {
  /// Perform global search across products, collections, and categories
  ///
  /// [query] - Search term (minimum 2 characters recommended)
  /// [type] - Filter by result type: 'products', 'collections', 'categories', 'all'
  /// [limit] - Number of results per type (default: 10)
  /// [regionCode] - Optional region code for region-specific results
  ///
  /// Returns SearchResult with matching items, or null on error
  /// Returns empty SearchResult for queries shorter than 2 characters
  Future<SearchResult?> search({
    required String query,
    String type = 'all',
    int limit = 10,
    String? regionCode,
  });

  /// Search only for products
  /// Convenience method that wraps search() with type='products'
  Future<List<ProductSearchItem>> searchProducts({
    required String query,
    int limit = 20,
    String? regionCode,
  });

  /// Search only for collections
  /// Convenience method that wraps search() with type='collections'
  Future<List<CollectionSearchItem>> searchCollections({
    required String query,
    int limit = 10,
    String? regionCode,
  });

  /// Search only for categories
  /// Convenience method that wraps search() with type='categories'
  Future<List<CategorySearchItem>> searchCategories({
    required String query,
    int limit = 10,
    String? regionCode,
  });
}
