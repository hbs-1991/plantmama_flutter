import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/http_cache_client.dart';
import '../models/order.dart';
import './interfaces/i_order_service.dart';
import './interfaces/i_auth_service.dart';
import '../config.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';

class OrderService implements IOrderService {
  static final String _baseUrl = AppConfig.apiBaseUrl;
  final IAuthService _authService;

  // Константы для настройки
  // Убираем таймауты - ждем загрузки столько, сколько нужно
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2); // Увеличиваем с 1 до 2

  OrderService({required IAuthService authService}) : _authService = authService;

  Future<String?> _getToken() async {
    try {
      final token = await _authService.getToken();
      print('OrderService: _getToken() - получен токен: ${token != null ? "${token.substring(0, 10)}..." : "null"}');
      return token;
    } catch (e) {
      print('OrderService: Ошибка получения токена: $e');
      return null;
    }
  }

  // Проверка доступности API с retry логикой
  Future<bool> _isApiAvailable() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/orders/');
      Map<String, String> baseHeaders = {
        'Accept': 'application/json',
      };
        
        final response = await CachedHttpClient.instance.get(
        uri,
        headers: baseHeaders,
          // Убираем таймаут - ждем загрузки столько, сколько нужно
        enableCache: true,
        ttlSeconds: 60,
      );
        
        // Проверяем, не является ли ответ HTML страницей ngrok
        if (response.body.contains('<!DOCTYPE html>') && 
            response.body.contains('ngrok') &&
            response.body.contains('ERR_NGROK_6024')) {
          print('OrderService: ngrok требует авторизации или недоступен');
          return false;
        }
        
        if (response.statusCode == 200 || response.statusCode == 401) {
          return true;
        }
    } catch (e) {
        print('OrderService: Попытка $attempt проверки API: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
        }
      }
    }
    print('OrderService: API недоступен после $_maxRetries попыток');
    return false;
  }

  // Метод получения заказов пользователя
  @override
  Future<List<Order>> getUserOrders() async {
    try {
      // Проверяем доступность API
      if (!await _isApiAvailable()) {
        print('OrderService: API недоступен');
        throw Exception('API недоступен. Проверьте подключение к интернету.');
      }

      final token = await _getToken();
      if (token == null) {
        print('OrderService: Токен не найден');
        throw Exception('Требуется авторизация для получения заказов.');
      }

      final response = await CachedHttpClient.instance.get(
        Uri.parse('${AppConfig.apiBaseUrl}/orders/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
           // Убираем таймаут - ждем загрузки столько, сколько нужно
        enableCache: false, // Не кешировать список заказов для актуальности
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        print('OrderService: Полный ответ API: ${response.body}');

        if (jsonBody is Map<String, dynamic>) {
          if (jsonBody['results'] is List) {
            final orders = List<Order>.from(
              jsonBody['results'].map((order) => Order.fromJson(order))
            );
            print('OrderService: Успешно загружено ${orders.length} заказов из API (results)');
            return orders;
          } else if (jsonBody['data'] is List) {
            // Некоторые API возвращают данные в поле 'data'
            final orders = List<Order>.from(
              jsonBody['data'].map((order) => Order.fromJson(order))
            );
            print('OrderService: Успешно загружено ${orders.length} заказов из API (data)');
            return orders;
          } else if (jsonBody['success'] == true && jsonBody['data'] is List) {
            // API возвращает success: true, data: [...]
            final orders = List<Order>.from(
              jsonBody['data'].map((order) => Order.fromJson(order))
            );
            print('OrderService: Успешно загружено ${orders.length} заказов из API (success+data)');
            return orders;
          }
        } else if (jsonBody is List) {
          final orders = List<Order>.from(
            jsonBody.map((order) => Order.fromJson(order))
          );
          print('OrderService: Успешно загружено ${orders.length} заказов из API (direct list)');
          return orders;
        }

        print('OrderService: Неожиданная структура ответа: $jsonBody');
        throw Exception('Неожиданная структура ответа от сервера');
      } else if (response.statusCode == 401) {
        print('OrderService: Неавторизованный доступ');
        throw Exception('Требуется авторизация. Войдите в систему.');
      } else {
        print('OrderService: HTTP ошибка ${response.statusCode}');
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderService: Ошибка получения заказов: $e');
      if (e is Exception) {
        rethrow;
        }
      final appEx = ErrorHandler.handle(e, context: 'getUserOrders');
      ErrorReporter.reportNow(appEx);
      throw Exception('Ошибка получения заказов: $e');
    }
  }



  // Улучшенный метод создания заказа
  @override
  Future<Order?> createOrder(CreateOrderRequest request) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
    try {
      // Проверяем доступность API
      if (!await _isApiAvailable()) {
        throw Exception('API недоступен. Проверьте подключение к интернету или обратитесь к администратору.');
      }

      final token = await _getToken();
      if (token == null) {
          throw Exception('Требуется авторизация для создания заказа.');
        }

        // Валидация данных
        if (request.items.isEmpty) {
          throw Exception('Корзина пуста. Добавьте товары перед оформлением заказа.');
        }

        if (request.customerName.trim().isEmpty) {
          throw Exception('Имя получателя обязательно для заполнения.');
        }

        if (request.customerPhone.trim().isEmpty) {
          throw Exception('Телефон получателя обязателен для заполнения.');
        }
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/orders/checkout/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
        body: json.encode(request.toJson()),
      );

        if (response.statusCode == 200 || response.statusCode == 201) {
          try {
            final jsonBody = json.decode(response.body);
            final order = Order.fromJson(jsonBody);
            print('OrderService: Заказ успешно создан с ID ${order.id}');
            return order;
          } catch (e) {
            print('OrderService: Ошибка парсинга ответа: $e');
            // Возвращаем базовый заказ на основе request
            return _createOrderFromRequest(request);
          }
        } else if (response.statusCode == 400) {
          final errorBody = json.decode(response.body);
          final errorMessage = _extractErrorMessage(errorBody);
          throw Exception('Ошибка валидации: $errorMessage');
        } else if (response.statusCode == 401) {
          print('OrderService: Неавторизованный доступ');
          throw Exception('Пользователь не авторизован');
        } else {
          print('OrderService: HTTP ошибка ${response.statusCode}, попытка $attempt');
          if (attempt < _maxRetries) {
            await Future.delayed(_retryDelay * attempt);
            continue;
          }
          final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'createOrder');
          ErrorReporter.reportNow(appEx);
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      } catch (e) {
        print('OrderService: Ошибка попытки $attempt: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
        final appEx = ErrorHandler.handle(e, context: 'createOrder');
        ErrorReporter.reportNow(appEx);
        rethrow;
      }
    }

    throw Exception('Не удалось создать заказ после $_maxRetries попыток.');
  }

  // Создание заказа из request для fallback
  Order _createOrderFromRequest(CreateOrderRequest request) {
    return Order(
      id: DateTime.now().millisecondsSinceEpoch,
      orderNumber: DateTime.now().millisecondsSinceEpoch.toString(),
      status: 'Новый',
      totalAmount: request.items.fold(0.0, (sum, item) => sum + (item['price'] ?? 0.0)),
      subtotal: request.items.fold(0.0, (sum, item) => sum + (item['price'] ?? 0.0)),
      deliveryFee: 20.0,
      deliveryMethod: request.deliveryMethod.toString(),
      paymentMethod: request.paymentMethod.toString(),
      customerName: request.customerName,
      customerPhone: request.customerPhone,
      customerEmail: request.customerEmail,
      notes: request.notes,
      items: request.items.map((item) => OrderItem(
        id: item['id'] ?? 0,
        productId: item['product_id'] ?? 0,
        productName: item['name'] ?? 'Товар',
        productImage: '',
        price: (item['price'] ?? 0.0).toDouble(),
        quantity: item['quantity'] ?? 1,
        totalPrice: (item['total_price'] ?? 0.0).toDouble(),
      )).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Извлечение сообщения об ошибке
  String _extractErrorMessage(Map<String, dynamic> errorBody) {
    if (errorBody.containsKey('detail')) {
      return errorBody['detail'].toString();
    }
    if (errorBody.containsKey('message')) {
      return errorBody['message'].toString();
    }
    if (errorBody.containsKey('error')) {
      return errorBody['error'].toString();
    }
    // Пытаемся извлечь первую ошибку валидации
    for (final entry in errorBody.entries) {
      if (entry.value is List && (entry.value as List).isNotEmpty) {
        return '${entry.key}: ${(entry.value as List).first}';
      }
    }
    return 'Неизвестная ошибка валидации';
  }

  @override
  Future<Order?> getOrderDetails(int orderId) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
    try {
        if (!await _isApiAvailable()) {
          return null;
        }

      final token = await _getToken();
        if (token == null) {
          return null;
        }

              final response = await CachedHttpClient.instance.get(
          Uri.parse('${AppConfig.apiBaseUrl}/orders/$orderId/'),
          headers: AppConfig.withNgrokBypass({
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          }),
          // Убираем таймаут - ждем загрузки столько, сколько нужно
          enableCache: true,
          ttlSeconds: 1800, // 30 минут кеш для деталей заказа
          cacheAuthorizedRequests: true,
        );

      if (response.statusCode == 200) {
          try {
        final jsonBody = json.decode(response.body);
        return Order.fromJson(jsonBody);
          } catch (e) {
            print('OrderService: Ошибка парсинга деталей заказа: $e');
            return null;
          }
        } else if (response.statusCode == 404) {
          print('OrderService: Заказ $orderId не найден');
          return null;
        } else if (response.statusCode == 401) {
          print('OrderService: Неавторизованный доступ к заказу $orderId');
          return null;
      } else {
          print('OrderService: HTTP ошибка ${response.statusCode} для заказа $orderId');
          if (attempt < _maxRetries) {
            await Future.delayed(_retryDelay * attempt);
            continue;
          }
          return null;
      }
    } catch (e) {
        print('OrderService: Ошибка получения деталей заказа $orderId, попытка $attempt: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
      return null;
      }
    }
    return null;
  }

  // Улучшенный метод отмены заказа
  @override
  Future<bool> cancelOrder(int orderId) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
    try {
        if (!await _isApiAvailable()) {
          throw Exception('API недоступен. Проверьте подключение к интернету или обратитесь к администратору.');
        }

      final token = await _getToken();
        if (token == null) {
          throw Exception('Требуется авторизация для отмены заказа.');
        }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/orders/$orderId/cancel/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
        );

      if (response.statusCode == 200 || response.statusCode == 204) {
          print('OrderService: Заказ $orderId успешно отменен');
        return true;
        } else if (response.statusCode == 400) {
          final errorBody = json.decode(response.body);
          final errorMessage = _extractErrorMessage(errorBody);
          throw Exception('Ошибка отмены заказа: $errorMessage');
        } else if (response.statusCode == 404) {
          throw Exception('Заказ не найден.');
        } else if (response.statusCode == 401) {
          throw Exception('Требуется авторизация. Войдите в систему.');
      } else {
          print('OrderService: HTTP ошибка ${response.statusCode} при отмене заказа $orderId');
          if (attempt < _maxRetries) {
            await Future.delayed(_retryDelay * attempt);
            continue;
          }
          throw Exception('Ошибка сервера при отмене заказа.');
        }
      } catch (e) {
        if (e is Exception) {
          rethrow;
        }
        print('OrderService: Ошибка отмены заказа $orderId, попытка $attempt: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
        final appEx = ErrorHandler.handle(e, context: 'cancelOrder');
        ErrorReporter.reportNow(appEx);
        return false;
      }
    }
    return false;
  }

  // Улучшенный метод повторного заказа
  @override
  Future<bool> reorder(int orderId) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
    try {
        if (!await _isApiAvailable()) {
          throw Exception('API недоступен. Проверьте подключение к интернету или обратитесь к администратору.');
        }

      final token = await _getToken();
        if (token == null) {
          throw Exception('Требуется авторизация для повторного заказа.');
        }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/orders/$orderId/reorder/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('OrderService: Заказ $orderId успешно повторен');
        return true;
        } else if (response.statusCode == 400) {
          final errorBody = json.decode(response.body);
          final errorMessage = _extractErrorMessage(errorBody);
          throw Exception('Ошибка повторного заказа: $errorMessage');
        } else if (response.statusCode == 404) {
          throw Exception('Заказ не найден.');
        } else if (response.statusCode == 401) {
          throw Exception('Требуется авторизация. Войдите в систему.');
      } else {
          print('OrderService: HTTP ошибка ${response.statusCode} при повторном заказе $orderId');
          if (attempt < _maxRetries) {
            await Future.delayed(_retryDelay * attempt);
            continue;
          }
          throw Exception('Ошибка сервера при повторном заказе.');
        }
      } catch (e) {
        if (e is Exception) {
          rethrow;
        }
        print('OrderService: Ошибка повторного заказа $orderId, попытка $attempt: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
        final appEx = ErrorHandler.handle(e, context: 'reorder');
        ErrorReporter.reportNow(appEx);
        return false;
      }
    }
    return false;
  }

  // Улучшенный метод обновления статуса заказа
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (!await _isApiAvailable()) {
          throw Exception('API недоступен. Проверьте подключение к интернету или обратитесь к администратору.');
        }

        final token = await _getToken();
        if (token == null) {
          throw Exception('Требуется авторизация для обновления статуса заказа.');
        }

        // Валидация статуса
        final validStatuses = ['Новый', 'В обработке', 'Отправлен', 'Доставлен', 'Отменен'];
        if (!validStatuses.contains(newStatus)) {
          throw Exception('Недопустимый статус: $newStatus');
        }

        final response = await http.patch(
          Uri.parse('${AppConfig.apiBaseUrl}/orders/$orderId/'),
          headers: AppConfig.withNgrokBypass({
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          }),
          body: json.encode({
            'status': newStatus,
          }),
        );

        if (response.statusCode == 200) {
          print('OrderService: Статус заказа $orderId успешно обновлен на "$newStatus"');
          return true;
        } else if (response.statusCode == 400) {
          final errorBody = json.decode(response.body);
          final errorMessage = _extractErrorMessage(errorBody);
          throw Exception('Ошибка обновления статуса: $errorMessage');
        } else if (response.statusCode == 404) {
          throw Exception('Заказ не найден.');
        } else if (response.statusCode == 401) {
          throw Exception('Требуется авторизация. Войдите в систему.');
        } else if (response.statusCode == 403) {
          throw Exception('Недостаточно прав для изменения статуса заказа.');
        } else {
          print('OrderService: HTTP ошибка ${response.statusCode} при обновлении статуса заказа $orderId');
          if (attempt < _maxRetries) {
            await Future.delayed(_retryDelay * attempt);
            continue;
          }
          throw Exception('Ошибка сервера при обновлении статуса.');
      }
    } catch (e) {
        if (e is Exception) {
          rethrow;
        }
        print('OrderService: Ошибка обновления статуса заказа $orderId, попытка $attempt: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
        final appEx = ErrorHandler.handle(e, context: 'updateOrderStatus');
      ErrorReporter.reportNow(appEx);
        return false;
      }
    }
    return false;
  }

  // Метод получения методов доставки
  @override
  Future<List<Map<String, dynamic>>> getDeliveryMethods({int? addressId, double? subtotal}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('OrderService: Токен не найден, используем fallback методы доставки');
        return getFallbackDeliveryMethods();
      }

      final response = await CachedHttpClient.instance.get(
        Uri.parse('${AppConfig.apiBaseUrl}/orders/delivery-methods/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        // Убираем таймаут - ждем загрузки столько, сколько нужно
        enableCache: true,
        ttlSeconds: 3600, // 1 час кеш для методов доставки
        cacheAuthorizedRequests: true,
      );

      if (response.statusCode == 200) {
        try {
          final jsonBody = json.decode(response.body);
          if (jsonBody is List) {
            print('OrderService: Успешно загружено ${jsonBody.length} методов доставки из API');
            return List<Map<String, dynamic>>.from(jsonBody);
          } else if (jsonBody is Map<String, dynamic> && jsonBody['results'] is List) {
            // Если API возвращает в формате pagination
            final results = jsonBody['results'] as List;
            print('OrderService: Успешно загружено ${results.length} методов доставки из API (paginated)');
            return List<Map<String, dynamic>>.from(results);
          } else if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('count') && jsonBody.containsKey('results')) {
            // Обработка paginated response
            final results = jsonBody['results'] as List?;
            if (results != null) {
              print('OrderService: Успешно загружено ${results.length} методов доставки из API (paginated format)');
              return List<Map<String, dynamic>>.from(results);
            }
          }
        } catch (e) {
          print('OrderService: Ошибка парсинга методов доставки: $e');
        }
      }

      print('OrderService: Используем fallback методы доставки');
      return getFallbackDeliveryMethods();
    } catch (e) {
      print('OrderService: Ошибка получения методов доставки: $e');
      return getFallbackDeliveryMethods();
    }
  }

  // Метод получения методов оплаты
  @override
  Future<List<Map<String, dynamic>>> getPaymentMethods({int? addressId, double? subtotal}) async {
    try {
      print('OrderService: Начинаем загрузку методов оплаты');

      final response = await CachedHttpClient.instance.get(
        Uri.parse('${AppConfig.apiBaseUrl}/orders/payment-methods/'),
        headers: AppConfig.withNgrokBypass({
          'Accept': 'application/json',
          'User-Agent': 'PlantMana-Flutter-App/1.0',
        }),
        // Убираем таймаут - ждем загрузки столько, сколько нужно
        enableCache: true,
        ttlSeconds: 3600, // 1 час кеш для методов оплаты
        cacheAuthorizedRequests: false, // Не кешируем без авторизации
      );

      print('OrderService: Ответ от API: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonBody = json.decode(response.body);
          print('OrderService: Тело ответа: ${response.body}');

          if (jsonBody is List) {
            print('OrderService: Успешно загружено ${jsonBody.length} методов оплаты из API (list)');
            return List<Map<String, dynamic>>.from(jsonBody);
          } else if (jsonBody is Map<String, dynamic> && jsonBody['results'] is List) {
            // Если API возвращает в формате pagination
            final results = jsonBody['results'] as List;
            print('OrderService: Успешно загружено ${results.length} методов оплаты из API (paginated)');
            return List<Map<String, dynamic>>.from(results);
          } else if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('count') && jsonBody.containsKey('results')) {
            // Обработка paginated response
            final results = jsonBody['results'] as List?;
            if (results != null) {
              print('OrderService: Успешно загружено ${results.length} методов оплаты из API (paginated format)');
              return List<Map<String, dynamic>>.from(results);
            }
          }
        } catch (e) {
          print('OrderService: Ошибка парсинга методов оплаты: $e');
        }
      } else {
        print('OrderService: HTTP ошибка ${response.statusCode} для методов оплаты');
        print('OrderService: Тело ошибки: ${response.body}');
      }

      print('OrderService: Используем fallback методы оплаты');
      return getFallbackPaymentMethods();
    } catch (e) {
      print('OrderService: Ошибка получения методов оплаты: $e');
      return getFallbackPaymentMethods();
    }
  }

  @override
  List<Map<String, dynamic>> getFallbackDeliveryMethods() {
    return [
      {
        'id': 1,
        'name': 'Standard Delivery',
        'description': 'Delivery within 3-5 business days',
        'price': 5.99,
        'estimated_days': 3,
        'is_active': true
      },
      {
        'id': 2,
        'name': 'Express Delivery',
        'description': 'Delivery within 1-2 business days',
        'price': 15.99,
        'estimated_days': 1,
        'is_active': true
      }
    ];
  }

  @override
  List<Map<String, dynamic>> getFallbackPaymentMethods() {
    return [
      {
        'id': 1,
        'name': 'Credit Card',
        'description': 'Pay with credit or debit card',
        'is_online': true,
        'is_active': true
      },
      {
        'id': 2,
        'name': 'Cash on Delivery',
        'description': 'Pay when you receive your order',
        'is_online': false,
        'is_active': true
      }
    ];
  }
} 