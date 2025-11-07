import 'package:flutter/foundation.dart' show ChangeNotifier;
import '../services/interfaces/i_address_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../di/locator.dart';
import '../models/address.dart';

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
    // Проверяем авторизацию перед загрузкой
    if (!await _authService.isLoggedIn()) {
      print('AddressesProvider: Пользователь не авторизован, пропускаем загрузку адресов');
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
    } catch (e) {
      print('AddressesProvider: Ошибка загрузки адресов: $e');
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

  Future<void> addAddress({
    required String label,
    required String streetAddress,
    String? apartment,
    required String city,
    String? postalCode,
    bool isDefault = false,
  }) async {
    final added = await _addressService.addAddress(
      label: label,
      streetAddress: streetAddress,
      apartment: apartment ?? '',
      city: city,
      postalCode: postalCode ?? '',
      isDefault: isDefault,
    );
    _addresses.add(added);
    if (isDefault) {
      _selected = added;
    }
    notifyListeners();
  }

  Future<void> updateAddress(Address updated) async {
    await _addressService.updateAddress(
      addressId: updated.id,
      label: updated.label,
      streetAddress: updated.streetAddress,
      apartment: updated.apartment,
      city: updated.city,
      postalCode: updated.postalCode,
      isDefault: updated.isDefault,
    );
    final idx = _addresses.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      _addresses[idx] = updated;
    }
    if (updated.isDefault) {
      _selected = updated;
    }
    notifyListeners();
  }

  Future<void> deleteAddress(int addressId) async {
    await _addressService.deleteAddress(addressId);
    _addresses.removeWhere((a) => a.id == addressId);
    if (_selected?.id == addressId) {
      _selected = _addresses.isNotEmpty ? _addresses.first : null;
    }
    notifyListeners();
  }
}


