
import 'package:flutter/widgets.dart';
import '../services/interfaces/i_cart_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../di/locator.dart';
import '../models/product.dart';

class FavoritesProvider extends ChangeNotifier {
  final ICartService _cartService = locator.get<ICartService>();
  final IAuthService _authService = locator.get<IAuthService>();

  bool _isLoading = false;
  final Set<int> _favoriteIds = {};
  List<Product> _favoriteProducts = [];

  bool get isLoading => _isLoading;
  int get count => _favoriteIds.length;
  Set<int> get ids => _favoriteIds;
  List<Product> get products => List.unmodifiable(_favoriteProducts);

  void _notifySafely() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  Future<void> loadFavorites() async {
    // Проверяем авторизацию перед загрузкой
    if (!await _authService.isLoggedIn()) {
      print('FavoritesProvider: Пользователь не авторизован, загружаем локальные избранные');
      _favoriteIds.clear();
      _favoriteProducts.clear();
      _isLoading = false;
      _notifySafely();
      return;
    }

    _isLoading = true;
    _notifySafely();
    try {
      final items = await _cartService.getFavoriteItems();
      _favoriteIds
        ..clear()
        ..addAll(items.map((e) => (e['id'] ?? 0) as int));
      _favoriteProducts = _mapFavoriteItemsToProducts(items);
      print('FavoritesProvider: Загружено ${_favoriteProducts.length} избранных товаров');
    } catch (e) {
      print('FavoritesProvider: Ошибка загрузки избранного: $e');
      _favoriteIds.clear();
      _favoriteProducts.clear();
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  bool isFavoriteSync(int productId) => _favoriteIds.contains(productId);

  Future<void> toggle(Product product) async {
    final isFav = _favoriteIds.contains(product.id);
    if (isFav) {
      await _cartService.removeFromFavorites(product.id);
      _favoriteIds.remove(product.id);
      _favoriteProducts.removeWhere((p) => p.id == product.id);
    } else {
      await _cartService.addToFavorites(product);
      _favoriteIds.add(product.id);
      _favoriteProducts.add(product);
    }
    _notifySafely();
  }

  List<Product> _mapFavoriteItemsToProducts(List<Map<String, dynamic>> items) {
    double parsePrice(dynamic price) {
      if (price == null) return 0.0;
      if (price is double) return price;
      if (price is int) return price.toDouble();
      return double.tryParse(price.toString()) ?? 0.0;
    }

    final List<Product> products = [];
    for (final item in items) {
      final price = parsePrice(item['current_price'] ?? item['price']);
      products.add(
        Product(
          id: item['id'] ?? 0,
          name: item['name'] ?? '',
          slug: item['slug'] ?? '',
          sku: item['sku'] ?? '',
          categoryId: item['category_id'] ?? 0,
          categoryName: item['category'] ?? '',
          sectionName: item['section_name'] ?? '',
          sectionSlug: item['section_slug'] ?? '',
          shortDescription: item['short_description'] ?? '',
          price: price,
          discountPrice: item['discount_price'] != null ? parsePrice(item['discount_price']) : null,
          currentPrice: price,
          discountPercentage: item['discount_percentage'] ?? 0,
          isFeatured: item['is_featured'] ?? false,
          mainImage: item['image'] ?? '',
          stock: item['stock'] ?? 0,
          rating: 0.0,
          reviewCount: 0,
        ),
      );
    }
    return products;
  }
}


