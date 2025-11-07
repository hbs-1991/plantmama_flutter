import 'package:http/http.dart' as http;
import '../config.dart';

class ApiStatus {
  static final String _baseUrl = AppConfig.apiBaseUrl;
  
  // Проверка доступности API
  static Future<bool> isApiAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/'),
        headers: AppConfig.withNgrokBypass({
          'Accept': 'application/json',
        }),
      );
      
      print('API Status Check: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (e) {
      print('API Status Check Error: $e');
      return false;
    }
  }

  // Проверка конкретного эндпоинта
  static Future<Map<String, dynamic>> checkEndpoint(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: AppConfig.withNgrokBypass({
          'Accept': 'application/json',
        }),
      );
      
      return {
        'available': true,
        'statusCode': response.statusCode,
        'body': response.body,
        'headers': response.headers,
      };
    } catch (e) {
      return {
        'available': false,
        'error': e.toString(),
      };
    }
  }

  // Получение информации о состоянии API
  static Future<Map<String, dynamic>> getApiHealth() async {
    final endpoints = [
      '/orders/',
      '/cart/my_cart/',
      '/products/',
      '/orders/delivery-methods/',
      '/orders/payment-methods/',
    ];

    final results = <String, dynamic>{};
    
    for (final endpoint in endpoints) {
      results[endpoint] = await checkEndpoint(endpoint);
    }

    final overallAvailable = results.values.any((result) => result['available'] == true);
    
    return {
      'overall_available': overallAvailable,
      'endpoints': results,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Проверка CORS
  static Future<bool> checkCorsSupport() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/'),
        headers: AppConfig.withNgrokBypass({
          'Origin': AppConfig.webOrigin,
          'Accept': 'application/json',
        }),
      );
      
      final hasCorsHeaders = response.headers.containsKey('access-control-allow-origin') ||
                            response.headers.containsKey('access-control-allow-methods');
      
      print('CORS Check: $hasCorsHeaders');
      print('CORS Headers: ${response.headers}');
      
      return hasCorsHeaders;
    } catch (e) {
      print('CORS Check Error: $e');
      return false;
    }
  }

  // Получение диагностической информации
  static Future<Map<String, dynamic>> getDiagnostics() async {
    final apiHealth = await getApiHealth();
    final corsSupport = await checkCorsSupport();
    
    return {
      ...apiHealth,
      'cors_support': corsSupport,
      'user_agent': 'Flutter Web App',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
