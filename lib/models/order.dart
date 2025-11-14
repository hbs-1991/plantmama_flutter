import 'package:flutter/material.dart';
import '../models/address.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }
  return 0.0;
}

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final double subtotal;
  final double deliveryFee;
  final String deliveryMethod;
  final String paymentMethod;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String? notes;
  final Address? deliveryAddress;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.subtotal,
    required this.deliveryFee,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.notes,
    this.deliveryAddress,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      return Order(
        id: json['id'] ?? 0,
        orderNumber: json['order_number']?.toString() ?? json['id']?.toString() ?? 'N/A',
        status: json['status'] is Map 
            ? json['status']['name'] ?? 'pending'
            : json['status']?.toString() ?? 'pending',
        totalAmount: _parseDouble(json['total_amount'] ?? json['total'] ?? 0),
        subtotal: _parseDouble(json['subtotal'] ?? 0),
        deliveryFee: _parseDouble(json['delivery_fee'] ?? json['delivery_cost'] ?? 0),
        deliveryMethod: json['delivery_method'] is Map 
            ? json['delivery_method']['name'] ?? 'delivery'
            : json['delivery_method']?.toString() ?? 'delivery',
        paymentMethod: json['payment_method'] is Map 
            ? json['payment_method']['name'] ?? 'cash'
            : json['payment_method']?.toString() ?? 'cash',
        customerName: json['customer_name'] ?? json['recipient_name'] ?? 'Клиент',
        customerPhone: json['customer_phone'] ?? json['recipient_phone'] ?? '',
        customerEmail: json['customer_email'] ?? '',
        notes: json['notes'] ?? json['comment'],
        deliveryAddress: json['delivery_address'] != null 
            ? Address.fromJson(json['delivery_address']) 
            : null,
        items: json['items'] != null 
            ? List<OrderItem>.from(json['items'].map((item) => OrderItem.fromJson(item)))
            : [],
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      // Возвращаем базовый заказ в случае ошибки
      return Order(
        id: json['id'] ?? 0,
        orderNumber: json['order_number']?.toString() ?? json['id']?.toString() ?? 'N/A',
        status: 'pending',
        totalAmount: 0.0,
        subtotal: 0.0,
        deliveryFee: 0.0,
        deliveryMethod: 'delivery',
        paymentMethod: 'cash',
        customerName: 'Клиент',
        customerPhone: '',
        customerEmail: '',
        items: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'status': status,
      'total_amount': totalAmount,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'delivery_method': deliveryMethod,
      'payment_method': paymentMethod,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'notes': notes,
      'delivery_address': deliveryAddress?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'новый':
        return 'Ожидает подтверждения';
      case 'confirmed':
      case 'подтвержден':
        return 'Подтвержден';
      case 'processing':
      case 'в обработке':
        return 'В обработке';
      case 'shipped':
      case 'отправлен':
        return 'Отправлен';
      case 'delivered':
      case 'доставлен':
        return 'Доставлен';
      case 'cancelled':
      case 'отменен':
        return 'Отменен';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'новый':
        return Colors.orange;
      case 'confirmed':
      case 'подтвержден':
        return Colors.blue;
      case 'processing':
      case 'в обработке':
        return Colors.purple;
      case 'shipped':
      case 'отправлен':
        return Colors.indigo;
      case 'delivered':
      case 'доставлен':
        return Colors.green;
      case 'cancelled':
      case 'отменен':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'новый':
        return Icons.schedule;
      case 'confirmed':
      case 'подтвержден':
        return Icons.check_circle;
      case 'processing':
      case 'в обработке':
        return Icons.build;
      case 'shipped':
      case 'отправлен':
        return Icons.local_shipping;
      case 'delivered':
      case 'доставлен':
        return Icons.done_all;
      case 'cancelled':
      case 'отменен':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String get formattedDate {
    return "${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}";
  }
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    try {
      // Обрабатываем случай, когда product передается как объект
      final product = json['product'];
      final productId = product is Map ? product['id'] : (json['product_id'] ?? json['id']); // Fallback to item id if no product_id
      final productName = product is Map ? product['name'] : json['product_name'];
      final productImage = product is Map && product['image'] != null
          ? product['image']
          : json['product_image'] ?? '';

      print('OrderItem.fromJson: Создаем товар "$productName" (ID: $productId) с картинкой: "$productImage"');

      return OrderItem(
        id: json['id'] ?? 0,
        productId: productId ?? 0,
        productName: productName ?? 'Товар',
        productImage: productImage,
        price: _parseDouble(json['price'] ?? json['product_price'] ?? 0),
        quantity: json['quantity'] ?? 1,
        totalPrice: _parseDouble(json['total_price'] ?? 0),
      );
    } catch (e) {
      print('OrderItem.fromJson: Ошибка парсинга: $e');
      // Возвращаем базовый товар в случае ошибки
      return OrderItem(
        id: json['id'] ?? 0,
        productId: json['product_id'] ?? json['id'] ?? 0,
        productName: 'Товар',
        productImage: json['product_image'] ?? '',
        price: 0.0,
        quantity: 1,
        totalPrice: 0.0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'price': price,
      'quantity': quantity,
      'total_price': totalPrice,
    };
  }
}

class CreateOrderRequest {
  final List<Map<String, dynamic>> items;
  final dynamic deliveryMethod; // Может быть int или String
  final dynamic paymentMethod; // Может быть int или String
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String? notes;
  final int? deliveryAddressId;
  final DateTime? deliveryDate;
  final String? recipientAddress; // Полный адрес для API

  CreateOrderRequest({
    required this.items,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.notes,
    this.deliveryAddressId,
    this.deliveryDate,
    this.recipientAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items,
      'delivery_method': deliveryMethod,
      'payment_method': paymentMethod,
      'recipient_name': customerName,
      'recipient_phone': customerPhone,
      'customer_email': customerEmail,
      if (notes != null) 'comment': notes,
      if (deliveryAddressId != null) 'delivery_address_id': deliveryAddressId,
      if (deliveryDate != null) 'delivery_date': deliveryDate!.toIso8601String().split('T')[0],
      if (recipientAddress != null) 'recipient_address': recipientAddress,
    };
  }
} 