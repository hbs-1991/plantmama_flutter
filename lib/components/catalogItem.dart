import 'package:flutter/material.dart';
import '../models/product.dart';
import '../pages/itemInfo.dart';
import 'package:provider/provider.dart';
// cart operations handled via providers
import '../providers/favorites_provider.dart';
import '../providers/cart_provider.dart';
import 'safe_image.dart';

class CatalogitemWidget extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String price;
  final String discountPrice;
  final String? page;
  final Product? product;

  const CatalogitemWidget({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.discountPrice,
    this.page,
    this.product,
  });

  @override
  State<CatalogitemWidget> createState() => _CatalogitemWidgetState();
}

class _CatalogitemWidgetState extends State<CatalogitemWidget> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _checkIfFavorite();
    }
  }

  Future<void> _checkIfFavorite() async {
    if (widget.product == null) return;
    final fav = context.read<FavoritesProvider>();
    final isFavorite = fav.isFavoriteSync(widget.product!.id);
    setState(() { _isFavorite = isFavorite; });
  }

  Future<void> _toggleFavorite() async {
    if (widget.product == null) return;

    print('Переключение избранного для товара: ${widget.product!.name} (ID: ${widget.product!.id})');
    print('Текущее состояние избранного: $_isFavorite');

    try {
      await context.read<FavoritesProvider>().toggle(widget.product!);
      setState(() { _isFavorite = !_isFavorite; });
      print('Состояние избранного обновлено: $_isFavorite');
    } catch (e) {
      print('Ошибка при переключении избранного: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _addToCart() async {
    if (widget.product == null) return;

    try {
      await context.read<CartProvider>().add(widget.product!, 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product!.name} добавлен в корзину'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Ошибка при добавлении в корзину: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления в корзину: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDefaultIcon() {
    final section = widget.product?.sectionSlug ?? widget.page ?? '';
    final isFlowers = section == 'flowers';
    final isPlants = section == 'plants';
    final isCafe = section == 'cafe';
    
    IconData icon;
    Color color;

    if (isFlowers) {
      icon = Icons.local_florist;
      color = const Color(0xFF8B3A3A);
    } else if (isPlants) {
      icon = Icons.eco;
      color = const Color(0xFF4B2E2E);
    } else if (isCafe) {
      icon = Icons.coffee;
      color = Colors.white; // Белая иконка для кофе
    } else {
      icon = Icons.shopping_bag;
      color = Colors.grey[600]!;
    }
    
    return Icon(icon, color: color, size: 50);
  }

  // Создаем красивую иконку для товара
  Widget _buildProductIcon(String productName) {
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
      color = Colors.white; // Белая иконка для кофе
    } else {
      icon = Icons.shopping_bag;
      color = Colors.grey[600]!;
    }

    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 50,
          ),
          const SizedBox(height: 8),
          Text(
            productName.length > 15 ? '${productName.substring(0, 15)}...' : productName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.product != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ItemInfoPage(product: widget.product!),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.all(4.0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: widget.page == 'plants' 
                  ? Colors.transparent // Убираю заливку для растений
                  : widget.page == 'flowers'
                    ? const Color(0xFFB58484) // Правильный цвет для цветов
                    : const Color(0xFFA3B6CC), // Правильный цвет для кофе
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.page == 'plants' 
                    ? const Color(0xFF3A5220) // Правильный цвет для растений
                    : widget.page == 'flowers'
                      ? const Color(0xFFB58484) // Цвет границы для цветов
                      : const Color(0xFFA3B6CC), // Цвет границы для кофе
                  width: 1,
                ),
              ),
              child: (widget.imageUrl.isNotEmpty)
                  ? SafeImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                      sectionSlug: widget.product?.sectionSlug,
                      page: widget.page,
                      placeholder: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.page == 'plants' 
                                ? const Color(0xFF3A5220) // Правильный цвет для растений
                                : widget.page == 'flowers'
                                  ? const Color(0xFFB58484) // Правильный цвет для цветов
                                  : const Color(0xFFA3B6CC) // Правильный цвет для кофе
                            ),
                          ),
                        ),
                      ),
                      errorWidget: _buildProductIcon(widget.name),
                    )
                  : _buildDefaultIcon(),
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: widget.discountPrice.isNotEmpty
                    ? Row(
                        children: [
                          Text(
                            widget.discountPrice,
                            style: TextStyle(
                              color: widget.page == 'plants' 
                                ? const Color(0xFF3A5220) // Правильный цвет для растений
                                : widget.page == 'flowers'
                                  ? const Color(0xFFB58484) // Правильный цвет для цветов
                                  : const Color(0xFFA3B6CC), // Правильный цвет для кофе
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.price,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      )
                    :                         Text(
                          widget.price,
                          style: TextStyle(
                            color: widget.page == 'plants' 
                              ? const Color(0xFF3A5220) // Правильный цвет для растений
                              : widget.page == 'flowers'
                                ? const Color(0xFFB58484) // Правильный цвет для цветов
                                : const Color(0xFFA3B6CC), // Правильный цвет для кофе
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
              if (widget.product != null) ...[
                // Кнопка добавления в корзину
                GestureDetector(
                  onTap: () => _addToCart(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.page == 'plants' 
                        ? const Color(0xFF3A5220) // Правильный цвет для растений
                        : widget.page == 'flowers'
                          ? const Color(0xFFB58484) // Правильный цвет для цветов
                          : const Color(0xFFA3B6CC), // Правильный цвет для кофе
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Кнопка избранного
                GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }
}
