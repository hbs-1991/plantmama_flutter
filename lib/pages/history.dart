import 'package:flutter/material.dart';
import '../models/order.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import 'api_debug.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<OrdersProvider>().loadOrders();
      setState(() { _debugInfo = 'Загружено через OrdersProvider\n'; });
    });
  }

  Future<void> _loadOrders() async {
    await context.read<OrdersProvider>().loadOrders();
    setState(() { _debugInfo += 'Перезагрузка заказов через провайдер\n'; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('История заказов', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApiDebugPage(),
                ),
              );
            },
            tooltip: 'Диагностика API',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'DEBUG - HISTORY PAGE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
             ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Обновить заказы'),
            ),
            const SizedBox(height: 20),
             Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<OrdersProvider>(
                        builder: (context, p, _) => Text(
                          'Статус загрузки: ${p.isLoading ? "Загружается" : "Загружено"}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Consumer<OrdersProvider>(
                        builder: (context, p, _) => Text(
                          'Количество заказов: ${p.orders.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Отладочная информация:',
                        style: const TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _debugInfo,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Consumer<OrdersProvider>(builder: (context, p, _) => p.orders.isNotEmpty ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'СПИСОК ЗАКАЗОВ:',
                            style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ...p.orders.map((order) => _buildDebugOrderCard(order)).toList(),
                        ],
                      ) : const Text(
                        'ЗАКАЗОВ НЕТ!',
                        style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                      )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugOrderCard(Order order) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${order.orderNumber}',
            style: const TextStyle(color: Colors.cyan, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            'Status: ${order.status}',
            style: const TextStyle(color: Colors.orange, fontSize: 14),
          ),
          Text(
            'Total: ${order.totalAmount} TMT',
            style: const TextStyle(color: Colors.green, fontSize: 14),
          ),
          Text(
            'Date: ${order.formattedDate}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Items: ${order.items.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              'First item: ${order.items.first.productName}',
              style: const TextStyle(color: Colors.yellow, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
