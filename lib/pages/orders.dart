import 'dart:typed_data';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plantmana_test/pages/homepage.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import '../providers/products_provider.dart';
import '../utils/image_cache.dart' as image_cache;

import '../components/safe_image.dart';
import '../utils/image_cache.dart' as image_cache;
// import '../components/bottomNavBar.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, this.page});
  
  final String? page;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ordersProvider = context.read<OrdersProvider>();
      ordersProvider.loadOrders();
      ordersProvider.loadMethods();
      // Автоматически обновляем заказы через 2 секунды после загрузки
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && ordersProvider.orders.isEmpty && ordersProvider.state != OrdersState.loading) {
          print('OrdersPage: Автоматическое обновление заказов...');
          ordersProvider.refreshOrders();
        }
      });
    });
  }

  Future<void> _loadOrders() async {
    final ordersProvider = context.read<OrdersProvider>();
    await ordersProvider.loadOrders();
  }

  // Load image for order item - first try cache, then try to find product by name, then try to download
  Future<Uint8List?> _loadOrderItemImage(OrderItem item) async {
    try {
      // First try to load from cache using the provided productId
      if (item.productId > 0) {
        final cached = await image_cache.ImageCache.loadProductImage(item.productId);
        if (cached != null) {
          return cached;
        }
      }

      // If not in cache or productId is 0, try to find the product by name from products provider
      final productsProvider = context.read<ProductsProvider>();
      final products = productsProvider.allProducts;
      final matchingProduct = products.firstWhere(
        (p) => p.name == item.productName,
        orElse: () => Product(
          id: 0,
          name: '',
          slug: '',
          sku: '',
          categoryId: 0,
          categoryName: '',
          sectionName: '',
          sectionSlug: '',
          shortDescription: '',
          price: 0.0,
          currentPrice: 0.0,
          discountPercentage: 0,
          isFeatured: false,
          rating: 0.0,
          reviewCount: 0,
          mainImage: '',
          stock: 0,
        ),
      );

      if (matchingProduct.id > 0) {
        print('OrdersPage: Found product by name: ${matchingProduct.name} (ID: ${matchingProduct.id})');

        // Try to load from cache using the correct product ID
        final cached = await image_cache.ImageCache.loadProductImage(matchingProduct.id);
        if (cached != null) {
          return cached;
        }

        // If not in cache, try to download from the product's main image
        if (matchingProduct.mainImage.isNotEmpty) {
          print('OrdersPage: Attempting to download image from product: ${matchingProduct.mainImage}');
          return await image_cache.ImageCache.downloadAndCacheImage(matchingProduct.id, matchingProduct.mainImage);
        }
      }

      // If we have a productImage URL from the order item, try to download it
      if (item.productImage.isNotEmpty) {
        print('OrdersPage: Attempting to download image from order item: ${item.productImage}');
        final productId = item.productId > 0 ? item.productId : (matchingProduct.id > 0 ? matchingProduct.id : 0);
        return await image_cache.ImageCache.downloadAndCacheImage(productId, item.productImage);
      }

      print('OrdersPage: No image available for product "${item.productName}"');
      return null;
    } catch (e) {
      print('OrdersPage: Error loading image for product "${item.productName}": $e');
      return null;
    }
  }

  // Вызов отмены не используется в текущей версии UI; оставлено на будущее
  Future<void> _cancelOrder(Order order) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Отменить заказ'),
          content: Text('Вы уверены, что хотите отменить заказ #${order.orderNumber}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Отменить заказ'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final ordersProvider = context.read<OrdersProvider>();
        final success = await ordersProvider.cancelOrder(order.id);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Заказ успешно отменен'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ordersProvider.errorMessage ?? 'Ошибка отмены заказа'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отмены заказа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reorder(Order order) async {
    try {
      final ordersProvider = context.read<OrdersProvider>();
      final success = await ordersProvider.reorder(order.id);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заказ добавлен в корзину'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ordersProvider.errorMessage ?? 'Ошибка повторного заказа'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка повторного заказа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Создаем красивую иконку для товара
  Widget _buildProductIcon(String productName, {double width = 100, double height = 100, double iconSize = 40, double fontSize = 10, bool showText = true}) {
    final name = productName.toLowerCase();
    String assetPath;
    Color color;

    if (name.contains('rose') || name.contains('flower') || name.contains('tulip') || name.contains('lily') || name.contains('sunflower') || name.contains('цвет') || name.contains('букет') || name.contains('роза') || name.contains('тюльпан')) {
      assetPath = 'assets/images/flower.svg';
      color = const Color(0xFF8B3A3A);
    } else if (name.contains('plant') || name.contains('tree') || name.contains('cactus') || name.contains('растен') || name.contains('растение') || name.contains('комнатн') || name.contains('кактус')) {
      assetPath = 'assets/images/plant.svg';
      color = const Color(0xFF4B2E2E);
    } else if (name.contains('coffee') || name.contains('drink') || name.contains('food') || name.contains('кафе') || name.contains('кофе') || name.contains('напиток') || name.contains('еда')) {
      assetPath = 'assets/images/coffee.svg';
      color = const Color(0xFF8B3A3A);
    } else {
      assetPath = 'assets/images/plant.svg'; // default to plant
      color = const Color(0xFF4B2E2E); // Use plant color as default
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            assetPath,
            width: iconSize,
            height: iconSize,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          if (showText) ...[
            const SizedBox(height: 4),
            Text(
              productName.length > (width / 10).round() ? '${productName.substring(0, (width / 10).round())}...' : productName,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // SVG фон
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/flowerbg.svg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Основной контент
            SafeArea(
              top: true, // Explicitly handle top safe area
              bottom: false, // Let bottom nav handle bottom
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Заголовок "Мои заказы" слева
                    Row(
                      children: [
                        const Text(
                          'Мои заказы',
                          style: TextStyle(
                            color: Colors.black, // Черный заголовок для лучшей видимости
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _buildContent(ordersProvider),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(OrdersProvider ordersProvider) {
    switch (ordersProvider.state) {
      case OrdersState.initial:
        return _buildInitialState();
      case OrdersState.loading:
        return _buildLoadingState();
      case OrdersState.loaded:
        return _buildLoadedState(ordersProvider);
      case OrdersState.error:
        return _buildErrorState(ordersProvider);
      case OrdersState.empty:
        return _buildEmptyState();
    }
  }

  Widget _buildInitialState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            'Нажмите для загрузки заказов',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Загружаем ваши заказы...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(OrdersProvider ordersProvider) {
    return RefreshIndicator(
      onRefresh: () => ordersProvider.refreshOrders(),
      color: const Color(0xFF9A463C),
      child: ListView.builder(
        itemCount: ordersProvider.orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(ordersProvider.orders[index]);
        },
      ),
    );
  }

  Widget _buildErrorState(OrdersProvider ordersProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки заказов',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ordersProvider.errorMessage ?? 'Произошла неизвестная ошибка',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => ordersProvider.retry(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A463C),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Повторить'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => ordersProvider.clearError(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Очистить'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Дополнительная кнопка для случаев когда заказы созданы но не отображаются
          if (ordersProvider.errorMessage?.contains('не отображаются') == true)
            ElevatedButton.icon(
              onPressed: () => ordersProvider.refreshOrders(),
              icon: const Icon(Icons.refresh),
              label: const Text('Обновить заказы'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: const Color.fromARGB(255, 22, 22, 22).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'У вас пока нет заказов',
            style: TextStyle(
              color: const Color.fromARGB(255, 8, 8, 8).withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Сделайте первый заказ в каталоге',
            style: TextStyle(
              color: const Color.fromARGB(255, 17, 17, 17).withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Навигация в каталог
              Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A463C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Перейти в каталог'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, // Белый цвет для карточки заказа
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Заказ #${order.orderNumber}',
                        style: const TextStyle(
                          color: Color(0xFF2F3F24),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(order.status).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(order.status),
                        color: _getStatusColor(order.status),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _getStatusText(order.status),
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (order.items.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FutureBuilder<Uint8List?>(
                        future: _loadOrderItemImage(order.items.first),
                        builder: (context, snapshot) {
                          print('OrdersPage: Loading image for product ${order.items.first.productId} (${order.items.first.productName}), state: ${snapshot.connectionState}');
                          if (snapshot.connectionState == ConnectionState.done) {
                            if (snapshot.hasData && snapshot.data != null) {
                              print('OrdersPage: Image loaded for product ${order.items.first.productId}');
                              return Image.memory(
                                snapshot.data!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('OrdersPage: Error displaying image: $error');
                                  return _buildProductIcon(order.items.first.productName);
                                },
                              );
                            } else {
                              print('OrdersPage: No image available for product ${order.items.first.productId}, showing fallback');
                              return _buildProductIcon(order.items.first.productName);
                            }
                          } else {
                            // Show loading indicator while loading
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B3A3A)),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items.first.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2F3F24),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (order.items.length > 1) ...[
                          const SizedBox(height: 4),
                          Text(
                            'и еще ${order.items.length - 1} товар(ов)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${order.totalAmount.toInt()} TMT',
                              style: const TextStyle(
                                color: Color(0xFF9A463C),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (order.deliveryFee > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(+${order.deliveryFee.toInt()} TMT доставка)',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            Builder(builder: (context) {
              final status = order.status.toLowerCase();
              final canCancel = status == 'pending' || status == 'новый' || status == 'confirmed' || status == 'подтвержден' || status == 'в обработке';
              final canReorder = status == 'delivered' || status == 'доставлен' || status == 'cancelled' || status == 'отменен';
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => _showOrderDetailsDialog(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9A463C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Детали',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (canCancel)
                        OutlinedButton(
                          onPressed: () => _cancelOrder(order),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF9A463C),
                            side: const BorderSide(color: Color(0xFF9A463C)),
                            minimumSize: const Size(100, 40),
                          ),
                          child: const Text('Отменить'),
                        ),
                      
                      const SizedBox(width: 8),
                      if (canReorder)
                        ElevatedButton(
                          onPressed: () => _reorder(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9A463C),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Повторить',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
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
        return const Color(0xFF1976D2);
      case 'delivered':
      case 'доставлен':
        return const Color(0xFF487F2C);
      case 'cancelled':
      case 'отменен':
        return const Color(0xFF800200);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
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

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'новый':
        return 'Ожидает';
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

  void _showStatusUpdateDialog(Order order) {
    String selectedStatus = order.status;
    bool isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.edit,
                    color: Color(0xFF1976D2),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Изменить статус заказа #${order.orderNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(order.status),
                          color: _getStatusColor(order.status),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Текущий статус: ${_getStatusText(order.status)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Выберите новый статус:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Новый статус',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: [
                      'Новый',
                      'В обработке',
                      'Отправлен',
                      'Доставлен',
                      'Отменен',
                    ].map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              color: _getStatusColor(status),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(_getStatusText(status)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: isUpdating ? null : (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedStatus = newValue;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Выберите статус';
                      }
                      if (value == order.status) {
                        return 'Статус не изменился';
                      }
                      return null;
                    },
                  ),
                  if (selectedStatus != order.status) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Статус будет изменен с "${_getStatusText(order.status)}" на "${_getStatusText(selectedStatus)}"',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: isUpdating || selectedStatus == order.status
                      ? null
                      : () async {
                          setState(() {
                            isUpdating = true;
                          });
                          
                          try {
                            Navigator.of(context).pop();
                            await _updateOrderStatus(order, selectedStatus);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ошибка: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Обновить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      final ordersProvider = context.read<OrdersProvider>();
      final success = await ordersProvider.updateOrderStatus(order.id, newStatus);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Статус заказа #${order.orderNumber} обновлен на "${_getStatusText(newStatus)}"'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ordersProvider.errorMessage ?? 'Ошибка при обновлении статуса заказа'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Форматирование даты для отображения
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Показываем диалог с деталями заказа
  void _showOrderDetailsDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF8B3A3A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Заказ #${order.orderNumber}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Информация о заказе
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статус: ${_getStatusText(order.status)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B3A3A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Дата: ${_formatDate(order.createdAt)}'),
                    Text('Сумма: ${order.totalAmount.toStringAsFixed(2)} TMT'),
                    if (order.deliveryFee > 0) Text('Доставка: ${order.deliveryFee.toStringAsFixed(2)} TMT'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Список всех товаров
              Text(
                'Товары (${order.items.length}):',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              ...order.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Изображение товара
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.productImage.isNotEmpty
                          ? SafeImage(
                              imageUrl: item.productImage,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : _buildProductIcon(item.productName, width: 60, height: 60, iconSize: 24, fontSize: 8),
                    ),
                    const SizedBox(width: 12),
                    
                    // Информация о товаре
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Количество: ${item.quantity}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Цена: ${item.price.toStringAsFixed(2)} TMT',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Итого: ${item.totalPrice.toStringAsFixed(2)} TMT',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B3A3A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
} 