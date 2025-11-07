import 'package:flutter/material.dart';
import '../components/bottomNavBar.dart';
import '../components/catalogItem.dart';
import '../components/category.dart';
import '../components/filterDrawer.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/products_provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key, this.page});
  
  final String? page;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<Product> _favoriteProducts = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  // removed unused: selected category is derived from filters
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  // removed unused: count is derived from provider
  
  Map<String, dynamic> _currentFilters = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final products = context.read<ProductsProvider>();
      await products.loadCategories();
      await context.read<FavoritesProvider>().loadFavorites();
      if (!mounted) return;
      _loadFromProviders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // вспомогательные ранее неиспользуемые методы удалены

  void _loadCategoriesLocal() {
    final products = context.read<ProductsProvider>();
    final filtered = products.allCategories
        .where((c) => c.sectionSlug == widget.page)
        .toList();
    setState(() {
      _categories = filtered;
      _isLoadingCategories = false;
    });
  }

  void _loadFavoritesLocal() {
    final fav = context.read<FavoritesProvider>();
    setState(() {
      _favoriteProducts = fav.products;
      _filteredProducts = fav.products;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _loadFromProviders() {
    _loadCategoriesLocal();
    _loadFavoritesLocal();
  }

  void _applyFilters() {
    if (_favoriteProducts.isEmpty) return;
    
    List<Product> filtered = List.from(_favoriteProducts);
    
    // Фильтрация по поиску
    if (_currentFilters['search'] != null && _currentFilters['search'].toString().isNotEmpty) {
      final searchQuery = _currentFilters['search'].toString().toLowerCase();
      filtered = filtered.where((product) => 
        product.name.toLowerCase().contains(searchQuery) ||
        product.shortDescription.toLowerCase().contains(searchQuery)
      ).toList();
    }
    
    // Фильтрация по категории
    if (_currentFilters['category'] != null) {
      filtered = filtered.where((product) => 
        product.categoryName == _currentFilters['category']
      ).toList();
    }
    
    // Фильтрация по цене
    if (_currentFilters['priceRange'] != null) {
      final priceRange = _currentFilters['priceRange'].toString();
      switch (priceRange) {
        case '0-500':
          filtered = filtered.where((product) => product.currentPrice <= 500).toList();
          break;
        case '500-1000':
          filtered = filtered.where((product) => 
            product.currentPrice > 500 && product.currentPrice <= 1000
          ).toList();
          break;
        case '1000-2000':
          filtered = filtered.where((product) => 
            product.currentPrice > 1000 && product.currentPrice <= 2000
          ).toList();
          break;
        case '2000+':
          filtered = filtered.where((product) => product.currentPrice > 2000).toList();
          break;
      }
    }
    
    // Фильтрация по рейтингу
    if (_currentFilters['ratingRange'] != null) {
      final ratingRange = _currentFilters['ratingRange'].toString();
      switch (ratingRange) {
        case '4.5+':
          filtered = filtered.where((product) => product.rating >= 4.5).toList();
          break;
        case '4.0+':
          filtered = filtered.where((product) => product.rating >= 4.0).toList();
          break;
        case '3.5+':
          filtered = filtered.where((product) => product.rating >= 3.5).toList();
          break;
      }
    }
    
    if (mounted) {
      setState(() {
        _filteredProducts = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        endDrawer: FilterDrawer(
          page: widget.page,
          onFiltersApplied: (filters) {
            setState(() {
              _currentFilters = filters;
            });
            _applyFilters();
          },
        ),
        body: SafeArea(
          child: Container(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Заголовок "Избранное" слева
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Row(
                          children: [
                            const Text(
                              'Избранное',
                              style: TextStyle(
                                color: Colors.black, // Черный заголовок для лучшей видимости
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                                                                                            child: ClipRRect(
                                 borderRadius: BorderRadius.circular(100),
                                 child: TextFormField(
                                   controller: _searchController,
                                   focusNode: _searchFocusNode,
                                   onChanged: (value) {
                                     setState(() {
                                       _currentFilters['search'] = value;
                                     });
                                     _applyFilters();
                                   },
                                   decoration: InputDecoration(
                                     isDense: true,
                                     hintText: 'Search...',
                                     hintStyle: const TextStyle(color: Color(0xFF989898)),
                                     enabledBorder: OutlineInputBorder(
                                       borderSide: const BorderSide(color: Colors.transparent),
                                       borderRadius: BorderRadius.circular(100),
                                     ),
                                     focusedBorder: OutlineInputBorder(
                                       borderSide: const BorderSide(color: Colors.transparent),
                                       borderRadius: BorderRadius.circular(100),
                                     ),
                                     filled: true,
                                     fillColor: Colors.white, // Белый цвет для всех секций
                                     contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                     suffixIcon: Row(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         if (_searchController.text.isNotEmpty)
                                           IconButton(
                                             icon: const Icon(Icons.clear, color: Colors.grey),
                                             onPressed: () {
                                               _searchController.clear();
                                               setState(() {
                                                 _currentFilters['search'] = '';
                                               });
                                               _applyFilters();
                                             },
                                           ),
                                         IconButton(
                                           icon: Icon(
                                             Icons.tune,
                                             color: widget.page == 'plants' ? const Color(0xFF4CAF50) : null,
                                           ),
                                           onPressed: () {
                                             Scaffold.of(context).openEndDrawer();
                                           },
                                         ),
                                       ],
                                     ),
                                   ),
                                   style: const TextStyle(color: Colors.black),
                                   cursorColor: Colors.black,
                                 ),
                               ),
                            ),
                            Container(
                              height: 40,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    // Кнопка "Все"
                                    CategoryWidget(
                                      page: widget.page,
                                      onTap: () {
                                        setState(() {
                                          _currentFilters['category'] = null;
                                        });
                                        _applyFilters();
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    // Динамические категории
                                    if (_isLoadingCategories)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    else
                                      ..._categories.map((category) => Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: CategoryWidget(
                                          category: category,
                                          page: widget.page,
                                          onTap: () {
                                            setState(() {
                                              _currentFilters['category'] = category.name;
                                            });
                                            _applyFilters();
                                          },
                                        ),
                                      )).toList(),
                                    // Добавляем отступ справа для лучшего скролла
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 110),
                          child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _filteredProducts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 80,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Товары не найдены',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Попробуйте изменить параметры поиска',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : MasonryGridView.builder(
                                  gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                  ),
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredProducts[index];
                                    return CatalogitemWidget(
                                      key: Key('Favorite_${item.id}'),
                                      name: item.name,
                                      imageUrl: '', // Используем локальные иконки
                                      price: item.price.toString(),
                                      discountPrice: item.discountPrice?.toString() ?? '',
                                      page: widget.page,
                                      product: item,
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Нижняя навигация
                Align(
                  alignment: Alignment.bottomCenter,
                  child: BottomNavBarWidget(page: widget.page),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 