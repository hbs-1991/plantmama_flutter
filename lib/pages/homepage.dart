import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/products_provider.dart';
import '../components/navBar.dart';
import '../components/bottomNavBar.dart';
import '../components/safe_image.dart';
import '../config.dart';
import 'catalog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Загружаем секции при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().loadSections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
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
            Container(
              width: double.infinity,
          child: Column(
            children: [
              // Верхняя навигационная панель
              const NavBarWidget(
                pageTitle: 'Plant Mama',
                page: 'home',
              ),
              
              // Основной контент
              Expanded(
                child: Column(
                  children: [
                    // Секции категорий
                    Expanded(
                      child: Selector<ProductsProvider, (bool, List)>(
                        selector: (_, p) => (p.isLoadingSections, p.sections),
                        builder: (context, data, _) {
                          final isLoading = data.$1;
                          final sections = data.$2;
                          
                          if (isLoading && sections.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(
                                    color: Colors.white,
                              ),
                            );
                          }
                          
                          if (sections.isEmpty) {
                            return const Center(
                              child: Text(
                                'Нет доступных секций',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: sections.length,
                            itemBuilder: (context, index) {
                              final section = sections[index];
                              return _buildCard(
                                context,
                                section: section,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CatalogWidget(
                                        page: section.slug,
                                        pageTitle: section.name,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Текст "Выберите категорию" внизу
                    const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Text(
                        'Выберите категорию',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
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

  Widget _buildCard(BuildContext context, {required dynamic section, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 160,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white, // Белый цвет для всех секций
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Фоновое изображение из API
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: section.image != null && section.image!.isNotEmpty
                  ? SafeImage( // Using SafeImage component
                      imageUrl: section.image!,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      placeholder: _buildPlaceholder(),
                      errorWidget: _buildErrorWidget(),
                    )
                  : _buildPlaceholder(), // Placeholder if no image URL
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B3A3A).withOpacity(0.8),
            const Color(0xFF8B3A3A).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B3A3A).withOpacity(0.8),
            const Color(0xFF8B3A3A).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              color: Colors.white.withOpacity(0.7),
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              'Изображение недоступно',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }


}
