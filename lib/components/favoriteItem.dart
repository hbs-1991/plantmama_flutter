import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
import 'safe_image.dart';

class FavoriteItemWidget extends StatefulWidget {
  const FavoriteItemWidget({super.key, this.page});
  
  final String? page;

  @override
  State<FavoriteItemWidget> createState() => _FavoriteItemWidgetState();
}

class _FavoriteItemWidgetState extends State<FavoriteItemWidget> {
  bool _isVisible = true; // Controls widget visibility
  
  // Закомментированные переменные для работы с SharedPreferences
  // List<Map<String, dynamic>> _favoriteItems = [];
  // bool _isLoading = true;

  // Закомментированные функции для работы с SharedPreferences
  /*
  @override
  void initState() {
    super.initState();
    _loadFavoriteItems();
  }
  
  // Загрузка избранных товаров
  Future<void> _loadFavoriteItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> favoriteItems = prefs.getStringList('favorite_items') ?? [];
      
      setState(() {
        _favoriteItems = favoriteItems.map((item) => json.decode(item) as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке избранного: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Удаление товара из избранного
  Future<void> _removeFavoriteItem(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> favoriteItems = prefs.getStringList('favorite_items') ?? [];
      
      favoriteItems.removeWhere((item) {
        Map<String, dynamic> favoriteItem = json.decode(item);
        return favoriteItem['id'] == itemId;
      });
      
      await prefs.setStringList('favorite_items', favoriteItems);
      await _updateFavoritesCount();
      _loadFavoriteItems(); // Перезагружаем данные
    } catch (e) {
      print('Ошибка при удалении из избранного: $e');
    }
  }
  
  // Добавление товара в корзину из избранного
  Future<void> _addToCartFromFavorites(Map<String, dynamic> favoriteItem) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> cartItems = prefs.getStringList('cart_items') ?? [];
      
      // Создаем объект товара для корзины
      Map<String, dynamic> cartItem = {
        'id': favoriteItem['id'],
        'name': favoriteItem['name'],
        'price': favoriteItem['price'],
        'image': favoriteItem['image'],
        'quantity': 1, // По умолчанию количество 1
        'category': favoriteItem['category'],
        'sku': favoriteItem['sku'],
        'totalPrice': favoriteItem['price'],
        'addedAt': DateTime.now().toIso8601String(),
      };
      
      // Проверяем, есть ли уже такой товар в корзине
      bool itemExists = false;
      for (int i = 0; i < cartItems.length; i++) {
        Map<String, dynamic> existingItem = json.decode(cartItems[i]);
        if (existingItem['id'] == favoriteItem['id']) {
          // Обновляем количество существующего товара
          existingItem['quantity'] = (existingItem['quantity'] ?? 1) + 1;
          existingItem['totalPrice'] = existingItem['price'] * existingItem['quantity'];
          existingItem['addedAt'] = DateTime.now().toIso8601String();
          cartItems[i] = json.encode(existingItem);
          itemExists = true;
          break;
        }
      }
      
      // Если товара нет в корзине, добавляем новый
      if (!itemExists) {
        cartItems.add(json.encode(cartItem));
      }
      
      await prefs.setStringList('cart_items', cartItems);
      await _updateCartCount();
      
      // Показываем уведомление
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${favoriteItem['name']} добавлен в корзину!'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
      
    } catch (e) {
      print('Ошибка при добавлении в корзину из избранного: $e');
    }
  }
  
  // Обновление счетчика товаров в избранном
  Future<void> _updateFavoritesCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> favoriteItems = prefs.getStringList('favorite_items') ?? [];
      await prefs.setInt('favorites_count', favoriteItems.length);
    } catch (e) {
      print('Ошибка при обновлении счетчика избранного: $e');
    }
  }
  
  // Обновление счетчика товаров в корзине
  Future<void> _updateCartCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> cartItems = prefs.getStringList('cart_items') ?? [];
      
      int totalCount = 0;
      for (String item in cartItems) {
        Map<String, dynamic> cartItem = json.decode(item);
        totalCount += (cartItem['quantity'] ?? 1) as int;
      }
      
      await prefs.setInt('cart_count', totalCount);
    } catch (e) {
      print('Ошибка при обновлении счетчика корзины: $e');
    }
  }
  
  // Виджет для отображения избранного товара из SharedPreferences
  Widget _buildFavoriteItemFromData(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white, // Белый цвет для всех секций
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SafeImage(
                    imageUrl: item['image'] ?? 'https://picsum.photos/seed/936/600',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    page: widget.page,
                    sectionSlug: widget.page,
                    placeholder: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B3A3A)),
                        ),
                      ),
                    ),
                    errorWidget: _buildFavoriteItemIcon(item['name'] ?? 'Товар'),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['name'] ?? 'Товар',
                                style: const TextStyle(
                                  color: Color(0xFF4B2E2E),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeFavoriteItem(item['id']),
                              child: const FaIcon(
                                FontAwesomeIcons.heart,
                                color: Color(0xFF8B3A3A),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          item['category'] ?? 'Категория',
                          style: const TextStyle(
                            color: Color(0xFF8C7070),
                            fontSize: 12,
                          ),
                        ),
                        if (item['shortDescription'] != null && item['shortDescription'].isNotEmpty)
                          Text(
                            item['shortDescription'],
                            style: const TextStyle(
                              color: Color(0xFF8C7070),
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item['price']?.toInt() ?? 0}TMT',
                          style: TextStyle(
                            color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF9A463C),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _addToCartFromFavorites(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
                            minimumSize: const Size(80, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          icon: const FaIcon(
                            FontAwesomeIcons.cartPlus,
                            size: 12,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'В корзину',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return Container(); // Return empty container if not visible
    }
    
    // Закомментированный код для отображения товаров из SharedPreferences
    /*
    // Для использования товаров из SharedPreferences раскомментируйте этот блок
    // и закомментируйте существующий код ниже
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
        ),
      );
    }
    
    if (_favoriteItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Избранное пустое',
          style: TextStyle(
            color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return Column(
      children: _favoriteItems.map((item) => _buildFavoriteItemFromData(item)).toList(),
    );
    */
    
    // Статичный пример избранного товара (для демонстрации)
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white, // Белый цвет для всех секций
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SafeImage(
                    imageUrl: 'https://picsum.photos/seed/favorite/600',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    page: widget.page,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Favorite Plant',
                                style: TextStyle(
                                  color: Color(0xFF4B2E2E),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isVisible = false;
                                });
                              },
                              child: const FaIcon(
                                FontAwesomeIcons.heart,
                                color: Color(0xFF8B3A3A),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Растения',
                          style: TextStyle(
                            color: Color(0xFF8C7070),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '350TMT',
                          style: TextStyle(
                            color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF9A463C),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Товар добавлен в корзину!'),
                                backgroundColor: Color(0xFF4CAF50),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
                            minimumSize: const Size(80, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          icon: const FaIcon(
                            FontAwesomeIcons.cartPlus,
                            size: 12,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'В корзину',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Создаем красивую иконку для избранного товара
  Widget _buildFavoriteItemIcon(String productName) {
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
      width: 100,
      height: 100,
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
        size: 40,
      ),
    );
  }
}