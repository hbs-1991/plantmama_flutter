import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// removed unused direct category import; categories come from provider
import '../providers/products_provider.dart';

class FilterDrawer extends StatefulWidget {
  const FilterDrawer({super.key, this.page, this.onFiltersApplied});

  final String? page;
  final Function(Map<String, dynamic>)? onFiltersApplied;

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  final TextEditingController _searchController = TextEditingController();
  
  List<String> _priceRanges = ['Все цены', '0-500', '500-1000', '1000-2000', '2000+'];
  List<String> _ratingRanges = ['Все рейтинги', '4.5+', '4.0+', '3.5+', '3.0+'];
  List<String> _stockRanges = ['Все', 'В наличии', 'Мало', 'Нет в наличии'];
  
  String? _selectedCategory;
  String? _selectedPriceRange;
  String? _selectedRatingRange;
  String? _selectedStockRange;
  bool _showOnlyFeatured = false;
  bool _showOnlyDiscounted = false;
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProductsProvider>().loadCategories();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Загрузка категорий выполняется через ProductsProvider

  void _applyFilters() {
    final filters = <String, dynamic>{
      'search': _searchController.text.trim(),
      'category': _selectedCategory,
      'priceRange': _selectedPriceRange,
      'ratingRange': _selectedRatingRange,
      'stockRange': _selectedStockRange,
      'showOnlyFeatured': _showOnlyFeatured,
      'showOnlyDiscounted': _showOnlyDiscounted,
    };
    
    widget.onFiltersApplied?.call(filters);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedPriceRange = null;
      _selectedRatingRange = null;
      _selectedStockRange = null;
      _showOnlyFeatured = false;
      _showOnlyDiscounted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchFillColor = const Color(0xFFE8F5E8);

    return Drawer(
      child: Container(
        color: const Color(0xFF3A5430),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text(
                        'Очистить',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const Text(
                      'Фильтры',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск по названию...',
                    hintStyle: const TextStyle(color: Color(0xFF989898)),
                    filled: true,
                    fillColor: searchFillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.search, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                       _buildFilterSection(
                        title: 'Категории',
                        icon: Icons.category,
                        children: [
                           Builder(
                             builder: (context) {
                               final provider = context.watch<ProductsProvider>();
                               final cats = provider.categoriesForSection(widget.page);
                               final isLoading = provider.isLoadingCategories && cats.isEmpty;
                               if (isLoading) {
                                 return const Padding(
                                   padding: EdgeInsets.all(8.0),
                                   child: Center(
                                     child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                                   ),
                                 );
                               }
                               return Column(
                                 children: cats.map((category) => _buildFilterOption(
                                   title: category.name,
                                   isSelected: _selectedCategory == category.name,
                                   onTap: () {
                                     setState(() {
                                       _selectedCategory = _selectedCategory == category.name 
                                         ? null 
                                         : category.name;
                                     });
                                   },
                                 )).toList(),
                               );
                             },
                           ),
                        ],
                      ),
                      const Divider(color: Colors.white54),
                      _buildFilterSection(
                        title: 'Цена',
                        icon: Icons.attach_money,
                        children: [
                          ..._priceRanges.map((range) => _buildFilterOption(
                            title: range,
                            isSelected: _selectedPriceRange == range,
                            onTap: () {
                              setState(() {
                                _selectedPriceRange = _selectedPriceRange == range 
                                  ? null 
                                  : range;
                              });
                            },
                          )),
                        ],
                      ),
                      const Divider(color: Colors.white54),
                      _buildFilterSection(
                        title: 'Рейтинг',
                        icon: Icons.star,
                        children: [
                          ..._ratingRanges.map((range) => _buildFilterOption(
                            title: range,
                            isSelected: _selectedRatingRange == range,
                            onTap: () {
                              setState(() {
                                _selectedRatingRange = _selectedRatingRange == range 
                                  ? null 
                                  : range;
                              });
                            },
                          )),
                        ],
                      ),
                      const Divider(color: Colors.white54),
                      _buildFilterSection(
                        title: 'Наличие',
                        icon: Icons.inventory,
                        children: [
                          ..._stockRanges.map((range) => _buildFilterOption(
                            title: range,
                            isSelected: _selectedStockRange == range,
                            onTap: () {
                              setState(() {
                                _selectedStockRange = _selectedStockRange == range 
                                  ? null 
                                  : range;
                              });
                            },
                          )),
                        ],
                      ),
                      const Divider(color: Colors.white54),
                      _buildFilterSection(
                        title: 'Дополнительно',
                        icon: Icons.tune,
                        children: [
                          _buildSwitchOption(
                            title: 'Только избранные',
                            value: _showOnlyFeatured,
                            onChanged: (value) {
                              setState(() {
                                _showOnlyFeatured = value;
                              });
                            },
                          ),
                          _buildSwitchOption(
                            title: 'Только со скидкой',
                            value: _showOnlyDiscounted,
                            onChanged: (value) {
                              setState(() {
                                _showOnlyDiscounted = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF3A5430),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Применить фильтры',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(
        Icons.keyboard_arrow_down,
        color: Colors.white,
      ),
      children: children,
    );
  }

  Widget _buildFilterOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF3A5430) : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected 
        ? const Icon(Icons.check, color: Colors.white)
        : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchOption({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: Colors.white.withValues(alpha: 0.3),
        inactiveThumbColor: Colors.white70,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }
} 