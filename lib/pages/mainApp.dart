import 'package:flutter/material.dart';

import 'catalog.dart';
import 'favorites.dart';
import 'shoppingCart.dart';
import 'history.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const CatalogWidget(page: 'flowers', pageTitle: 'Catalog'),
    const FavoritesPage(),
    const ShoppingCartPage(),
    const HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          _pages[_currentIndex],
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white, // Белый цвет для всех секций
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.store,
                    label: 'Catalog',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.favorite,
                    label: 'Favorites',
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.shopping_cart,
                    label: 'Shopping cart',
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.person,
                    label: 'Profile',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF8B3A3A) : const Color(0xFF8B3A3A).withValues(alpha: 0.6),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF8B3A3A) : const Color(0xFF8B3A3A).withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
} 