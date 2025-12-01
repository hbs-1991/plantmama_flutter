part of 'orders_bloc.dart';

class OrdersState extends Equatable {
  final bool isLoading;
  final List<Order> orders;
  final String? error;
  final bool reorderSuccess;

  const OrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.error,
    this.reorderSuccess = false,
  });

  OrdersState copyWith({
    bool? isLoading,
    List<Order>? orders,
    String? error,
    bool? reorderSuccess,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      error: error,
      reorderSuccess: reorderSuccess ?? false,
    );
  }

  @override
  List<Object?> get props => [isLoading, orders, error, reorderSuccess];
}


