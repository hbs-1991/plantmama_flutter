import 'package:flutter/material.dart';
import '../models/address.dart';
import 'package:provider/provider.dart';
import '../providers/addresses_provider.dart';
import '../components/addressForm.dart';
import '../test_address_api.dart';
import 'test_page.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({Key? key}) : super(key: key);

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  List<Address> addresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AddressesProvider>().loadAddresses();
      _loadAddresses();
    });
  }

  Future<void> _loadAddresses() async {
    try {
      print('AddressListPage: Начинаем загрузку адресов');
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final loadedAddresses = context.read<AddressesProvider>().addresses;
      print('AddressListPage: Получено адресов: ${loadedAddresses.length}');
      setState(() {
        addresses = loadedAddresses;
        _isLoading = false;
      });
    } catch (e) {
      print('AddressListPage: Ошибка загрузки: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text(
          'Мои адреса',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.bug_report, color: Color(0xFF8B4513)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TestPage()),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B4513),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Ошибка загрузки адресов',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error ?? 'Неизвестная ошибка',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) => ElevatedButton(
                                onPressed: _loadAddresses,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B4513),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Повторить'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) => ElevatedButton(
                                                onPressed: () async {
                                  final test = AddressApiTest();
                                  await test.testAddressApi();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Тест API'),
                              ),
                            ),
                          ],
                        ),
                      )
                    : addresses.isEmpty
                        ? const Center(
                            child: Text(
                              'У вас пока нет сохраненных адресов',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: addresses.length,
                            itemBuilder: (context, index) {
                              final address = addresses[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F5),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      address.displayLabel,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF4A4A4A),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (address.isDefault)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF4CAF50),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: const Text(
                                                          'По умолчанию',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  address.fullAddress,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Color(0xFF666666),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F5E8),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              address.icon,
                                              color: const Color(0xFF4CAF50),
                                              size: 30,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Builder(
                                        builder: (context) => Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                 onPressed: () {
                                                  _editAddress(address);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF8B4513),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                                child: const Text(
                                                  'Редактировать',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                 onPressed: () {
                                                  _deleteAddress(address);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF8B4513),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                                child: const Text(
                                                  'Удалить',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
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
                            },
                          ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (context) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _addNewAddress();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Добавить новый адрес',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Builder(
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF0F5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFFFFF0F5),
            selectedItemColor: const Color(0xFF8B4513),
            unselectedItemColor: const Color(0xFF8B4513),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Каталог',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Избранное',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Корзина',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Профиль',
              ),
            ],
            currentIndex: 3,
            onTap: (index) {
              _onBottomNavTap(index);
            },
          ),
        ),
      ),
    );
  }

  void _editAddress(Address address) {
    showDialog(
      context: context,
      builder: (context) => AddressForm(
        address: address,
        onSave: (updatedAddress) async {
          try {
            print('AddressListPage: Обновляем адрес');
            print('AddressListPage: ID: ${updatedAddress.id}');
            print('AddressListPage: Label: ${updatedAddress.label}');
            print('AddressListPage: Street: ${updatedAddress.streetAddress}');
            
            await context.read<AddressesProvider>().updateAddress(updatedAddress);
            Navigator.pop(context);
            _loadAddresses();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Адрес обновлен'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка обновления: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteAddress(Address address) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить адрес'),
        content: Text('Вы уверены, что хотите удалить адрес "${address.displayLabel}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<AddressesProvider>().deleteAddress(address.id);
                await _loadAddresses();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Адрес удален'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка удаления: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addNewAddress() {
    showDialog(
      context: context,
      builder: (context) => AddressForm(
        onSave: (newAddress) async {
          try {
            print('AddressListPage: Добавляем новый адрес');
            print('AddressListPage: label: ${newAddress.label}');
            print('AddressListPage: streetAddress: ${newAddress.streetAddress}');
            print('AddressListPage: apartment: ${newAddress.apartment}');
            print('AddressListPage: city: ${newAddress.city}');
            print('AddressListPage: postalCode: ${newAddress.postalCode}');
            print('AddressListPage: country: ${newAddress.country}');
            print('AddressListPage: isDefault: ${newAddress.isDefault}');
            
            await context.read<AddressesProvider>().addAddress(
              label: newAddress.label,
              streetAddress: newAddress.streetAddress,
              apartment: newAddress.apartment,
              city: newAddress.city,
              postalCode: newAddress.postalCode,
              isDefault: newAddress.isDefault,
            );
            await _loadAddresses();
            
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Адрес добавлен'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка добавления: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _onBottomNavTap(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Навигация на индекс: $index'),
        backgroundColor: const Color(0xFF8B4513),
      ),
    );
  }
}

