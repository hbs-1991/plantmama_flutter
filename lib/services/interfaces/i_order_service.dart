import 'dart:async';
import '../../models/order.dart';

abstract class IOrderService {
  Future<List<Order>> getUserOrders();
  Future<Order?> createOrder(CreateOrderRequest request);
  Future<Order?> getOrderDetails(int orderId);
  Future<bool> cancelOrder(int orderId);
  Future<bool> reorder(int orderId);
  Future<bool> updateOrderStatus(int orderId, String newStatus);
  Future<List<Map<String, dynamic>>> getDeliveryMethods({int? addressId, double? subtotal});
  Future<List<Map<String, dynamic>>> getPaymentMethods({int? addressId, double? subtotal});
  List<Map<String, dynamic>> getFallbackDeliveryMethods();
  List<Map<String, dynamic>> getFallbackPaymentMethods();
}


