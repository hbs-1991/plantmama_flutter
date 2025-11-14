import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/http_cache_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import './interfaces/i_cart_service.dart';
import '../config.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';
import '../utils/app_error.dart';
import '../utils/image_cache.dart' as image_cache;


class CartService implements ICartService {
  static final String _baseUrl = AppConfig.apiBaseUrl;
  
  // Кэш для результатов проверки избранного
  final Map<int, bool> _favoritesCache = {};

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Проверка доступности API
  Future<bool> _isApiAvailable() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/cart/');
      Map<String, String> baseHeaders = {
        'Accept': 'application/json',
      };
      http.Response response = await CachedHttpClient.instance.get(
        uri,
        headers: baseHeaders,
        // Убираем таймаут - ждем загрузки столько, сколько нужно
        enableCache: true,
        ttlSeconds: 30,
      );
      // Ответ HTML от ngrok считаем недоступностью API
      final looksHtml = _looksLikeHtml(response.body, response.headers);
      return (response.statusCode == 200 || response.statusCode == 401) && !looksHtml;
    } catch (e) {
      print('API корзины недоступен: $e');
      return false;
    }
  }

  // Безопасное преобразование цены
  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }

  // Добавить товар в корзину
  @override
  Future<void> addToCart(Product product, int quantity) async {
    final token = await _getToken();
    
    if (token == null) {
      // Пользователь не авторизован - сохраняем локально
      await _addToLocalCart(product, quantity);
      return;
    }

    // Проверяем доступность API
    if (!await _isApiAvailable()) {
      print('API недоступен, сохраняем локально');
      await _addToLocalCart(product, quantity);
      return; // Не выбрасываем исключение, просто сохраняем локально
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/cart/add_item/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode({
          'product_id': product.id,
          'quantity': quantity,
        }),
              );

      print('Add to cart response status: ${response.statusCode}');
      print('Add to cart response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Товар успешно добавлен в корзину');
        // Cache the product image
        if (product.mainImage.isNotEmpty) {
          print('CartService: Caching image for product ${product.id}: ${product.mainImage}');
          image_cache.ImageCache.downloadAndCacheImage(product.id, product.mainImage);
        } else {
          print('CartService: No image to cache for product ${product.id}');
        }
        return;
      } else {
        // При ошибке сервера сохраняем локально
        print('Ошибка сервера ${response.statusCode}, сохраняем локально');
        await _addToLocalCart(product, quantity);
        return; // Не выбрасываем исключение
      }
    } catch (e) {
      // При любой ошибке сохраняем локально
      print('Ошибка добавления в корзину: $e, сохраняем локально');
      await _addToLocalCart(product, quantity);
      return; // Не выбрасываем исключение
    }
  }

  // Получить товары из корзины
  @override
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final token = await _getToken();
    
    if (token == null) {
      return await _getLocalCartItems();
    }

    // Проверяем доступность API
    if (!await _isApiAvailable()) {
      print('API недоступен, используем локальную корзину');
      return await _getLocalCartItems();
    }

    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/cart/my_cart/');
      Map<String, String> baseHeaders = AppConfig.withNgrokBypass({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      http.Response response = await CachedHttpClient.instance.get(
        uri,
        headers: baseHeaders,
        // Убираем таймаут - ждем загрузки столько, сколько нужно
        enableCache: false,
        ttlSeconds: 0,
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          print('CartService: Получен HTML от ngrok, используем локальную корзину');
          return await _getLocalCartItems();
        }
        final jsonBody = json.decode(response.body);
        dynamic items;
        if (jsonBody is Map<String, dynamic>) {
          items = jsonBody['items'];
          if (items == null && jsonBody['cart'] is Map<String, dynamic>) {
            items = (jsonBody['cart'] as Map<String, dynamic>)['items'];
          }
          if (items == null && jsonBody['data'] is Map<String, dynamic>) {
            items = (jsonBody['data'] as Map<String, dynamic>)['items'];
          }
          if (items == null && jsonBody['results'] is List) {
            items = jsonBody['results'];
          }
        } else if (jsonBody is List) {
          items = jsonBody;
        }
        items ??= [];
         
         print('API корзины - количество товаров: ${items.length}');
         print('API корзины - данные: $items');
         
         // Преобразуем данные из API в нужный формат
         List<Map<String, dynamic>> cartItems = [];
         for (var item in items) {
           final product = item['product'] ?? {};
           
           // Безопасное преобразование цены
           final currentPrice = product['current_price'] ?? product['price'] ?? 0;
           final price = _parsePrice(currentPrice);
           
           // Безопасное преобразование общей цены
           final totalPrice = item['total_price'] ?? 0;
           final total = _parsePrice(totalPrice);
           
           final cartItem = {
             'id': product['id'] ?? 0,
             'productId': product['id'] ?? 0,
             'cartItemId': item['id'] ?? item['cart_item_id'] ?? item['item_id'] ?? 0,
             'name': product['name'] ?? '',
             'price': price,
             'image': product['main_image'] ?? '',
             'quantity': item['quantity'] ?? 1,
             'category': product['category_name'] ?? '',
             'sku': product['sku'] ?? '',
             'totalPrice': total,
             'addedAt': DateTime.now().toIso8601String(),
           };
           
           print('Обработанный товар корзины: $cartItem');
           cartItems.add(cartItem);
         }
         
         print('Итоговый список корзины: $cartItems');
         return cartItems;
      } else {
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'getCartItems');
        ErrorReporter.reportNow(appEx);
        return await _getLocalCartItems();
      }
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'getCartItems');
      ErrorReporter.reportNow(appEx);
      return await _getLocalCartItems();
    }
  }

  // Удалить товар из корзины
  @override
  Future<void> removeFromCart(int productId) async {
    final token = await _getToken();
    
    if (token == null) {
      await _removeFromLocalCart(productId);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/cart/remove_item/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode({
          'product_id': productId,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'removeFromCart');
        ErrorReporter.reportNow(appEx);
        throw appEx;
      }
    } catch (e) {
      await _removeFromLocalCart(productId);
      final appEx = ErrorHandler.handle(e, context: 'removeFromCart');
      ErrorReporter.reportNow(appEx);
      throw AppException(type: appEx.type, message: 'Товар удален локально: ${appEx.message}', cause: appEx);
    }
  }

  // Добавить в избранное
  @override
  Future<void> addToFavorites(Product product) async {
    final token = await _getToken();
    
    if (token == null) {
      await _addToLocalFavorites(product);
      // Очищаем кэш для этого товара
      _favoritesCache.remove(product.id);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/add_to_favorites/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode({
          'product_id': product.id,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        await _addToLocalFavorites(product);
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'addToFavorites');
        ErrorReporter.reportNow(appEx);
        throw AppException(type: appEx.type, message: 'Товар сохранен в избранном локально', cause: appEx);
      }
      
      // Очищаем кэш для этого товара
      _favoritesCache.remove(product.id);
    } catch (e) {
      await _addToLocalFavorites(product);
      // Очищаем кэш для этого товара
      _favoritesCache.remove(product.id);
      final appEx = ErrorHandler.handle(e, context: 'addToFavorites');
      ErrorReporter.reportNow(appEx);
      throw AppException(type: appEx.type, message: 'Товар сохранен в избранном локально: ${appEx.message}', cause: appEx);
    }
  }

  // Получить избранные товары
  @override
  Future<List<Map<String, dynamic>>> getFavoriteItems() async {
    final token = await _getToken();
    
    if (token == null) {
      return await _getLocalFavoriteItems();
    }

    try {
      // Получаем все товары из каталога
      final catalogResponse = await CachedHttpClient.instance.get(
        Uri.parse('$_baseUrl/products/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        enableCache: true,
        ttlSeconds: 300,
        cacheAuthorizedRequests: true,
      );

      print('Каталог API ответ: ${catalogResponse.statusCode}');
      
      if (catalogResponse.statusCode == 200) {
        final catalogJson = json.decode(catalogResponse.body);
        final allProducts = catalogJson['results'] ?? [];
        
        print('Получено товаров из каталога: ${allProducts.length}');
        
        // Фильтруем только избранные товары
        List<Map<String, dynamic>> favoriteItems = [];
        
        for (var product in allProducts) {
          final productId = product['id'];
          if (productId != null) {
            // Проверяем, есть ли этот товар в избранном
            final isFavorite = await isInFavorites(productId);
            print('Товар ${product['name']} (ID: $productId) в избранном: $isFavorite');
            
            if (isFavorite) {
              // Безопасное преобразование цены
              final currentPrice = product['current_price'] ?? product['price'] ?? 0;
              final price = _parsePrice(currentPrice);
              
              final favoriteItem = {
                'id': product['id'] ?? 0,
                'name': product['name'] ?? '',
                'price': price,
                'current_price': price,
                'image': product['main_image'] ?? '',
                'category': product['category_name'] ?? '',
                'section_name': product['section_name'] ?? '',
                'section_slug': product['section_slug'] ?? '',
                'short_description': product['short_description'] ?? '',
                'discount_price': product['discount_price'],
                'discount_percentage': product['discount_percentage'] ?? 0,
                'sku': product['sku'] ?? '',
                'addedAt': DateTime.now().toIso8601String(),
              };
              
              print('✅ Найден товар в избранном: ${favoriteItem['name']} (ID: ${favoriteItem['id']})');
              favoriteItems.add(favoriteItem);
            }
          }
        }
        
        print('Итоговый список избранного: ${favoriteItems.length} товаров');
        return favoriteItems;
      } else {
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: catalogResponse, context: 'getFavoriteItems');
        ErrorReporter.reportNow(appEx);
        return await _getLocalFavoriteItems();
      }
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'getFavoriteItems');
      ErrorReporter.reportNow(appEx);
      return await _getLocalFavoriteItems();
    }
  }

  // Удалить из избранного
  @override
  Future<void> removeFromFavorites(int productId) async {
    final token = await _getToken();
    
    if (token == null) {
      await _removeFromLocalFavorites(productId);
      // Очищаем кэш для этого товара
      _favoritesCache.remove(productId);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/remove_from_favorites/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode({
          'product_id': productId,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'removeFromFavorites');
        ErrorReporter.reportNow(appEx);
        throw appEx;
      }
      
      // Очищаем кэш для этого товара
      _favoritesCache.remove(productId);
    } catch (e) {
      await _removeFromLocalFavorites(productId);
      // Очищаем кэш для этого товара
      _favoritesCache.remove(productId);
      final appEx = ErrorHandler.handle(e, context: 'removeFromFavorites');
      ErrorReporter.reportNow(appEx);
      throw AppException(type: appEx.type, message: 'Товар удален из избранного локально: ${appEx.message}', cause: appEx);
    }
  }

  // === Локальные методы для неавторизованных пользователей ===

  Future<void> _addToLocalCart(Product product, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList('cart_items') ?? [];
    
    Map<String, dynamic> cartItem = {
      'id': product.id,
      'name': product.name,
      'price': product.currentPrice,
      'image': product.mainImage,
      'quantity': quantity,
      'category': product.categoryName,
      'sku': product.sku,
      'totalPrice': product.currentPrice * quantity,
      'addedAt': DateTime.now().toIso8601String(),
    };
    
    // Проверяем, есть ли уже такой товар
    bool itemExists = false;
    for (int i = 0; i < cartItems.length; i++) {
      Map<String, dynamic> existingItem = json.decode(cartItems[i]);
      if (existingItem['id'] == product.id) {
        existingItem['quantity'] = (existingItem['quantity'] ?? 1) + quantity;
        existingItem['totalPrice'] = existingItem['price'] * existingItem['quantity'];
        cartItems[i] = json.encode(existingItem);
        itemExists = true;
        break;
      }
    }
    
    if (!itemExists) {
      cartItems.add(json.encode(cartItem));
    }
    
    await prefs.setStringList('cart_items', cartItems);
    print('Товар добавлен в локальную корзину: ${product.name}, количество: $quantity');
    print('Локальная корзина после добавления: $cartItems');

    // Cache the product image
    if (product.mainImage.isNotEmpty) {
      print('CartService: Caching image for product ${product.id}: ${product.mainImage}');
      image_cache.ImageCache.downloadAndCacheImage(product.id, product.mainImage);
    } else {
      print('CartService: No image to cache for product ${product.id}');
    }
  }

  Future<List<Map<String, dynamic>>> _getLocalCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList('cart_items') ?? [];
    
    print('Локальная корзина - количество товаров: ${cartItems.length}');
    print('Локальная корзина - сырые данные: $cartItems');
    
    final decodedItems = cartItems.map((item) => json.decode(item) as Map<String, dynamic>).toList();
    print('Локальная корзина - декодированные данные: $decodedItems');
    
    return decodedItems;
  }

  Future<void> _removeFromLocalCart(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList('cart_items') ?? [];
    
    cartItems.removeWhere((item) {
      Map<String, dynamic> cartItem = json.decode(item);
      return cartItem['id'] == productId;
    });
    
    await prefs.setStringList('cart_items', cartItems);
  }

  Future<void> _addToLocalFavorites(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriteItems = prefs.getStringList('favorite_items') ?? [];
    
    Map<String, dynamic> favoriteItem = {
      'id': product.id,
      'name': product.name,
      'price': product.currentPrice,
      'image': product.mainImage,
      'category': product.categoryName,
      'sku': product.sku,
      'addedAt': DateTime.now().toIso8601String(),
    };
    
    // Проверяем, нет ли уже такого товара
    bool itemExists = favoriteItems.any((item) {
      Map<String, dynamic> existing = json.decode(item);
      return existing['id'] == product.id;
    });
    
    if (!itemExists) {
      favoriteItems.add(json.encode(favoriteItem));
      await prefs.setStringList('favorite_items', favoriteItems);
      print('Товар добавлен в локальное избранное: ${product.name}');
      print('Локальное избранное после добавления: $favoriteItems');
    } else {
      print('Товар уже есть в локальном избранном: ${product.name}');
    }
  }

  Future<List<Map<String, dynamic>>> _getLocalFavoriteItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriteItems = prefs.getStringList('favorite_items') ?? [];
    
    print('Локальное избранное - количество товаров: ${favoriteItems.length}');
    print('Локальное избранное - сырые данные: $favoriteItems');
    
    final decodedItems = favoriteItems.map((item) => json.decode(item) as Map<String, dynamic>).toList();
    print('Локальное избранное - декодированные данные: $decodedItems');
    
    return decodedItems;
  }

  Future<bool> _isInLocalFavorites(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriteItems = prefs.getStringList('favorite_items') ?? [];
    
    for (String item in favoriteItems) {
      try {
        Map<String, dynamic> favoriteItem = json.decode(item);
        if (favoriteItem['id'] == productId) {
          print('Товар $productId найден в локальном избранном');
          return true;
        }
      } catch (e) {
        print('Ошибка декодирования элемента избранного: $e');
      }
    }
    
    print('Товар $productId НЕ найден в локальном избранном');
    return false;
  }

  Future<void> _removeFromLocalFavorites(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriteItems = prefs.getStringList('favorite_items') ?? [];
    
    favoriteItems.removeWhere((item) {
      Map<String, dynamic> favoriteItem = json.decode(item);
      return favoriteItem['id'] == productId;
    });
    
    await prefs.setStringList('favorite_items', favoriteItems);
  }

  Future<void> _clearLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_items');
    await prefs.remove('cart_count');
  }

  Future<void> _updateLocalCartItemQuantity(int productId, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList('cart_items') ?? [];
    
    for (int i = 0; i < cartItems.length; i++) {
      Map<String, dynamic> cartItem = json.decode(cartItems[i]);
      if (cartItem['id'] == productId) {
        cartItem['quantity'] = quantity;
        cartItem['totalPrice'] = cartItem['price'] * quantity;
        cartItems[i] = json.encode(cartItem);
        break;
      }
    }
    
    await prefs.setStringList('cart_items', cartItems);
  }

  // Проверить, есть ли товар в избранном
  @override
  Future<bool> isInFavorites(int productId) async {
    // Проверяем кэш сначала
    if (_favoritesCache.containsKey(productId)) {
      print('Результат из кэша для товара $productId: ${_favoritesCache[productId]}');
      return _favoritesCache[productId]!;
    }
    
    final token = await _getToken();
    
    if (token == null) {
      print('Пользователь не авторизован, проверяем локальное избранное для товара $productId');
      final result = await _isInLocalFavorites(productId);
      _favoritesCache[productId] = result;
      return result;
    }

    try {
      print('Проверяем избранное через API для товара $productId');
      final uri = Uri.parse('$_baseUrl/users/is_favorite/?product_id=$productId');
      Map<String, String> baseHeaders = AppConfig.withNgrokBypass({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      http.Response response = await CachedHttpClient.instance.get(
        uri,
        headers: baseHeaders,
        enableCache: true,
        ttlSeconds: 60,
        cacheAuthorizedRequests: true,
      );

      print('API ответ для проверки избранного товара $productId: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          print('CartService: HTML при проверке избранного — fallback к локальным данным');
          final result = await _isInLocalFavorites(productId);
          _favoritesCache[productId] = result;
          return result;
        }
        final jsonBody = json.decode(response.body);
        final result = jsonBody['is_favorite'] ?? false;
        print('API результат для товара $productId: $result');
        // Сохраняем в кэш
        _favoritesCache[productId] = result;
        return result;
      } else {
        print('API вернул ошибку, используем локальную проверку для товара $productId');
        // Fallback к локальной проверке
        final result = await _isInLocalFavorites(productId);
        _favoritesCache[productId] = result;
        return result;
      }
    } catch (e) {
      print('Ошибка проверки избранного для товара $productId: $e');
      // Fallback к локальной проверке
      final result = await _isInLocalFavorites(productId);
      _favoritesCache[productId] = result;
      return result;
    }
  }

  // Получить количество товаров в корзине
  @override
  Future<int> getCartCount() async {
    final cartItems = await getCartItems();
    int totalCount = 0;
    for (var item in cartItems) {
      final quantity = item['quantity'];
      if (quantity != null) {
        totalCount += (quantity is int) ? quantity : int.tryParse(quantity.toString()) ?? 1;
      } else {
        totalCount += 1;
      }
    }
    return totalCount;
  }

  // Получить количество товаров в избранном
  @override
  Future<int> getFavoritesCount() async {
    final favoriteItems = await getFavoriteItems();
    return favoriteItems.length;
  }

  // Очистить кэш избранного
  @override
  void clearFavoritesCache() {
    _favoritesCache.clear();
    print('Кэш избранного очищен');
  }

  // Очистить корзину
  @override
  Future<void> clearCart() async {
    final token = await _getToken();
    
    if (token == null) {
      await _clearLocalCart();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/cart/clear/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'clearCart');
        ErrorReporter.reportNow(appEx);
        throw appEx;
      }
    } catch (e) {
      await _clearLocalCart();
      final appEx = ErrorHandler.handle(e, context: 'clearCart');
      ErrorReporter.reportNow(appEx);
      throw AppException(type: appEx.type, message: 'Корзина очищена локально: ${appEx.message}', cause: appEx);
    }
  }

  // Обновить количество товара в корзине
  @override
  Future<void> updateCartItemQuantity(int productId, int quantity) async {
    final token = await _getToken();
    
    if (token == null) {
      await _updateLocalCartItemQuantity(productId, quantity);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/cart/update_item/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode({
          'product_id': productId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'updateCartItemQuantity');
        ErrorReporter.reportNow(appEx);
        throw appEx;
      }
    } catch (e) {
      await _updateLocalCartItemQuantity(productId, quantity);
      final appEx = ErrorHandler.handle(e, context: 'updateCartItemQuantity');
      ErrorReporter.reportNow(appEx);
      throw AppException(type: appEx.type, message: 'Количество обновлено локально: ${appEx.message}', cause: appEx);
    }
  }

  bool _looksLikeHtml(String body, Map<String, String> headers) {
    final contentType = headers['content-type'] ?? '';
    return body.trim().startsWith('<!DOCTYPE') || 
           body.trim().startsWith('<html') ||
           contentType.contains('text/html');
  }
}