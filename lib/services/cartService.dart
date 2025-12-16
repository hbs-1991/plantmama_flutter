import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/http_cache_client.dart';
import '../utils/secure_storage.dart';
import '../models/product.dart';
import '../models/cart_validation.dart';
import './interfaces/i_cart_service.dart';
import '../config.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';
import '../utils/app_error.dart';
import '../utils/image_cache.dart' as image_cache;


class CartService implements ICartService {
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // Cache for favorites check results
  final Map<int, bool> _favoritesCache = {};

  /// Get authentication token from secure storage
  Future<String?> _getToken() async {
    return await SecureStorage.instance.getToken();
  }

  /// Check if API is available
  Future<bool> _isApiAvailable() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/cart/');
      Map<String, String> baseHeaders = {
        'Accept': 'application/json',
      };
      http.Response response = await CachedHttpClient.instance.get(
        uri,
        headers: baseHeaders,
        enableCache: true,
        ttlSeconds: 30,
      );
      // HTML response from ngrok means API is unavailable
      final looksHtml = _looksLikeHtml(response.body, response.headers);
      return (response.statusCode == 200 || response.statusCode == 401) && !looksHtml;
    } catch (e) {
      if (kDebugMode) print('Cart API unavailable: $e');
      return false;
    }
  }

  /// Safely parse price from various formats (String, int, double)
  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }

  /// Add product to cart
  @override
  Future<void> addToCart(Product product, int quantity) async {
    final token = await _getToken();

    if (token == null) {
      // User not authenticated - save locally
      await _addToLocalCart(product, quantity);
      return;
    }

    // Check API availability
    if (!await _isApiAvailable()) {
      if (kDebugMode) print('API unavailable, saving locally');
      await _addToLocalCart(product, quantity);
      return;
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

      if (kDebugMode) {
        print('Add to cart response: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Cache the product image
        if (product.mainImage.isNotEmpty) {
          image_cache.ImageCache.downloadAndCacheImage(product.id, product.mainImage);
        }
        return;
      } else {
        // On server error, save locally
        if (kDebugMode) print('Server error ${response.statusCode}, saving locally');
        await _addToLocalCart(product, quantity);
        return;
      }
    } catch (e) {
      // On any error, save locally
      if (kDebugMode) print('Error adding to cart: $e, saving locally');
      await _addToLocalCart(product, quantity);
      return;
    }
  }

  /// Get cart items from API or local storage
  /// FastAPI response format: {success: bool, data: {items: [...]}}
  @override
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final token = await _getToken();

    if (token == null) {
      return await _getLocalCartItems();
    }

    // Check API availability
    if (!await _isApiAvailable()) {
      if (kDebugMode) print('API unavailable, using local cart');
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
        enableCache: false,
        ttlSeconds: 0,
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          if (kDebugMode) print('CartService: HTML response, using local cart');
          return await _getLocalCartItems();
        }
        final jsonBody = json.decode(response.body);
        dynamic items;

        // FastAPI response format: {success: bool, data: {items: [...]}}
        if (jsonBody is Map<String, dynamic>) {
          // Primary: FastAPI format with data wrapper
          if (jsonBody['data'] is Map<String, dynamic>) {
            items = (jsonBody['data'] as Map<String, dynamic>)['items'];
          }
          // Alternative: Direct items array
          items ??= jsonBody['items'];
          // Alternative: Cart wrapper
          if (items == null && jsonBody['cart'] is Map<String, dynamic>) {
            items = (jsonBody['cart'] as Map<String, dynamic>)['items'];
          }
          // Alternative: Direct data array (for list endpoints)
          if (items == null && jsonBody['data'] is List) {
            items = jsonBody['data'];
          }
        } else if (jsonBody is List) {
          items = jsonBody;
        }
        items ??= [];

        if (kDebugMode) print('Cart API - items count: ${items.length}');

        // Transform API data to internal format
        List<Map<String, dynamic>> cartItems = [];
        for (var item in items) {
          final product = item['product'] ?? {};

          // Safe price parsing
          final currentPrice = product['current_price'] ?? product['price'] ?? 0;
          final price = _parsePrice(currentPrice);

          // Safe total price parsing
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

          cartItems.add(cartItem);
        }

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

  /// Remove product from cart
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
      throw AppException(type: appEx.type, message: 'Item removed locally: ${appEx.message}', cause: appEx);
    }
  }

  /// Add product to favorites
  @override
  Future<void> addToFavorites(Product product) async {
    final token = await _getToken();

    if (token == null) {
      await _addToLocalFavorites(product);
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
        throw AppException(type: appEx.type, message: 'Item saved to favorites locally', cause: appEx);
      }

      _favoritesCache.remove(product.id);
    } catch (e) {
      await _addToLocalFavorites(product);
      _favoritesCache.remove(product.id);
      final appEx = ErrorHandler.handle(e, context: 'addToFavorites');
      ErrorReporter.reportNow(appEx);
      throw AppException(type: appEx.type, message: 'Item saved to favorites locally: ${appEx.message}', cause: appEx);
    }
  }

  /// Get favorite items
  /// FastAPI response format: {success: bool, data: [...], meta: {...}}
  @override
  Future<List<Map<String, dynamic>>> getFavoriteItems() async {
    final token = await _getToken();

    if (token == null) {
      return await _getLocalFavoriteItems();
    }

    try {
      // Get all products from catalog
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

      if (kDebugMode) print('Catalog API response: ${catalogResponse.statusCode}');

      if (catalogResponse.statusCode == 200) {
        final catalogJson = json.decode(catalogResponse.body);
        // FastAPI format: {success, data, meta} - use 'data' instead of 'results'
        final allProducts = catalogJson['data'] ?? catalogJson['results'] ?? [];

        if (kDebugMode) print('Products from catalog: ${allProducts.length}');

        // Filter only favorite items
        List<Map<String, dynamic>> favoriteItems = [];

        for (var product in allProducts) {
          final productId = product['id'];
          if (productId != null) {
            final isFavorite = await isInFavorites(productId);

            if (isFavorite) {
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

              favoriteItems.add(favoriteItem);
            }
          }
        }

        if (kDebugMode) print('Favorites count: ${favoriteItems.length}');
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

  /// Remove product from favorites
  @override
  Future<void> removeFromFavorites(int productId) async {
    final token = await _getToken();

    if (token == null) {
      await _removeFromLocalFavorites(productId);
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

      _favoritesCache.remove(productId);
    } catch (e) {
      await _removeFromLocalFavorites(productId);
      _favoritesCache.remove(productId);
      final appEx = ErrorHandler.handle(e, context: 'removeFromFavorites');
      ErrorReporter.reportNow(appEx);
      throw AppException(type: appEx.type, message: 'Товар удален из избранного локально: ${appEx.message}', cause: appEx);
    }
  }

  // === Local methods for unauthenticated users ===

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

    // Check if item already exists
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
    if (kDebugMode) print('Added to local cart: ${product.name}, qty: $quantity');

    // Cache the product image
    if (product.mainImage.isNotEmpty) {
      image_cache.ImageCache.downloadAndCacheImage(product.id, product.mainImage);
    }
  }

  Future<List<Map<String, dynamic>>> _getLocalCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartItems = prefs.getStringList('cart_items') ?? [];

    if (kDebugMode) print('Local cart items: ${cartItems.length}');

    return cartItems.map((item) => json.decode(item) as Map<String, dynamic>).toList();
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

    // Check if item already exists
    bool itemExists = favoriteItems.any((item) {
      Map<String, dynamic> existing = json.decode(item);
      return existing['id'] == product.id;
    });

    if (!itemExists) {
      favoriteItems.add(json.encode(favoriteItem));
      await prefs.setStringList('favorite_items', favoriteItems);
      if (kDebugMode) print('Added to local favorites: ${product.name}');
    }
  }

  Future<List<Map<String, dynamic>>> _getLocalFavoriteItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriteItems = prefs.getStringList('favorite_items') ?? [];

    if (kDebugMode) print('Local favorites: ${favoriteItems.length}');

    return favoriteItems.map((item) => json.decode(item) as Map<String, dynamic>).toList();
  }

  Future<bool> _isInLocalFavorites(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriteItems = prefs.getStringList('favorite_items') ?? [];

    for (String item in favoriteItems) {
      try {
        Map<String, dynamic> favoriteItem = json.decode(item);
        if (favoriteItem['id'] == productId) {
          return true;
        }
      } catch (e) {
        if (kDebugMode) print('Error decoding favorite item: $e');
      }
    }

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

  /// Check if product is in favorites
  @override
  Future<bool> isInFavorites(int productId) async {
    // Check cache first
    if (_favoritesCache.containsKey(productId)) {
      return _favoritesCache[productId]!;
    }

    final token = await _getToken();

    if (token == null) {
      final result = await _isInLocalFavorites(productId);
      _favoritesCache[productId] = result;
      return result;
    }

    try {
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

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          if (kDebugMode) print('CartService: HTML in favorites check - fallback to local');
          final result = await _isInLocalFavorites(productId);
          _favoritesCache[productId] = result;
          return result;
        }
        final jsonBody = json.decode(response.body);
        // FastAPI format: {success, data: {is_favorite}} or direct {is_favorite}
        final data = jsonBody['data'] ?? jsonBody;
        final result = data['is_favorite'] ?? false;
        _favoritesCache[productId] = result;
        return result;
      } else {
        // Fallback to local check
        final result = await _isInLocalFavorites(productId);
        _favoritesCache[productId] = result;
        return result;
      }
    } catch (e) {
      if (kDebugMode) print('Error checking favorites for product $productId: $e');
      // Fallback to local check
      final result = await _isInLocalFavorites(productId);
      _favoritesCache[productId] = result;
      return result;
    }
  }

  /// Get total cart item count
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

  /// Get favorites count
  @override
  Future<int> getFavoritesCount() async {
    final favoriteItems = await getFavoriteItems();
    return favoriteItems.length;
  }

  /// Clear favorites cache
  @override
  void clearFavoritesCache() {
    _favoritesCache.clear();
    if (kDebugMode) print('Favorites cache cleared');
  }

  /// Clear cart
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
      throw AppException(type: appEx.type, message: 'Cart cleared locally: ${appEx.message}', cause: appEx);
    }
  }

  /// Update cart item quantity
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
      throw AppException(type: appEx.type, message: 'Quantity updated locally: ${appEx.message}', cause: appEx);
    }
  }

  bool _looksLikeHtml(String body, Map<String, String> headers) {
    final contentType = headers['content-type'] ?? '';
    return body.trim().startsWith('<!DOCTYPE') ||
           body.trim().startsWith('<html') ||
           contentType.contains('text/html');
  }

  // ============ Cart Validation Methods ============

  /// Validate cart items before checkout
  /// FastAPI response format: {success: bool, data: CartValidation}
  @override
  Future<CartValidationResult?> validateCart({
    required List<Map<String, dynamic>> items,
    String deliveryMethod = 'delivery',
    String? regionCode,
  }) async {
    final token = await _getToken();
    if (token == null) {
      if (kDebugMode) print('CartService: No token for cart validation');
      return null;
    }

    try {
      final headers = AppConfig.withNgrokBypass({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (regionCode != null) {
        headers['X-Region-Code'] = regionCode;
      }

      // Normalize item format for API
      final normalizedItems = items.map((item) => {
        'product_id': item['productId'] ?? item['product_id'] ?? item['id'],
        'quantity': item['quantity'] ?? 1,
      }).toList();

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/cart/validate/'),
        headers: headers,
        body: json.encode({
          'items': normalizedItems,
          'delivery_method': deliveryMethod,
          if (regionCode != null) 'region_code': regionCode,
        }),
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) print('Cart validation response: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          if (kDebugMode) print('CartService: HTML response from cart validation');
          return null;
        }

        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'] ?? jsonBody;
        return CartValidationResult.fromJson(data);
      }

      final appEx = ErrorHandler.handle(
        'HTTP_ERROR',
        response: response,
        context: 'validateCart',
      );
      ErrorReporter.reportNow(appEx);
      return null;
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'validateCart');
      ErrorReporter.reportNow(appEx);
      return null;
    }
  }

  /// Calculate delivery fee based on subtotal and location
  /// FastAPI response format: {success: bool, data: DeliveryFeeResult}
  @override
  Future<DeliveryFeeResult?> calculateDeliveryFee({
    required double subtotal,
    String? regionCode,
    String? postalCode,
  }) async {
    final token = await _getToken();
    if (token == null) {
      if (kDebugMode) print('CartService: No token for delivery fee calculation');
      return null;
    }

    try {
      final queryParams = <String, String>{
        'subtotal': subtotal.toString(),
      };

      if (regionCode != null) queryParams['region_code'] = regionCode;
      if (postalCode != null) queryParams['postal_code'] = postalCode;

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/cart/delivery-fee/')
          .replace(queryParameters: queryParams);

      final headers = AppConfig.withNgrokBypass({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        enableCache: true,
        ttlSeconds: 300, // Cache for 5 minutes
        cacheAuthorizedRequests: true,
      );

      if (kDebugMode) print('Delivery fee response: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          if (kDebugMode) print('CartService: HTML response from delivery fee endpoint');
          return null;
        }

        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'] ?? jsonBody;
        return DeliveryFeeResult.fromJson(data);
      }

      final appEx = ErrorHandler.handle(
        'HTTP_ERROR',
        response: response,
        context: 'calculateDeliveryFee',
      );
      ErrorReporter.reportNow(appEx);
      return null;
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'calculateDeliveryFee');
      ErrorReporter.reportNow(appEx);
      return null;
    }
  }
}