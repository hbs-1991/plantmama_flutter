import 'dart:async';
import '../../models/product.dart';
import '../../models/cart_validation.dart';

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

  /// Validate cart items before checkout
  /// Checks item availability, stock levels, and current prices
  ///
  /// [items] - List of cart items with productId and quantity
  /// [deliveryMethod] - 'delivery' or 'pickup' (default: 'delivery')
  /// [regionCode] - Optional region code for region-specific pricing
  ///
  /// Returns CartValidationResult with validation details, or null on error
  Future<CartValidationResult?> validateCart({
    required List<Map<String, dynamic>> items,
    String deliveryMethod = 'delivery',
    String? regionCode,
  });

  /// Calculate delivery fee based on subtotal and location
  ///
  /// [subtotal] - Cart subtotal amount
  /// [regionCode] - Optional region code
  /// [postalCode] - Optional postal code for more accurate fee calculation
  ///
  /// Returns DeliveryFeeResult with fee details, or null on error
  Future<DeliveryFeeResult?> calculateDeliveryFee({
    required double subtotal,
    String? regionCode,
    String? postalCode,
  });
}


