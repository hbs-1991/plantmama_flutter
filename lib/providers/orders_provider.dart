import 'package:flutter/foundation.dart' show ChangeNotifier;
import '../services/interfaces/i_order_service.dart';
import '../di/locator.dart';
import '../models/order.dart';

enum OrdersState {
  initial,
  loading,
  loaded,
  error,
  empty,
}

class OrdersProvider extends ChangeNotifier {
  final IOrderService _orderService = locator.get<IOrderService>();

  OrdersState _state = OrdersState.initial;
  List<Order> _orders = [];
  List<Map<String, dynamic>> _deliveryMethods = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _isLoadingMethods = false;

  // Getters
  OrdersState get state => _state;
  bool get isLoading => _state == OrdersState.loading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMethods => _isLoadingMethods;
  List<Order> get orders => List.unmodifiable(_orders);
  List<Map<String, dynamic>> get deliveryMethods => List.unmodifiable(_deliveryMethods);
  List<Map<String, dynamic>> get paymentMethods => List.unmodifiable(_paymentMethods);
  String? get errorMessage => _errorMessage;
  bool get hasError => _state == OrdersState.error;
  bool get isEmpty => _state == OrdersState.empty;

  // Загрузка заказов с обработкой ошибок
  Future<void> loadOrders({bool showLoading = true}) async {
    if (showLoading) {
      _setState(OrdersState.loading);
    }
    
    try {
      _errorMessage = null;
      final orders = await _orderService.getUserOrders();
      
      if (orders.isEmpty) {
        _setState(OrdersState.empty);
      } else {
        _orders = orders;
        print('OrdersProvider: Загружено ${orders.length} заказов');
        for (int i = 0; i < orders.length; i++) {
          final order = orders[i];
          print('OrdersProvider: Заказ #${order.orderNumber}: ${order.items.length} товаров');
          for (int j = 0; j < order.items.length; j++) {
            final item = order.items[j];
            print('OrdersProvider: Товар ${j + 1}: "${item.productName}", картинка: "${item.productImage}"');
          }
        }
        _setState(OrdersState.loaded);
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _setState(OrdersState.error);
      print('OrdersProvider: Ошибка загрузки заказов: $e');
    }
  }

  // Обновление заказов (pull-to-refresh)
  Future<void> refreshOrders() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    notifyListeners();
    
    try {
      _errorMessage = null;
      final orders = await _orderService.getUserOrders();
      
      if (orders.isEmpty) {
        _setState(OrdersState.empty);
      } else {
        _orders = orders;
        _setState(OrdersState.loaded);
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _setState(OrdersState.error);
      print('OrdersProvider: Ошибка обновления заказов: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Отмена заказа с обработкой ошибок
  Future<bool> cancelOrder(int orderId) async {
    try {
      _errorMessage = null;
      final success = await _orderService.cancelOrder(orderId);
      
      if (success) {
        // Обновляем локальный список заказов
        await loadOrders(showLoading: false);
        return true;
      } else {
        _errorMessage = 'Не удалось отменить заказ';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      print('OrdersProvider: Ошибка отмены заказа: $e');
      return false;
    }
  }

  // Повторный заказ с обработкой ошибок
  Future<bool> reorder(int orderId) async {
    try {
      _errorMessage = null;
      final success = await _orderService.reorder(orderId);
      
      if (success) {
        return true;
      } else {
        _errorMessage = 'Не удалось повторить заказ';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      print('OrdersProvider: Ошибка повторного заказа: $e');
      return false;
    }
  }

  // Обновление статуса заказа
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      _errorMessage = null;
      final success = await _orderService.updateOrderStatus(orderId, newStatus);
      
      if (success) {
        // Обновляем локальный список заказов
        await loadOrders(showLoading: false);
        return true;
      } else {
        _errorMessage = 'Не удалось обновить статус заказа';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      print('OrdersProvider: Ошибка обновления статуса заказа: $e');
      return false;
    }
  }

  // Загрузка методов доставки и оплаты
  Future<void> loadMethods() async {
    if (_isLoadingMethods) return;
    
    _isLoadingMethods = true;
    notifyListeners();
    
    try {
      _errorMessage = null;
      
      // Загружаем методы параллельно
      final results = await Future.wait([
        _orderService.getDeliveryMethods(),
        _orderService.getPaymentMethods(),
      ]);
      
      _deliveryMethods = results[0];
      _paymentMethods = results[1];
      
      print('OrdersProvider: Загружено ${_deliveryMethods.length} методов доставки и ${_paymentMethods.length} методов оплаты');
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      print('OrdersProvider: Ошибка загрузки методов: $e');
    } finally {
      _isLoadingMethods = false;
      notifyListeners();
    }
  }

  // Очистка ошибки
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Retry загрузки при ошибке
  Future<void> retry() async {
    if (_state == OrdersState.error) {
      await loadOrders();
    }
  }

  // Получение заказа по ID
  Order? getOrderById(int orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // Фильтрация заказов по статусу
  List<Order> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status.toLowerCase() == status.toLowerCase()).toList();
  }

  // Поиск заказов
  List<Order> searchOrders(String query) {
    if (query.isEmpty) return _orders;
    
    final lowercaseQuery = query.toLowerCase();
    return _orders.where((order) {
      return order.orderNumber.toLowerCase().contains(lowercaseQuery) ||
             order.customerName.toLowerCase().contains(lowercaseQuery) ||
             order.items.any((item) => item.productName.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Сортировка заказов
  void sortOrders({bool byDate = true, bool ascending = false}) {
    if (byDate) {
      if (ascending) {
        _orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else {
        _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } else {
      if (ascending) {
        _orders.sort((a, b) => a.orderNumber.compareTo(b.orderNumber));
      } else {
        _orders.sort((a, b) => b.orderNumber.compareTo(a.orderNumber));
      }
    }
    notifyListeners();
  }

  // Установка состояния
  void _setState(OrdersState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  // Получение сообщения об ошибке
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    if (error is String) {
      return error;
    }
    return 'Произошла неизвестная ошибка';
  }

  // Сброс состояния
  void reset() {
    _state = OrdersState.initial;
    _orders = [];
    _deliveryMethods = [];
    _paymentMethods = [];
    _errorMessage = null;
    _isRefreshing = false;
    _isLoadingMethods = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}


