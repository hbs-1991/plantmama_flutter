part of 'orders_bloc.dart';

abstract class OrdersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class OrdersRequested extends OrdersEvent {}

class OrderCancelRequested extends OrdersEvent {
  final Order order;
  OrderCancelRequested(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderReorderRequested extends OrdersEvent {
  final Order order;
  OrderReorderRequested(this.order);

  @override
  List<Object?> get props => [order];
}


