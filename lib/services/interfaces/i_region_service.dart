import '../../models/region.dart';

/// Interface for managing service regions
///
/// Regions control what products, pricing, and delivery options are available
/// to users based on their geographic location or preference.
abstract class IRegionService {
  /// Retrieves all available regions
  ///
  /// Parameters:
  /// - [isActive]: If provided, filters regions by active status
  ///
  /// Returns cached data if API is unavailable.
  Future<List<Region>> getRegions({bool? isActive});

  /// Retrieves the current region based on stored preference or default
  ///
  /// Parameters:
  /// - [regionCode]: Optional explicit region code to look up
  ///
  /// Returns null if no region is set and API is unavailable.
  Future<Region?> getCurrentRegion({String? regionCode});

  /// Gets the saved region code from local storage
  ///
  /// Returns null if no region has been saved.
  Future<String?> getSavedRegionCode();

  /// Saves the selected region code to local storage
  ///
  /// Parameters:
  /// - [regionCode]: The region code to save
  Future<void> saveRegionCode(String regionCode);

  /// Clears the saved region preference
  Future<void> clearSavedRegion();

  /// Gets a region by its code
  ///
  /// Parameters:
  /// - [code]: The region code to look up
  ///
  /// Returns null if region not found.
  Future<Region?> getRegionByCode(String code);
}
