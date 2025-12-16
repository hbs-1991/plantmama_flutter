import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../constants/api_paths.dart';
import '../models/address.dart';
import './interfaces/i_address_service.dart';
import './interfaces/i_auth_service.dart';
import '../di/locator.dart';
import '../utils/app_logger.dart';

/// Address service implementation for FastAPI backend.
///
/// Endpoints (no trailing slashes - FastAPI style):
/// - GET /users/me/addresses - List addresses
/// - GET /users/me/addresses/{id} - Get single address
/// - POST /users/me/addresses - Create address
/// - PATCH /users/me/addresses/{id} - Update address
/// - DELETE /users/me/addresses/{id} - Delete address
class AddressApiService implements IAddressService {
  /// Helper to extract data from FastAPI response wrapper.
  ///
  /// FastAPI responses follow the format:
  /// ```json
  /// { "success": true, "data": [...] }
  /// ```
  /// or just the raw data array/object.
  dynamic _extractData(dynamic jsonBody) {
    if (jsonBody is Map && jsonBody.containsKey('data')) {
      return jsonBody['data'];
    }
    return jsonBody;
  }

  /// Parse FastAPI error response.
  ///
  /// FastAPI error format:
  /// ```json
  /// {
  ///   "success": false,
  ///   "error": { "code": "NOT_FOUND", "message": "Address not found" }
  /// }
  /// ```
  /// or validation errors:
  /// ```json
  /// { "detail": [{ "loc": ["body", "phone"], "msg": "field required" }] }
  /// ```
  String _parseError(String responseBody) {
    try {
      final jsonBody = json.decode(responseBody);

      // FastAPI standard error format
      if (jsonBody is Map) {
        if (jsonBody['error'] is Map) {
          return jsonBody['error']['message'] ?? 'Unknown error';
        }
        if (jsonBody['detail'] is String) {
          return jsonBody['detail'];
        }
        if (jsonBody['detail'] is List) {
          // Validation errors
          final details = jsonBody['detail'] as List;
          return details.map((e) => e['msg'] ?? e.toString()).join(', ');
        }
        if (jsonBody['message'] is String) {
          return jsonBody['message'];
        }
      }
    } catch (_) {}
    return 'Server error';
  }

  @override
  Future<List<Address>> getUserAddresses() async {
    try {
      AppLogger.debug('Fetching user addresses...', tag: 'AddressService');

      final authService = locator.get<IAuthService>();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}${ApiPaths.userAddresses}'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final data = _extractData(jsonBody);

        if (data is List) {
          return data.map((item) => Address.fromJson(item)).toList();
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('User not authenticated');
      } else {
        AppLogger.warning(
          'Failed to fetch addresses: ${response.statusCode}',
          tag: 'AddressService',
        );
        return [];
      }
    } catch (e) {
      AppLogger.error('Error fetching addresses', tag: 'AddressService', error: e);
      return [];
    }
  }

  @override
  Future<Address?> getAddress(int addressId) async {
    try {
      AppLogger.debug('Fetching address $addressId...', tag: 'AddressService');

      final authService = locator.get<IAuthService>();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}${ApiPaths.userAddress(addressId)}'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final data = _extractData(jsonBody);
        return Address.fromJson(data);
      } else if (response.statusCode == 404) {
        AppLogger.debug('Address $addressId not found', tag: 'AddressService');
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('User not authenticated');
      } else {
        AppLogger.warning(
          'Failed to fetch address: ${response.statusCode}',
          tag: 'AddressService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error('Error fetching address', tag: 'AddressService', error: e);
      return null;
    }
  }

  @override
  Future<Address> addAddress({
    required String fullName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    String postalCode = '',
    String country = 'Russia',
    bool isDefault = false,
  }) async {
    AppLogger.debug('Creating new address...', tag: 'AddressService');

    final authService = locator.get<IAuthService>();
    final token = await authService.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final addressData = {
      'full_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      if (addressLine2 != null && addressLine2.isNotEmpty)
        'address_line2': addressLine2,
      'city': city,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
    };

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}${ApiPaths.userAddresses}'),
      headers: AppConfig.withNgrokBypass({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      }),
      body: json.encode(addressData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      final data = _extractData(jsonBody);
      AppLogger.info('Address created successfully', tag: 'AddressService');
      return Address.fromJson(data);
    } else if (response.statusCode == 422 || response.statusCode == 400) {
      throw Exception(_parseError(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('User not authenticated');
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  @override
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
  }) async {
    AppLogger.debug('Updating address $addressId...', tag: 'AddressService');

    final authService = locator.get<IAuthService>();
    final token = await authService.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final addressData = <String, dynamic>{};
    if (fullName != null) addressData['full_name'] = fullName;
    if (phone != null) addressData['phone'] = phone;
    if (addressLine1 != null) addressData['address_line1'] = addressLine1;
    if (addressLine2 != null) addressData['address_line2'] = addressLine2;
    if (city != null) addressData['city'] = city;
    if (postalCode != null) addressData['postal_code'] = postalCode;
    if (country != null) addressData['country'] = country;
    if (isDefault != null) addressData['is_default'] = isDefault;

    final response = await http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}${ApiPaths.userAddress(addressId)}'),
      headers: AppConfig.withNgrokBypass({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      }),
      body: json.encode(addressData),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      final data = _extractData(jsonBody);
      AppLogger.info('Address updated successfully', tag: 'AddressService');
      return Address.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Address not found');
    } else if (response.statusCode == 422 || response.statusCode == 400) {
      throw Exception(_parseError(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('User not authenticated');
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteAddress(int addressId) async {
    AppLogger.debug('Deleting address $addressId...', tag: 'AddressService');

    final authService = locator.get<IAuthService>();
    final token = await authService.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}${ApiPaths.userAddress(addressId)}'),
      headers: AppConfig.withNgrokBypass({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      AppLogger.info('Address deleted successfully', tag: 'AddressService');
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Address not found');
    } else if (response.statusCode == 401) {
      throw Exception('User not authenticated');
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  @override
  Future<void> setDefaultAddress(int addressId) async {
    // Use PATCH to set is_default: true
    await updateAddress(addressId: addressId, isDefault: true);
  }
}
