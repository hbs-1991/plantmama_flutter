import 'dart:async';
import '../../models/product.dart';

abstract class ICartService {
  Future<void> addToCart(Product product, int quantity);
  Future<List<Map<String, dynamic>>> getCartItems();
  Future<void> removeFromCart(int productId);
  Future<void> updateCartItemQuantity(int productId, int quantity);

  Future<void> addToFavorites(Product product);
  Future<List<Map<String, dynamic>>> getFavoriteItems();
  Future<void> removeFromFavorites(int productId);
  Future<bool> isInFavorites(int productId);
  Future<int> getCartCount();
  Future<int> getFavoritesCount();
  void clearFavoritesCache();
  Future<void> clearCart();
}


