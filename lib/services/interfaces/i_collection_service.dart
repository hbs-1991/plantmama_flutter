import '../../models/collection.dart';

/// Interface for managing product collections (curated bundles like bouquets, gift sets)
///
/// Collections group multiple products together at a fixed price, typically offering
/// a discount compared to purchasing items individually.
abstract class ICollectionService {
  /// Retrieves a paginated list of collections with optional filtering
  ///
  /// Parameters:
  /// - [skip]: Number of items to skip (for pagination)
  /// - [limit]: Maximum number of items to return
  /// - [search]: Text search filter on collection name/description
  /// - [sectionId]: Filter by product section
  /// - [isFeatured]: Filter featured collections only
  /// - [inStock]: Filter by stock availability
  /// - [minPrice]: Minimum price filter
  /// - [maxPrice]: Maximum price filter
  /// - [regionCode]: Region code for region-specific pricing/availability
  ///
  /// Returns empty list on error or no results.
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

  /// Retrieves detailed information for a specific collection
  ///
  /// Parameters:
  /// - [collectionId]: The ID of the collection to fetch
  /// - [regionCode]: Optional region code for region-specific data
  ///
  /// Returns null if collection not found or on error.
  Future<Collection?> getCollectionDetails(
    int collectionId, {
    String? regionCode,
  });

  /// Retrieves featured collections for homepage display
  ///
  /// Parameters:
  /// - [limit]: Maximum number of featured collections to return
  /// - [regionCode]: Optional region code for region-specific data
  Future<List<Collection>> getFeaturedCollections({
    int limit = 6,
    String? regionCode,
  });

  /// Retrieves collections by section (category)
  ///
  /// Parameters:
  /// - [sectionId]: The section ID to filter by
  /// - [skip]: Number of items to skip
  /// - [limit]: Maximum items to return
  /// - [regionCode]: Optional region code
  Future<List<Collection>> getCollectionsBySection(
    int sectionId, {
    int skip = 0,
    int limit = 20,
    String? regionCode,
  });
}
