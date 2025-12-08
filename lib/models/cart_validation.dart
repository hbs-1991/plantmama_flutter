/// Cart validation models for pre-checkout validation
/// These models represent the response from POST /cart/validate endpoint

class CartValidationResult {
  final List<CartValidationItem> items;
  final double subtotal;
  final double estimatedDeliveryFee;
  final bool allItemsAvailable;

  CartValidationResult({
    required this.items,
    required this.subtotal,
    required this.estimatedDeliveryFee,
    required this.allItemsAvailable,
  });

  factory CartValidationResult.fromJson(Map<String, dynamic> json) {
    return CartValidationResult(
      items: (json['items'] as List? ?? [])
          .map((item) => CartValidationItem.fromJson(item))
          .toList(),
      subtotal: _parseDouble(json['subtotal']),
      estimatedDeliveryFee: _parseDouble(json['estimated_delivery_fee']),
      allItemsAvailable: json['all_items_available'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'estimated_delivery_fee': estimatedDeliveryFee,
      'all_items_available': allItemsAvailable,
    };
  }

  /// Get list of unavailable items for display purposes
  List<CartValidationItem> get unavailableItems =>
      items.where((item) => !item.available).toList();

  /// Get list of items with price changes
  List<CartValidationItem> get itemsWithPriceChanges =>
      items.where((item) => item.hasPriceChanged).toList();

  /// Check if cart can proceed to checkout
  bool get canProceedToCheckout => allItemsAvailable;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class CartValidationItem {
  final int productId;
  final bool available;
  final int quantityAvailable;
  final double currentPrice;
  final double? originalPrice;
  final String? unavailableReason;

  CartValidationItem({
    required this.productId,
    required this.available,
    required this.quantityAvailable,
    required this.currentPrice,
    this.originalPrice,
    this.unavailableReason,
  });

  factory CartValidationItem.fromJson(Map<String, dynamic> json) {
    return CartValidationItem(
      productId: json['product_id'] ?? 0,
      available: json['available'] ?? false,
      quantityAvailable: json['quantity_available'] ?? 0,
      currentPrice: CartValidationResult._parseDouble(json['current_price']),
      originalPrice: json['original_price'] != null
          ? CartValidationResult._parseDouble(json['original_price'])
          : null,
      unavailableReason: json['unavailable_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'available': available,
      'quantity_available': quantityAvailable,
      'current_price': currentPrice,
      if (originalPrice != null) 'original_price': originalPrice,
      if (unavailableReason != null) 'unavailable_reason': unavailableReason,
    };
  }

  /// Check if the price has changed from the original
  bool get hasPriceChanged =>
      originalPrice != null && originalPrice != currentPrice;

  /// Get the price difference if price changed
  double get priceDifference =>
      originalPrice != null ? currentPrice - originalPrice! : 0.0;
}

/// Result model for delivery fee calculation
/// Represents response from GET /cart/delivery-fee endpoint
class DeliveryFeeResult {
  final double deliveryFee;
  final double freeDeliveryThreshold;
  final bool isFreeDelivery;

  DeliveryFeeResult({
    required this.deliveryFee,
    required this.freeDeliveryThreshold,
    required this.isFreeDelivery,
  });

  factory DeliveryFeeResult.fromJson(Map<String, dynamic> json) {
    return DeliveryFeeResult(
      deliveryFee: CartValidationResult._parseDouble(json['delivery_fee']),
      freeDeliveryThreshold:
          CartValidationResult._parseDouble(json['free_delivery_threshold']),
      isFreeDelivery: json['is_free_delivery'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'delivery_fee': deliveryFee,
      'free_delivery_threshold': freeDeliveryThreshold,
      'is_free_delivery': isFreeDelivery,
    };
  }

  /// Calculate how much more is needed for free delivery
  double amountForFreeDelivery(double currentSubtotal) {
    if (isFreeDelivery || currentSubtotal >= freeDeliveryThreshold) {
      return 0.0;
    }
    return freeDeliveryThreshold - currentSubtotal;
  }
}
