import 'package:flutter/foundation.dart' show ChangeNotifier;
import '../services/interfaces/i_product_api_service.dart';
import '../di/locator.dart';
import '../models/section.dart';
import '../models/category.dart' as app_models;
import '../models/product.dart';

class ProductsProvider extends ChangeNotifier {
  final IProductApiService _api = locator.get<IProductApiService>();

  bool _isLoadingSections = false;
  bool _isLoadingCategories = false;
  bool _isLoadingProducts = false;

  List<Section> _sections = [];
  List<app_models.Category> _allCategories = [];
  List<Product> _allProducts = [];

  bool get isLoadingSections => _isLoadingSections;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingProducts => _isLoadingProducts;

  List<Section> get sections => List.unmodifiable(_sections);
  List<app_models.Category> get allCategories => List.unmodifiable(_allCategories);
  List<Product> get allProducts => List.unmodifiable(_allProducts);

  Future<void> loadSections() async {
    if (_isLoadingSections) return;
    _isLoadingSections = true;
    notifyListeners();
    try {
      _sections = await _api.getSections();
      _sections.sort((a, b) => a.order.compareTo(b.order));
      
      // Отладочная информация
      print('ProductsProvider: Загружено ${_sections.length} секций');
      for (var section in _sections) {
        print('Секция: ${section.name}, изображение: ${section.image}');
      }
      
      // Если API не вернул данные, ждем еще
      if (_sections.isEmpty) {
        print('ProductsProvider: API не вернул секции, ждем загрузки...');
        // Не используем fallback, ждем реальные данные
      }
    } catch (e) {
      print('ProductsProvider: Ошибка загрузки секций: $e, пробуем еще раз');
      // Не используем fallback, пробуем загрузить снова
    } finally {
      _isLoadingSections = false;
      notifyListeners();
    }
  }

  // Fallback данные для секций больше не используются

  Future<void> loadCategories() async {
    if (_isLoadingCategories) return;
    _isLoadingCategories = true;
    notifyListeners();
    try {
      _allCategories = await _api.getCategories();
      _allCategories.sort((a, b) => a.order.compareTo(b.order));
      
      // Если API не вернул данные, ждем еще
      if (_allCategories.isEmpty) {
        print('ProductsProvider: API не вернул категории, ждем загрузки...');
        // Не используем fallback, ждем реальные данные
      }
    } catch (e) {
      print('ProductsProvider: Ошибка загрузки категорий: $e, пробуем еще раз');
      // Не используем fallback, пробуем загрузить снова
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  // Fallback данные для категорий больше не используются

  Future<void> loadProducts() async {
    if (_isLoadingProducts) return;
    _isLoadingProducts = true;
    notifyListeners();
    try {
      _allProducts = await _api.getProducts();
      
      // Если API не вернул данные, ждем еще
      if (_allProducts.isEmpty) {
        print('ProductsProvider: API не вернул продукты, ждем загрузки...');
        // Не используем fallback, ждем реальные данные
      }
    } catch (e) {
      print('ProductsProvider: Ошибка загрузки продуктов: $e, пробуем еще раз');
      // Не используем fallback, пробуем загрузить снова
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  // Fallback данные для продуктов больше не используются

  Future<void> loadCatalogIfNeeded() async {
    final futures = <Future<void>>[];
    if (_sections.isEmpty && !_isLoadingSections) futures.add(loadSections());
    if (_allCategories.isEmpty && !_isLoadingCategories) futures.add(loadCategories());
    if (_allProducts.isEmpty && !_isLoadingProducts) futures.add(loadProducts());
    if (futures.isNotEmpty) {
      // Убираем таймаут - ждем загрузки столько, сколько нужно
      await Future.wait(futures);
    }
  }

  List<app_models.Category> categoriesForSection(String? sectionSlug) {
    if (sectionSlug == null || sectionSlug.isEmpty) return _allCategories;
    final list = _allCategories.where((c) => c.sectionSlug == sectionSlug).toList();
    // Если передан неизвестный slug (например, 'catalog') — показываем все
    return list.isEmpty ? _allCategories : list;
  }

  List<Product> productsForSection(String? sectionSlug) {
    if (sectionSlug == null || sectionSlug.isEmpty) return _allProducts;
    return _allProducts.where((p) => p.sectionSlug == sectionSlug).toList();
  }

  Future<void> loadCatalog({bool forceRefresh = false}) async {
    if (_isLoadingProducts && !forceRefresh) return;

    _isLoadingProducts = true;
    notifyListeners();

    try {
      print('ProductsProvider: Начинаем загрузку каталога');
      
      int retryCount = 0;
      const maxRetries = 3;
      const retryDelay = Duration(seconds: 2);
      
      while (retryCount < maxRetries) {
        try {
          print('ProductsProvider: Попытка загрузки каталога $retryCount/$maxRetries');
          
          final sections = await _api.getSections();
          print('ProductsProvider: Получено секций: ${sections.length}');
          
          if (sections.isEmpty) {
            print('ProductsProvider: Секции пусты, пробуем еще раз');
            retryCount++;
            if (retryCount < maxRetries) {
              await Future.delayed(retryDelay * retryCount);
              continue;
            }
            throw Exception('Не удалось получить секции после $maxRetries попыток');
          }

          // Загружаем все продукты один раз
          final allProducts = await _api.getProducts();
          print('ProductsProvider: Всего загружено продуктов: ${allProducts.length}');
          
          _sections = sections;
          _allProducts = allProducts;
          _isLoadingProducts = false;
          notifyListeners();
          
          print('ProductsProvider: Каталог успешно загружен');
          return; // Успешно загрузили, выходим из цикла
          
        } catch (e) {
          retryCount++;
          print('ProductsProvider: Ошибка загрузки каталога, попытка $retryCount/$maxRetries: $e');
          
          if (retryCount >= maxRetries) {
            print('ProductsProvider: Не удалось загрузить каталог после $maxRetries попыток');
            throw Exception('Не удалось загрузить каталог. Проверьте соединение и попробуйте снова.');
          }
          
          // Ждем перед следующей попыткой
          await Future.delayed(retryDelay * retryCount);
        }
      }
      
    } catch (e) {
      print('ProductsProvider: Критическая ошибка загрузки каталога: $e');
      _isLoadingProducts = false;
      notifyListeners();
    }
  }
}


