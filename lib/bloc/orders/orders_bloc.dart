import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/order.dart';
import '../../services/interfaces/i_order_service.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final IOrderService orderService;
  OrdersBloc({required this.orderService}) : super(const OrdersState()) {
    on<OrdersRequested>(_onOrdersRequested);
    on<OrderCancelRequested>(_onOrderCancelRequested);
    on<OrderReorderRequested>(_onOrderReorderRequested);
  }

  Future<void> _onOrdersRequested(OrdersRequested event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final orders = await orderService.getUserOrders();
      emit(state.copyWith(isLoading: false, orders: orders));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onOrderCancelRequested(OrderCancelRequested event, Emitter<OrdersState> emit) async {
    try {
      await orderService.cancelOrder(event.order.id);
      add(OrdersRequested());
    } catch (_) {}
  }

  Future<void> _onOrderReorderRequested(OrderReorderRequested event, Emitter<OrdersState> emit) async {
    try {
      await orderService.reorder(event.order.id);
    } catch (_) {}
  }
}


