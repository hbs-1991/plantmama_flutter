import 'package:flutter/material.dart';
import 'package:plantmana_test/components/catalogItem.dart';
import '../components/bottomNavBar.dart';
import '../components/category.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../components/filterDrawer.dart';

import '../models/product.dart';
import 'package:flutter_svg/flutter_svg.dart';
 

class CatalogWidget extends StatefulWidget {
  const CatalogWidget({
    super.key,
    String? page,
    String? pageTitle,
  }) : pageTitle = pageTitle ?? 'Catalog', page = page ?? 'catalog';

  final String pageTitle;
  final String page;

  static String routeName = 'catalog';
  static String routePath = '/catalog';

  @override
  State<CatalogWidget> createState() => _CatalogWidgetState();
}

class _CatalogWidgetState extends State<CatalogWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // local categories state no longer used (render reads from provider)
  
  Map<String, dynamic> _currentFilters = {};
  // Управление продуктами делаем реактивно через provider в build

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final products = context.read<ProductsProvider>();
      await products.loadCatalogIfNeeded();
      // Данные будут подтянуты через provider, UI обновится через watch в build
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // no-op



  List<Product> _computeFiltered(List<Product> source) {
    if (source.isEmpty) return const [];
    String expectedSectionSlug = '';
    switch (widget.page) {
      case 'цветы':
        expectedSectionSlug = 'цветы';
        break;
      case 'растения':
        expectedSectionSlug = 'растения';
        break;
      case 'кафе':
        expectedSectionSlug = 'кафе';
        break;
      default:
        expectedSectionSlug = widget.page; // Если нет прямого соответствия, используем slug как есть
        break;
    }
    List<Product> filtered = source.where((p) => p.sectionSlug == expectedSectionSlug).toList();
    if (_currentFilters['search'] != null && _currentFilters['search'].toString().isNotEmpty) {
      final q = _currentFilters['search'].toString().toLowerCase();
      filtered = filtered.where((p) => p.name.toLowerCase().contains(q) || p.shortDescription.toLowerCase().contains(q)).toList();
    }
    if (_currentFilters['categoryId'] != null) {
      filtered = filtered.where((p) => p.categoryId == _currentFilters['categoryId']).toList();
    }
    if (_currentFilters['priceRange'] != null) {
      final r = _currentFilters['priceRange'].toString();
      switch (r) {
        case '0-500':
          filtered = filtered.where((p) => p.currentPrice <= 500).toList();
          break;
        case '500-1000':
          filtered = filtered.where((p) => p.currentPrice > 500 && p.currentPrice <= 1000).toList();
          break;
        case '1000-2000':
          filtered = filtered.where((p) => p.currentPrice > 1000 && p.currentPrice <= 2000).toList();
          break;
        case '2000+':
          filtered = filtered.where((p) => p.currentPrice > 2000).toList();
          break;
      }
    }
    if (_currentFilters['ratingRange'] != null) {
      final r = _currentFilters['ratingRange'].toString();
      switch (r) {
        case '4.5+':
          filtered = filtered.where((p) => p.rating >= 4.5).toList();
          break;
        case '4.0+':
          filtered = filtered.where((p) => p.rating >= 4.0).toList();
          break;
        case '3.5+':
          filtered = filtered.where((p) => p.rating >= 3.5).toList();
          break;
        case '3.0+':
          filtered = filtered.where((p) => p.rating >= 3.0).toList();
          break;
      }
    }
    if (_currentFilters['stockRange'] != null) {
      final r = _currentFilters['stockRange'].toString();
      switch (r) {
        case 'В наличии':
          filtered = filtered.where((p) => p.stock > 10).toList();
          break;
        case 'Мало':
          filtered = filtered.where((p) => p.stock > 0 && p.stock <= 10).toList();
          break;
        case 'Нет в наличии':
          filtered = filtered.where((p) => p.stock == 0).toList();
          break;
      }
    }
    if (_currentFilters['showOnlyFeatured'] == true) {
      filtered = filtered.where((p) => p.isFeatured).toList();
    }
    if (_currentFilters['showOnlyDiscounted'] == true) {
      filtered = filtered.where((p) => p.discountPrice != null && p.discountPrice! < p.price).toList();
    }
    return filtered;
  }

  void _onFiltersApplied(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = filters;
    });
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
          onFiltersApplied: _onFiltersApplied,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Фоновое изображение
              Positioned.fill(
                child: widget.page == 'plants' 
                  ? Image.asset(
                      'assets/images/plantbg.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : SvgPicture.asset(
                      widget.page == 'flowers'
                        ? 'assets/images/flowerbg.svg'
                        : 'assets/images/coffeebg.svg',
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
                    
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(
                                Icons.tune,
                                color: Color(0xFF666666), // Светло-черный для всех секций
                                size: 30,
                              ),
                              onPressed: () {
                                Scaffold.of(context).openEndDrawer();
                              },
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
                                  setState(() {});
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
                                  fillColor: Colors.white, // Белый фон для всех секций
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
                                            setState(() {});
                                          },
                                        ),
                                      Builder(
                                        builder: (context) => IconButton(
                                          icon: const Icon(
                                            Icons.tune,
                                            color: Color(0xFF666666), // Светло-черный для всех секций
                                            size: 30,
                                          ),
                                          onPressed: () {
                                            Scaffold.of(context).openEndDrawer();
                                          },
                                        ),
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
                                        _currentFilters['categoryId'] = null;
                                      });
                                      setState(() {});
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  // Динамические категории через provider
                                  Builder(
                                    builder: (context) {
                                      final provider = context.watch<ProductsProvider>();
                                      final cats = provider.categoriesForSection(widget.page);
                                      if (provider.isLoadingCategories && cats.isEmpty) {
                                        return const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        );
                                      }
                                      return Row(
                                        children: cats.map((category) => Padding(
                                          padding: const EdgeInsets.only(right: 12),
                                          child: CategoryWidget(
                                            category: category,
                                            page: widget.page,
                                            onTap: () {
                                              setState(() {
                                                _currentFilters['category'] = category.name;
                                                _currentFilters['categoryId'] = category.id;
                                              });
                                            },
                                          ),
                                        )).toList(),
                                      );
                                    },
                                  ),
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
                        child: (() {
                          final provider = context.watch<ProductsProvider>();
                          final isLoadingProducts = provider.isLoadingProducts;
                          final baseProducts = provider.productsForSection(widget.page);
                          final filtered = _computeFiltered(baseProducts);
                          if (isLoadingProducts && baseProducts.isEmpty) {
                            return const Center(
                              child: SizedBox(width: 50, height: 50, child: CircularProgressIndicator()),
                            );
                          }
                          return filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: CircularProgressIndicator(color: Colors.white.withValues(alpha: 0.8)),
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
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return CatalogitemWidget(
                                    key: Key('Keyeba_${item.id}'),
                                    name: item.name,
                                    imageUrl: item.mainImage,
                                    price: item.price.toString(),
                                    discountPrice: item.discountPrice?.toString() ?? '',
                                    page: widget.page,
                                    product: item,
                                  );
                                },
                              );
                        })(),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [],
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 70,
                  child: BottomNavBarWidget(page: widget.page),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
