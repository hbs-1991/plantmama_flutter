
import 'package:flutter/widgets.dart';
import '../services/interfaces/i_cart_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../di/locator.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final ICartService _cartService = locator.get<ICartService>();
  final IAuthService _authService = locator.get<IAuthService>();

  bool _isLoading = false;
  List<Map<String, dynamic>> _items = [];
  int _favoritesCount = 0;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  int get itemsCount => _items.length;
  int get favoritesCount => _favoritesCount;

  void _notifySafely() {
    // Переносим уведомление на следующий кадр, чтобы не триггерить во время build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> loadCart() async {
    // Проверяем авторизацию перед загрузкой
    if (!await _authService.isLoggedIn()) {
      print('CartProvider: Пользователь не авторизован, загружаем локальную корзину');
      _items = [];
      _isLoading = false;
      _notifySafely();
      return;
    }

    _isLoading = true;
    _notifySafely();
    try {
      _items = await _cartService.getCartItems();
      print('CartProvider: Загружено ${_items.length} товаров в корзину');
    } catch (e) {
      print('CartProvider: Ошибка загрузки корзины: $e');
      _items = [];
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> add(Product product, int quantity) async {
    try {
      await _cartService.addToCart(product, quantity);
      await loadCart();
    } catch (e) {
      print('CartProvider: Ошибка добавления в корзину: $e');
      // Даже при ошибке пытаемся загрузить корзину (возможно, товар сохранен локально)
      await loadCart();
    }
  }

  Future<void> remove(int productId) async {
    await _cartService.removeFromCart(productId);
    await loadCart();
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    await _cartService.updateCartItemQuantity(productId, quantity);
    await loadCart();
  }

  double get subtotal {
    double total = 0.0;
    for (final item in _items) {
      final totalPrice = item['totalPrice'];
      if (totalPrice != null) {
        total += (totalPrice is double) ? totalPrice : double.tryParse(totalPrice.toString()) ?? 0.0;
      }
    }
    return total;
  }

  Future<void> refreshFavoritesCount() async {
    _favoritesCount = await _cartService.getFavoritesCount();
    _notifySafely();
  }
}


