import 'dart:async';
import '../../models/address.dart';

/// Interface for address service operations.
///
/// Aligned with FastAPI backend endpoints:
/// - GET /users/me/addresses - List addresses
/// - POST /users/me/addresses - Create address
/// - PATCH /users/me/addresses/{id} - Update address
/// - DELETE /users/me/addresses/{id} - Delete address
abstract class IAddressService {
  /// Get all addresses for the current user.
  Future<List<Address>> getUserAddresses();

  /// Get a single address by ID.
  Future<Address?> getAddress(int addressId);

  /// Create a new address.
  ///
  /// FastAPI expects:
  /// - full_name: Recipient name (required)
  /// - phone: Contact phone (required)
  /// - address_line1: Street address (required)
  /// - address_line2: Apartment/floor (optional)
  /// - city: City name (required)
  /// - postal_code: Postal code
  /// - country: Country (default: Russia)
  /// - is_default: Set as default address
  Future<Address> addAddress({
    required String fullName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    String postalCode,
    String country,
    bool isDefault,
  });

  /// Update an existing address.
  Future<Address> updateAddress({
    required int addressId,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    String? country,
    bool? isDefault,
  });

  /// Delete an address by ID.
  Future<void> deleteAddress(int addressId);

  /// Set an address as the default.
  Future<void> setDefaultAddress(int addressId);
}
