import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/interfaces/i_cart_service.dart';
import '../di/locator.dart';
import '../models/address.dart';
// removed direct AddressService usage; using AddressesProvider
import '../services/interfaces/i_order_service.dart';
import '../providers/cart_provider.dart';
import '../providers/addresses_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import '../pages/addressList.dart';
import '../pages/orders.dart';
import '../utils/input_sanitizer.dart';
import '../components/safe_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, this.page});
  
  final String? page;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ICartService _cartService = locator.get<ICartService>();
  final IOrderService _orderService = locator.get<IOrderService>();
  
  Address? _selectedAddress;
  List<Address> _userAddresses = [];
  bool _isLoadingAddresses = false;
  
  List<Map<String, dynamic>> _cartItems = [];
  // Используется как индикатор загрузки данных корзины
  bool _isLoading = true;
  double _subtotal = 0.0;
  double _deliveryFee = 5.99;
  int? _selectedPaymentMethod; // Убираем жестко заданное значение
  int? _selectedDeliveryMethod; // Убираем жестко заданное значение
  DateTime _selectedDeliveryDate = DateTime.now().add(const Duration(days: 3));
  List<Map<String, dynamic>> _deliveryMethods = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoadingMethods = false;
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthProvider>().initialize();
      await context.read<CartProvider>().loadCart();
      await context.read<AddressesProvider>().loadAddresses();
      await context.read<OrdersProvider>().loadMethods();
      if (!mounted) return;
      _syncFromProviders();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCartItems() async {
    await context.read<CartProvider>().loadCart();
    _syncFromProviders();
  }

  Future<void> _loadUserAddresses() async {
    await context.read<AddressesProvider>().loadAddresses();
    _syncFromProviders();
  }

  Future<void> _loadDeliveryAndPaymentMethods() async {
    await context.read<OrdersProvider>().loadMethods();
    _syncFromProviders();
  }

  void _syncFromProviders() {
    final cart = context.read<CartProvider>();
    final addr = context.read<AddressesProvider>();
    final ord = context.read<OrdersProvider>();
    final auth = context.read<AuthProvider>();
    setState(() {
      _cartItems = cart.items;
      _subtotal = cart.subtotal;
      _userAddresses = addr.addresses;
      _selectedAddress = addr.selected;
      _deliveryMethods = ord.deliveryMethods;
      _paymentMethods = ord.paymentMethods;
      
      // Автоматически выбираем первый доступный метод если ничего не выбрано
      if (_selectedPaymentMethod == null && _paymentMethods.isNotEmpty) {
        _selectedPaymentMethod = _paymentMethods.first['id'];
      }
      if (_selectedDeliveryMethod == null && _deliveryMethods.isNotEmpty) {
        // По умолчанию выбираем первый доступный метод доставки
        _selectedDeliveryMethod = _deliveryMethods.first['id'];
      }
      
      _isLoading = false;
      _isLoadingAddresses = false;
      _isLoadingMethods = false;
    });
    // Предзаполнение полей клиента из профиля, если они пустые
    final user = auth.currentUser;
    if (user != null) {
      if (_nameController.text.trim().isEmpty) {
        final first = user.firstName;
        final last = user.lastName;
        final username = user.username;
        final full = [first, last].where((e) => e.trim().isNotEmpty).join(' ').trim();
        _nameController.text = InputSanitizer.sanitizeName(full.isNotEmpty ? full : username);
      }
      if (_phoneController.text.trim().isEmpty) {
        final phone = user.phone;
        _phoneController.text = InputSanitizer.sanitizePhone(phone);
      }
      if (_emailController.text.trim().isEmpty) {
        final email = user.email;
        _emailController.text = InputSanitizer.sanitizeEmail(email);
      }
    }
    // Автовыбор ID и цены
    if (_deliveryMethods.isNotEmpty) {
      final deliveryId = _deliveryMethods.first['id'];
      if (deliveryId != null) {
        _selectedDeliveryMethod = deliveryId is int ? deliveryId : int.tryParse(deliveryId.toString()) ?? 1;
      }
      final price = _deliveryMethods.first['price'];
      if (price != null) {
        _deliveryFee = _parsePrice(price);
      }
    }
    if (_paymentMethods.isNotEmpty) {
      final paymentId = _paymentMethods.first['id'];
      if (paymentId != null) {
        _selectedPaymentMethod = paymentId is int ? paymentId : int.tryParse(paymentId.toString()) ?? 1;
      }
    }
  }

  void _navigateToAddressList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressListPage(),
      ),
    ).then((_) {
      _loadUserAddresses();
    });
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isRequired = true,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B2E2E),
          ),
        ),
        const SizedBox(height: 8),
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
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 400) {
                      // Для узких экранов используем Column
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['price']?.toString() ?? '0'} TMT',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B3A3A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF4CAF50)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        if (item['quantity'] > 1) {
                                          await _cartService.updateCartItemQuantity(
                                            item['id'],
                                            item['quantity'] - 1,
                                          );
                                          _loadCartItems();
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
                                      '${item['quantity']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        await _cartService.updateCartItemQuantity(
                                          item['id'],
                                          item['quantity'] + 1,
                                        );
                                        _loadCartItems();
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
                                onPressed: () async {
                                  await _cartService.removeFromCart(item['id']);
                                  _loadCartItems();
                                },
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      // Для широких экранов используем Row
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item['price']?.toString() ?? '0'} TMT',
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
                                  border: Border.all(color: const Color(0xFF4CAF50)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        if (item['quantity'] > 1) {
                                          await _cartService.updateCartItemQuantity(
                                            item['id'],
                                            item['quantity'] - 1,
                                          );
                                          _loadCartItems();
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
                                      '${item['quantity']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        await _cartService.updateCartItemQuantity(
                                          item['id'],
                                          item['quantity'] + 1,
                                        );
                                        _loadCartItems();
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
                                onPressed: () async {
                                  await _cartService.removeFromCart(item['id']);
                                  _loadCartItems();
                                },
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Способ оплаты',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B2E2E),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingMethods)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_paymentMethods.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Методы оплаты не загружены',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _paymentMethods.map((method) {
              return _buildPaymentOption(
                (method['id'] ?? '').toString(),
                _getPaymentIcon(method['id'] ?? ''),
                method['name'] ?? '',
              );
            }).toList(),
          ),
      ],
    );
  }

  IconData _getPaymentIcon(dynamic methodId) {
    final id = methodId.toString();
    switch (id) {
      case '1': // Credit Card
        return Icons.credit_card;
      case '2': // Cash on Delivery
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPaymentOption(String value, IconData icon, String label) {
            final isSelected = _selectedPaymentMethod == (int.tryParse(value) ?? 1);
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPaymentMethod = int.tryParse(value) ?? 1;
            });
          },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B3A3A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B3A3A) : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF8B3A3A),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF8B3A3A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Способ доставки',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B2E2E),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingMethods)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_deliveryMethods.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Методы доставки не загружены',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _deliveryMethods.map((method) {
              return _buildDeliveryOption(
                (method['id'] ?? '').toString(),
                _getDeliveryIcon(method['id'] ?? ''),
                method['name'] ?? '',
                _parsePrice(method['price']),
              );
            }).toList(),
          ),
      ],
    );
  }

  IconData _getDeliveryIcon(dynamic methodId) {
    final id = methodId.toString();
    switch (id) {
      case '1': // Standard Delivery
        return Icons.local_shipping;
      case '2': // Express Delivery
        return Icons.flash_on;
      default:
        return Icons.local_shipping;
    }
  }

  double _parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }

  Widget _buildDeliveryOption(String value, IconData icon, String label, double price) {
    final isSelected = _selectedDeliveryMethod == (int.tryParse(value) ?? 1);
    return GestureDetector(
              onTap: () {
          setState(() {
            _selectedDeliveryMethod = int.tryParse(value) ?? 1;
            _deliveryFee = price;
          });
        },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B3A3A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B3A3A) : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF8B3A3A),
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF8B3A3A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  price > 0 ? '${price.toStringAsFixed(2)} TMT' : 'Бесплатно',
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : const Color(0xFF8C7070),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дата доставки',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B2E2E),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDeliveryDate,
              firstDate: DateTime.now().add(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null && picked != _selectedDeliveryDate) {
              setState(() {
                _selectedDeliveryDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF8B3A3A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedDeliveryDate.day.toString().padLeft(2, '0')}.${_selectedDeliveryDate.month.toString().padLeft(2, '0')}.${_selectedDeliveryDate.year}',
                  style: const TextStyle(
                    color: Color(0xFF4B2E2E),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF8B3A3A),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmOrder() async {
    // Валидация данных
    if (_deliveryMethods.isEmpty || _paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Методы доставки/оплаты недоступны. Повторите позже.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedDeliveryMethod == null || _selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите способ доставки и оплаты'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите ваше имя'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите номер телефона'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите адрес доставки'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Показываем индикатор загрузки с возможностью отмены
    bool orderCancelled = false;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Создание заказа'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Пожалуйста, подождите...'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                orderCancelled = true;
                Navigator.pop(context);
              },
              child: const Text('Отменить'),
            ),
          ],
        ),
      );

      // Проверяем что методы выбраны
      if (_selectedPaymentMethod == null || _paymentMethods.isEmpty) {
        throw Exception('Методы оплаты недоступны. Попробуйте позже.');
      }
      if (_selectedDeliveryMethod == null || _deliveryMethods.isEmpty) {
        throw Exception('Методы доставки недоступны. Попробуйте позже.');
      }

      // Подготавливаем данные для создания заказа
      final items = _cartItems.map((item) => {
        'product_id': item['id'],
        'quantity': item['quantity'],
        'price': item['price'],
        'product_image': item['image'], // Include image
      }).toList();

      final orderRequest = CreateOrderRequest(
        items: items,
        deliveryMethod: _selectedDeliveryMethod!,
        paymentMethod: _selectedPaymentMethod!,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        customerEmail: _emailController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        deliveryAddressId: _selectedAddress!.id,
        deliveryDate: _selectedDeliveryDate,
        recipientAddress: _selectedAddress!.fullAddress,
      );

      // Создаем заказ с таймаутом
      final order = await _orderService.createOrder(orderRequest).timeout(
        const Duration(seconds: 45), // Таймаут 45 секунд для создания заказа
        onTimeout: () {
          throw Exception('Превышено время ожидания. Попробуйте позже.');
        },
      );

      // Проверяем, не был ли заказ отменен
      if (orderCancelled) {
        return;
      }

      // Закрываем индикатор загрузки
      Navigator.pop(context);

      if (order != null) {
        // Очищаем локальную корзину
        await _cartService.clearCart();
        
        // Показываем успешное сообщение
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Заказ создан!'),
              content: Text('Ваш заказ #${order.orderNumber} успешно создан.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Переходим в список заказов
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => OrdersPage(page: widget.page)),
                    );
                  },
                  child: const Text('К заказам'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Закрываем индикатор загрузки
      if (!orderCancelled) {
        Navigator.pop(context);
      }

      if (mounted && !orderCancelled) {
        String errorMessage = 'Ошибка создания заказа';
        
        if (e.toString().contains('connection') || e.toString().contains('ConnectionException')) {
          errorMessage = 'Превышено время ожидания. Проверьте подключение к интернету.';
        } else if (e.toString().contains('API недоступен')) {
          errorMessage = 'Сервер временно недоступен. Попробуйте позже.';
        } else if (e.toString().contains('401') || e.toString().contains('авторизация')) {
          errorMessage = 'Требуется авторизация. Войдите в систему.';
        } else {
          errorMessage = 'Ошибка создания заказа: ${e.toString().replaceFirst('Exception: ', '')}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address*',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B2E2E),
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingAddresses)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_userAddresses.isEmpty)
          ElevatedButton.icon(
            onPressed: _navigateToAddressList,
            icon: const Icon(Icons.add),
            label: const Text('Add delivery address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B3A3A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
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
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<Address?>(
                    value: _userAddresses.contains(_selectedAddress) ? _selectedAddress : null,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text(
                      'Select address',
                      style: TextStyle(color: Color(0xFF989898)),
                    ),
                    items: [
                      ..._userAddresses.map((address) => DropdownMenuItem<Address?>(
                        value: address,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              address.displayLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4B2E2E),
                              ),
                            ),
                            Text(
                              address.fullAddress,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8C7070),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                     onChanged: (Address? newValue) {
                      context.read<AddressesProvider>().select(newValue);
                      setState(() {
                        _selectedAddress = newValue;
                      });
                      _loadDeliveryAndPaymentMethods();
                    },
                  ),
                ),
                IconButton(
                  onPressed: _navigateToAddressList,
                  icon: const Icon(Icons.add, color: Color(0xFF8B3A3A)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _subtotal + _deliveryFee;

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
              top: true,
              bottom: false,
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
                            'Check out',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Черный заголовок
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Для баланса
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  
                  // Основной контент
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        children: [
                          // Информация о клиенте
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
                                  'Customer',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4B2E2E),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildInputField(
                                  label: 'Your name*',
                                  controller: _nameController,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  label: 'Phone number*',
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  label: 'Email*',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _buildAddressField(),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  label: 'Special notes (optional)',
                                  controller: _notesController,
                                  isRequired: false,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Товары в корзине
                          if (_cartItems.isNotEmpty)
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
                                    'Cart Items',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4B2E2E),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 250, // Фиксированная высота для скролла
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
                                      '${_subtotal.toStringAsFixed(0)} TMT',
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
                                      '${_deliveryFee.toStringAsFixed(0)} TMT',
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
                                      '${total.toStringAsFixed(0)} TMT',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF8B3A3A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                 if (_isLoadingMethods)
                                   const Padding(
                                     padding: EdgeInsets.symmetric(vertical: 8),
                                     child: LinearProgressIndicator(minHeight: 2),
                                   ),
                                 _buildDeliveryMethod(),
                                const SizedBox(height: 20),
                                _buildDeliveryDateField(),
                                const SizedBox(height: 20),
                                 _buildPaymentMethod(),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _confirmOrder,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B3A3A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Confirm',
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
                    ),
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
