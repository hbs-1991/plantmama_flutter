import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/authService.dart';
import 'config.dart';

class AddressApiTest {
  static final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService = AuthService();

  Future<void> testAddressApi() async {
    try {
      print('=== ТЕСТ API АДРЕСОВ ===');
      
      // 1. Проверяем токен
      final token = await _authService.getToken();
      print('1. Токен: ${token != null ? "найден" : "не найден"}');
      if (token == null) {
        print('ОШИБКА: Токен не найден!');
        return;
      }
      
      // 2. Тестируем получение адресов
      print('\n2. Тестируем GET /users/addresses/');
      final response = await http.get(
        Uri.parse('$baseUrl/users/addresses/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );
      
      print('Статус ответа: ${response.statusCode}');
      print('Тело ответа: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Количество адресов: ${data.length}');
        
        for (int i = 0; i < data.length; i++) {
          print('Адрес ${i + 1}: ${data[i]}');
        }
      } else {
        print('ОШИБКА: Не удалось получить адреса');
      }
      
    } catch (e) {
      print('ОШИБКА: $e');
    }
  }
} 