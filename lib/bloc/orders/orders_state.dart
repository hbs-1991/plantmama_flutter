part of 'orders_bloc.dart';

class OrdersState extends Equatable {
  final bool isLoading;
  final List<Order> orders;
  final String? error;

  const OrdersState({this.isLoading = false, this.orders = const [], this.error});

  OrdersState copyWith({bool? isLoading, List<Order>? orders, String? error}) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, orders, error];
}


