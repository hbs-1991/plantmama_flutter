import 'package:flutter/foundation.dart' show ChangeNotifier;
import '../services/interfaces/i_address_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../di/locator.dart';
import '../models/address.dart';
import '../utils/app_logger.dart';

/// Address provider for managing user addresses.
///
/// Aligned with FastAPI backend which uses:
/// - full_name, phone for recipient info
/// - address_line1, address_line2 for address details
class AddressesProvider extends ChangeNotifier {
  final IAddressService _addressService = locator.get<IAddressService>();
  final IAuthService _authService = locator.get<IAuthService>();

  bool _isLoading = false;
  List<Address> _addresses = [];
  Address? _selected;

  bool get isLoading => _isLoading;
  List<Address> get addresses => List.unmodifiable(_addresses);
  Address? get selected => _selected;

  Future<void> loadAddresses() async {
    if (!await _authService.isLoggedIn()) {
      AppLogger.debug('User not authenticated, skipping address load', tag: 'AddressesProvider');
      _addresses = [];
      _selected = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      _addresses = await _addressService.getUserAddresses();
      if (_addresses.isNotEmpty) {
        _selected = _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);
      }
      AppLogger.debug('Loaded ${_addresses.length} addresses', tag: 'AddressesProvider');
    } catch (e) {
      AppLogger.error('Error loading addresses', tag: 'AddressesProvider', error: e);
      _addresses = [];
      _selected = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void select(Address? address) {
    _selected = address;
    notifyListeners();
  }

  /// Add address using FastAPI schema fields.
  Future<void> addAddress({
    required String fullName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    String postalCode = '',
    String country = 'Russia',
    bool isDefault = false,
  }) async {
    final added = await _addressService.addAddress(
      fullName: fullName,
      phone: phone,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      postalCode: postalCode,
      country: country,
      isDefault: isDefault,
    );
    _addresses.add(added);
    if (isDefault) {
      _selected = added;
    }
    AppLogger.info('Address added: ${added.id}', tag: 'AddressesProvider');
    notifyListeners();
  }

  /// Update address using FastAPI schema fields.
  Future<void> updateAddress(Address updated) async {
    await _addressService.updateAddress(
      addressId: updated.id,
      fullName: updated.fullName,
      phone: updated.phone,
      addressLine1: updated.addressLine1,
      addressLine2: updated.addressLine2,
      city: updated.city,
      postalCode: updated.postalCode,
      country: updated.country,
      isDefault: updated.isDefault,
    );
    final idx = _addresses.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      _addresses[idx] = updated;
    }
    if (updated.isDefault) {
      _selected = updated;
    }
    AppLogger.info('Address updated: ${updated.id}', tag: 'AddressesProvider');
    notifyListeners();
  }

  Future<void> deleteAddress(int addressId) async {
    await _addressService.deleteAddress(addressId);
    _addresses.removeWhere((a) => a.id == addressId);
    if (_selected?.id == addressId) {
      _selected = _addresses.isNotEmpty ? _addresses.first : null;
    }
    AppLogger.info('Address deleted: $addressId', tag: 'AddressesProvider');
    notifyListeners();
  }
}


