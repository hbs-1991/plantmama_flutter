import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/address.dart';
import './interfaces/i_address_service.dart';
import './interfaces/i_auth_service.dart';
import '../di/locator.dart';

class AddressApiService implements IAddressService {

  @override
  Future<List<Address>> getUserAddresses() async {
    try {
      print('AddressService: Получаем адреса пользователя...');
      
      final authService = locator.get<IAuthService>();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/addresses/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        try {
          final jsonBody = json.decode(response.body);
          if (jsonBody is List) {
            return List<Address>.from(jsonBody.map((json) => Address.fromJson(json)));
          } else if (jsonBody is Map && jsonBody['results'] is List) {
            return List<Address>.from(jsonBody['results'].map((json) => Address.fromJson(json)));
          } else {
            return [];
          }
        } catch (e) {
          print('AddressService: Ошибка парсинга JSON адресов: $e');
          return []; // Возвращаем пустой список вместо ошибки
        }
      } else if (response.statusCode == 401) {
        throw Exception('Пользователь не авторизован');
      } else if (response.statusCode == 404) {
        print('AddressService: Адреса не найдены (404)');
        return []; // Возвращаем пустой список для 404
      } else {
        print('AddressService: Неожиданный статус код: ${response.statusCode}');
        return []; // Возвращаем пустой список вместо ошибки
      }
    } catch (e) {
      print('AddressService: Ошибка при получении адресов: $e');
      return []; // Возвращаем пустой список вместо ошибки
    }
  }

  @override
  Future<Address?> getAddress(int addressId) async {
    try {
      print('AddressService: Получаем адрес $addressId...');
      
      final authService = locator.get<IAuthService>();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/addresses/$addressId/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        try {
          final jsonBody = json.decode(response.body);
          return Address.fromJson(jsonBody);
        } catch (e) {
          print('AddressService: Ошибка парсинга JSON адреса: $e');
          return null; // Возвращаем null вместо ошибки
        }
      } else if (response.statusCode == 404) {
        print('AddressService: Адрес $addressId не найден');
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Пользователь не авторизован');
      } else {
        print('AddressService: Неожиданный статус код: ${response.statusCode}');
        return null; // Возвращаем null вместо ошибки
      }
    } catch (e) {
      print('AddressService: Ошибка при получении адреса: $e');
      return null; // Возвращаем null вместо ошибки
    }
  }

  @override
  Future<Address> addAddress({
    required String label,
    required String streetAddress,
    required String apartment,
    required String city,
    required String postalCode,
    required bool isDefault,
  }) async {
    try {
      print('AddressService: Создаем новый адрес...');
      
      final authService = locator.get<IAuthService>();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Пользователь не авторизован');
      }

      final addressData = {
        'label': label,
        'street_address': streetAddress,
        'apartment': apartment,
        'city': city,
        'postal_code': postalCode,
        'country': 'Turkmenistan',
        'is_default': isDefault,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/add_address/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }),
        body: json.encode(addressData),
      );

      if (response.statusCode == 201) {
        try {
          final jsonBody = json.decode(response.body);
          return Address.fromJson(jsonBody);
        } catch (e) {
          print('AddressService: Ошибка парсинга JSON созданного адреса: $e');
          throw Exception('Ошибка обработки ответа сервера');
        }
      } else if (response.statusCode == 400) {
        try {
          final errorBody = json.decode(response.body);
          final detail = errorBody['detail'] ?? 'Неизвестная ошибка';
          throw Exception(detail);
        } catch (e) {
          throw Exception('Ошибка валидации данных адреса');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Пользователь не авторизован');
      } else {
        print('AddressService: Неожиданный статус код: ${response.statusCode}');
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('AddressService: Ошибка при создании адреса: $e');
      rethrow; // Для создания адреса все же пробрасываем ошибку
    }
  }

  @override
  Future<Address> updateAddress({
    required int addressId,
    required String label,
    required String streetAddress,
    required String apartment,
    required String city,
    required String postalCode,
    required bool isDefault,
  }) async {
    try {
      print('AddressService: Обновляем адрес $addressId...');
      
      final authService = locator.get<IAuthService>();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Пользователь не авторизован');
      }

      final addressData = {
        'label': label,
        'street_address': streetAddress,
        'apartment': apartment,
        'city': city,
        'postal_code': postalCode,
        'country': 'Turkmenistan',
        'is_default': isDefault,
      };

      final response = await http.patch(
        Uri.parse('${AppConfig.apiBaseUrl}/users/update_address/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }),
        body: json.encode(addressData),
      );

      if (response.statusCode == 200) {
        try {
          final jsonBody = json.decode(response.body);
          return Address.fromJson(jsonBody);
        } catch (e) {
          print('AddressService: Ошибка парсинга JSON обновленного адреса: $e');
          throw Exception('Ошибка обработки ответа сервера');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Адрес не найден');
      } else if (response.statusCode == 400) {
        try {
          final errorBody = json.decode(response.body);
          final detail = errorBody['detail'] ?? 'Неизвестная ошибка';
          throw Exception(detail);
        } catch (e) {
          throw Exception('Ошибка валидации данных адреса');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Пользователь не авторизован');
      } else {
        print('AddressService: Неожиданный статус код: ${response.statusCode}');
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('AddressService: Ошибка при обновлении адреса: $e');
      rethrow; // Для обновления адреса все же пробрасываем ошибку
    }
  }

  @override
  Future<void> deleteAddress(int addressId) async {
    try {
      print('AddressService: Удаляем адрес $addressId...');
      
      final authService = locator.get<IAuthService>();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Пользователь не авторизован');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/users/delete_address/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Адрес не найден');
      } else if (response.statusCode == 401) {
        throw Exception('Пользователь не авторизован');
      } else {
        print('AddressService: Неожиданный статус код: ${response.statusCode}');
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('AddressService: Ошибка при удалении адреса: $e');
      rethrow; // Для удаления адреса все же пробрасываем ошибку
    }
  }
} 