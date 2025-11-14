import 'package:flutter/material.dart';
import '../components/bottomNavBar.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Адреса выбираются на экране Checkout
import 'checkout.dart';
import '../components/safe_image.dart';

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key, this.page});
  
  final String? page;

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  // final AddressService _addressService = AddressService();
  
  // Убраны поля, не используемые после упрощения страницы корзины
  // Address? _selectedAddress;
  // List<Address> _userAddresses = [];
  // bool _isLoadingAddresses = false;
  
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  double _subtotal = 0.0;
  double _deliveryFee = 20.0;
  double get _totalPrice => _subtotal + _deliveryFee;
  bool get _hasItems => _cartItems.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCartData();
      await _loadUserAddresses();
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Удалена загрузка адресов в корзине — выбор адреса перенесён на экран оформления заказа
  Future<void> _loadUserAddresses() async {}

  Future<void> _loadCartData() async {
    final cart = context.read<CartProvider>();
    setState(() { _isLoading = true; });
    
    try {
      await cart.loadCart();
      if (!mounted) return;
      setState(() {
        _cartItems = cart.items;
        _subtotal = cart.subtotal;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки корзины: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Показываем пустую корзину при ошибке
        _cartItems = [];
        _subtotal = 0.0;
      });
    }
  }

  double _calculateItemTotal(Map<String, dynamic> item) {
    final totalPrice = item['totalPrice'];
    if (totalPrice != null) {
      return (totalPrice is double) ? totalPrice : double.tryParse(totalPrice.toString()) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _removeItem(int productId) async {
    try {
      await context.read<CartProvider>().remove(productId);
      await _loadCartData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Товар удален из корзины'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateItemQuantity(int productId, int newQuantity) async {
    try {
      await context.read<CartProvider>().updateQuantity(productId, newQuantity);
      await _loadCartData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Количество обновлено: $newQuantity'),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final quantity = item['quantity'] ?? 1;
    final price = item['price'] ?? 0.0;
    final totalPrice = _calculateItemTotal(item);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 252, 252),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF8B3A3A), width: 1)
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SafeImage(
              imageUrl: item['image'] ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              sectionSlug: widget.page ?? 'cart',
              placeholder: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 237, 237, 237),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B3A3A)),
                  ),
                ),
              ),
              errorWidget: _buildCartItemIcon(item['name'] ?? 'Товар'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B2E2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['category'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${price.toInt()} TMT',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B3A3A),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF8B3A3A)),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  if (quantity > 1) {
                                    await _updateItemQuantity(item['id'], quantity - 1);
                                  }
                                },
                                icon: const Icon(Icons.remove, size: 16),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await _updateItemQuantity(item['id'], quantity + 1);
                                },
                                icon: const Icon(Icons.add, size: 16),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeItem(item['id']),
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8C7070),
                      ),
                    ),
                    Text(
                      '${totalPrice.toInt()} TMT',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B3A3A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Используется в UI CheckoutPage, но здесь оставлено для модульного переноса
  // Удалён неиспользуемый элемент интерфейса (_buildInputField)

  // Используется для выбора адреса доставки на странице корзины
  // Удалён неиспользуемый элемент интерфейса (_buildAddressField)
  

  // Удалена навигация к списку адресов из корзины
  // Навигация к адресам не используется на этой странице

  // Вспомогательный диалог подтверждения промокода
  // Удалён неиспользуемый элемент интерфейса (_showPromocodeDialog)

  // Создаем красивую иконку для товара в корзине
  Widget _buildCartItemIcon(String productName) {
    final name = productName.toLowerCase();
    IconData icon;
    Color color;

    if (name.contains('rose') || name.contains('flower') || name.contains('tulip') || name.contains('lily')) {
      icon = Icons.local_florist;
      color = const Color(0xFF8B3A3A);
    } else if (name.contains('plant') || name.contains('tree') || name.contains('cactus')) {
      icon = Icons.eco;
      color = const Color(0xFF4B2E2E);
    } else if (name.contains('coffee') || name.contains('drink') || name.contains('food')) {
      icon = Icons.coffee;
      color = const Color(0xFF8B3A3A);
    } else {
      icon = Icons.shopping_bag;
      color = Colors.grey[600]!;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 30,
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'Корзина пуста',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Добавьте товары в корзину',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                children: [
                  // Заголовок
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.black), // Черная кнопка назад
                        ),
                        const Expanded(
                          child: Text(
                            'Shopping cart',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Черный заголовок
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            setState(() { _isLoading = true; });
                            await _loadCartData();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.black), // Черная кнопка обновления
                          tooltip: 'Обновить корзину',
                        ),
                      ],
                    ),
                  ),
                  
                  // Основной контент
                  Expanded(
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _hasItems
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Column(
                              children: [
                                // Товары в корзине
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 255, 255, 255), // Чуть темнее, но все еще белый
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cart Items',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4B2E2E),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 300, // Фиксированная высота для скролла
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _cartItems.length,
                                          itemBuilder: (context, index) {
                                            return _buildCartItem(_cartItems[index]);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Промокод
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white, // Белый цвет для всех секций
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Promocode',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4B2E2E),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.withValues(alpha: 0.3),
                                              style: BorderStyle.solid,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _promoController,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                                            hintText: 'Enter promocode',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // TODO: Apply promocode
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF8B3A3A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Use promocode',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Сводка заказа
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white, // Белый цвет для всех секций
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Order summary',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4B2E2E),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Subtotal',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF4B2E2E),
                                            ),
                                          ),
                                          Text(
                                            '${_subtotal.toInt()} TMT',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF4B2E2E),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Delivery',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF4B2E2E),
                                            ),
                                          ),
                                          Text(
                                            '${_deliveryFee.toInt()} TMT',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF4B2E2E),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 32),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Total price',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF4B2E2E),
                                            ),
                                          ),
                                          Text(
                                            '${_totalPrice.toInt()} TMT',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF8B3A3A),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CheckoutPage(page: widget.page),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF8B3A3A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Checkout',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                              ],
                            ),
                          )
                        : _buildEmptyCart(),
                  ),
                  
                  // Нижняя навигация
                  Container(
                    height: 70,
                    child: BottomNavBarWidget(page: widget.page),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}