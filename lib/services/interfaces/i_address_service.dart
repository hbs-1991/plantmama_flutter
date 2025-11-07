import 'dart:async';
import '../../models/address.dart';

abstract class IAddressService {
  Future<List<Address>> getUserAddresses();
  Future<Address> addAddress({
    required String label,
    required String streetAddress,
    required String apartment,
    required String city,
    required String postalCode,
    required bool isDefault,
  });
  Future<Address> updateAddress({
    required int addressId,
    required String label,
    required String streetAddress,
    required String apartment,
    required String city,
    required String postalCode,
    required bool isDefault,
  });
  Future<void> deleteAddress(int addressId);
}


