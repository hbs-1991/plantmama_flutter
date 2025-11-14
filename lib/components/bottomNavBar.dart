import 'package:flutter/material.dart';
import 'package:plantmana_test/pages/catalog.dart';
import 'package:plantmana_test/pages/homepage.dart';
import 'package:plantmana_test/pages/settings.dart';
import 'package:plantmana_test/pages/shoppingCart.dart';
import 'package:plantmana_test/pages/favorites.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';

class BottomNavBarWidget extends StatefulWidget {
  const BottomNavBarWidget({super.key, this.page});
  
  final String? page;

  @override
  State<BottomNavBarWidget> createState() => _BottomNavBarWidgetState();
}

class _BottomNavBarWidgetState extends State<BottomNavBarWidget> {
  @override
  Widget build(BuildContext context) {
    // Используем watch: CartProvider/FavoritesProvider теперь нотифицируют безопасно после кадра
    final cart = context.watch<CartProvider>();
    final fav = context.watch<FavoritesProvider>();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: 70,
        constraints: const BoxConstraints(maxHeight: 70),
        decoration: BoxDecoration(
          color: widget.page == 'plants' 
            ? const Color(0xFF3A5220) // Цвет акцента для растений
            : widget.page == 'tsvety' || widget.page == "cvety"
              ? const Color(0xFFB58484) // Цвет акцента для цветов
              : const Color(0xFFA3B6CC), // Цвет акцента для кофе
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.home,
              label: 'Home',
              onTap: () {
                // TODO: Навигация на HomePageWidget
                Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
              },
            ),
            _buildNavItem(
              icon: Icons.shopping_basket,
              label: 'Catalog',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CatalogWidget(page: widget.page),
                  ),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.shopping_cart,
              label: 'Cart',
              badge: cart.itemsCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShoppingCartPage(page: widget.page),
                  ),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.favorite,
              label: 'Favorites',
              badge: fav.count,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoritesPage(page: widget.page),
                  ),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.person_sharp,
              label: 'Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(page: widget.page),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required VoidCallback onTap, int? badge}) {
    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: Colors.white, // Иконки теперь белые
                  size: 45,
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white, // Текст теперь белый
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
