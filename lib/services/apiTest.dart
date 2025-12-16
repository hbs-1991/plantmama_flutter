import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../utils/http_cache_client.dart';
import '../models/product.dart';
import '../models/section.dart';
import '../models/category.dart';
import '../config.dart';
import '../constants/api_paths.dart';
import './interfaces/i_product_api_service.dart';

class ProductApiService implements IProductApiService {
  static String get _baseUrl => '${AppConfig.apiBaseUrl}${ApiPaths.products}';
  static String get _sectionsUrl => '${AppConfig.apiBaseUrl}${ApiPaths.productSections}';
  static String get _categoriesUrl => '${AppConfig.apiBaseUrl}${ApiPaths.productCategories}';

  Map<String, String> _headers() {
    return AppConfig.withNgrokBypass({
      'Accept': 'application/json',
      'User-Agent': 'PlantMana-Flutter-App/1.0',
    });
  }

  Map<String, String> _headersNgrokBypass() {
    return AppConfig.withNgrokBypass({
      'Accept': 'application/json',
      'User-Agent': 'PlantMana-Flutter-App/1.0',
    });
  }

  bool _looksLikeHtml(String body, Map<String, String> headers) {
    final contentType = (headers['content-type'] ?? headers['Content-Type'] ?? '').toLowerCase();
    
    // Проверяем Content-Type заголовок
    if (contentType.contains('text/html')) {
      print('API - Content-Type указывает на HTML: $contentType');
      return true;
    }
    
    // Если Content-Type указывает на JSON - это точно не HTML
    if (contentType.contains('application/json')) {
      print('API - Content-Type указывает на JSON: $contentType');
      return false;
    }
    
    // Проверяем начало тела ответа
    final trimmedBody = body.trimLeft();
    if (trimmedBody.startsWith('<!doctype') || 
        trimmedBody.startsWith('<html') || 
        trimmedBody.startsWith('<!DOCTYPE') ||
        trimmedBody.startsWith('<HTML')) {
      print('API - Тело ответа начинается с HTML тегов');
      return true;
    }
    
    // Проверяем на наличие ngrok специфичных строк, но только если это не JSON
    if (!contentType.contains('json') && !body.startsWith('{') && !body.startsWith('[')) {
      if (body.contains('ngrok') && 
          (body.contains('ERR_NGROK') ||
           body.contains('browser warning') ||
           body.contains('Page not found') ||
           body.contains('<!DOCTYPE html>'))) {
        print('API - Обнаружены ngrok специфичные строки в HTML ответе');
        return true;
      }
    }
    
    // Проверяем на наличие HTML тегов, но только если это не JSON
    if (!contentType.contains('json') && !body.startsWith('{') && !body.startsWith('[')) {
      if (body.contains('<title>') || 
          body.contains('<head>') || 
          body.contains('<body>') ||
          body.contains('<meta') ||
          body.contains('<script>')) {
        print('API - Обнаружены HTML теги в ответе');
        return true;
      }
    }
    
    // Если ответ начинается с { или [ - это JSON, не HTML
    if (body.startsWith('{') || body.startsWith('[')) {
      print('API - Ответ начинается с JSON символов, это не HTML');
      return false;
    }
    
    return false;
  }

  Future<http.Response> _get(String url, {Duration? timeout, bool forceNgrokBypass = false, int ttlSeconds = 300, bool enableCache = true}) async {
    Uri uri = Uri.parse(url);
    final headers = forceNgrokBypass ? _headersNgrokBypass() : _headers();
    
    // Принудительно применяем ngrok bypass для всех запросов к ngrok
    if (uri.host.contains('ngrok')) {
      headers.addAll({
        'ngrok-skip-browser-warning': 'true',
        'X-Requested-With': 'XMLHttpRequest',
        'Accept': 'application/json, text/plain, */*',
        'Cache-Control': 'no-cache',
      });
    }
    
    if (forceNgrokBypass && AppConfig.enableNgrokBypass) {
      final qp = Map<String, String>.from(uri.queryParameters);
      qp['ngrok-skip-browser-warning'] = 'true';
      uri = uri.replace(queryParameters: qp);
      // На повторе не используем кэш, чтобы не вернуть HTML из кэша
      enableCache = false;
    }
    
    print('API - Выполняем GET запрос: $uri');
    print('API - Заголовки: $headers');
    
    try {
      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        timeout: timeout,
        ttlSeconds: ttlSeconds,
        enableCache: enableCache,
      );
      
      print('API - Получен ответ: ${response.statusCode}');
      print('API - Content-Type: ${response.headers['content-type']}');
      
      // Проверяем, не является ли ответ HTML
      if (_looksLikeHtml(response.body, response.headers)) {
        print('API - Обнаружен HTML ответ, возможно ngrok warning');
        print('API - Первые 200 символов: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }
      
      return response;
    } on TimeoutException {
      print('API - Таймаут запроса к: $uri');
      rethrow;
    } catch (e) {
      print('API - Ошибка запроса к $uri: $e');
      rethrow;
    }
  }

  /// Builds query parameters, excluding null values
  Map<String, String> _buildQueryParams(Map<String, dynamic> params) {
    final result = <String, String>{};
    params.forEach((key, value) {
      if (value != null) {
        result[key] = value.toString();
      }
    });
    return result;
  }

  @override
  Future<List<Product>> getProducts({
    int skip = 0,
    int limit = 100,
    String? search,
    int? sectionId,
    int? categoryId,
    bool? isFeatured,
    bool? inStock,
    double? minPrice,
    double? maxPrice,
    String? regionCode,
  }) async {
    List<Product> allProducts = [];
    int currentSkip = skip;
    const maxPages = 10;
    int pageCount = 0;

    print('API - Начинаем загрузку продуктов с URL: $_baseUrl');

    while (pageCount < maxPages) {
      try {
        final queryParams = _buildQueryParams({
          'skip': currentSkip,
          'limit': limit,
          'search': search,
          'section_id': sectionId,
          'category_id': categoryId,
          'is_featured': isFeatured,
          'in_stock': inStock,
          'min_price': minPrice,
          'max_price': maxPrice,
        });
        final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
        final url = uri.toString();
        print('API - Загружаем страницу продуктов $pageCount: $url');

        // Add region header if provided
        Map<String, String> headers = _headers();
        if (regionCode != null) {
          headers['X-Region-Code'] = regionCode;
        }

        http.Response response = await _get(url, ttlSeconds: 600, enableCache: true);

        print('API RESPONSE for $url: Status ${response.statusCode}');

        if (response.statusCode == 200) {
          // Проверяем Content-Type - если это JSON, то не проверяем на HTML
          final contentType = response.headers['content-type'] ?? '';
          if (contentType.contains('application/json')) {
            print('API - Получен JSON ответ, пропускаем HTML проверку');
          } else if (_looksLikeHtml(response.body, response.headers)) {
            print('API - Получен HTML (ngrok warning). Прерываем загрузку.');
            // Пробуем с принудительным ngrok bypass
            if (pageCount == 0 && AppConfig.enableNgrokBypass) {
              print('API - Пробуем с принудительным ngrok bypass');
              response = await _get(url, forceNgrokBypass: true, ttlSeconds: 600, enableCache: false);
              if (_looksLikeHtml(response.body, response.headers)) {
                print('API - HTML получен даже с bypass, прерываем');
                break;
              }
            } else {
              break;
            }
          }

          try {
            final jsonBody = json.decode(response.body);
            print('API - JSON успешно распарсен для продуктов: ${jsonBody.runtimeType}');

            // FastAPI format: {success: true, data: [...], meta: {...}}
            if (jsonBody is Map<String, dynamic> && jsonBody['data'] is List) {
              final products = List<Product>.from(
                (jsonBody['data'] as List).map((product) => Product.fromJson(product))
              );
              allProducts.addAll(products);
              print('API - Добавлено ${products.length} продуктов с текущей страницы');

              // Check pagination from meta
              final meta = jsonBody['meta'];
              if (meta != null) {
                final totalPages = meta['total_pages'] ?? 1;
                final currentPage = meta['page'] ?? 1;
                print('API - Страница $currentPage из $totalPages');

                if (currentPage >= totalPages || products.isEmpty) {
                  print('API - Достигнута последняя страница');
                  break;
                }
              } else if (products.isEmpty) {
                break;
              }

              currentSkip += limit;
              pageCount++;
            } else {
              print('API - Неожиданная структура ответа для продуктов: ${jsonBody.runtimeType}');
              print('API - Ключи: ${jsonBody is Map ? jsonBody.keys.toList() : 'не Map'}');
              if (jsonBody is Map) {
                print('API - Содержимое: $jsonBody');
              }
              break;
            }
          } catch (e) {
            print('API - Ошибка парсинга JSON для продуктов: $e');
            print('API - Тело ответа: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
            break;
          }
        } else if (response.statusCode == 503) {
          print('API - Сервер недоступен (503) для продуктов');
          break;
        } else {
          print('API - Ошибка HTTP ${response.statusCode} при загрузке продуктов');
          print('API - Тело ответа: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
          break;
        }
      } catch (e) {
        print('API - Ошибка при загрузке продуктов: $e');
        break;
      }
    }

    print('API - Всего загружено продуктов: ${allProducts.length}');

    // Debug: Print first few products to verify section_slug
    if (allProducts.isNotEmpty) {
      print('API - Примеры продуктов:');
      for (var p in allProducts.take(3)) {
        print('  - ${p.name}: section_slug="${p.sectionSlug}", section_name="${p.sectionName}"');
      }
    }

    return allProducts;
  }

  @override
  Future<Product?> getProductById(int id) async {
    try {
      final url = '${AppConfig.apiBaseUrl}${ApiPaths.product(id)}';
      print('API - Загружаем продукт с ID $id по URL: $url');
      
      http.Response response = await _get(url, ttlSeconds: 1800, enableCache: true);
      print('API RESPONSE product $id: Status ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Проверяем Content-Type - если это JSON, то не проверяем на HTML
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          print('API - Получен JSON ответ, пропускаем HTML проверку');
        } else if (_looksLikeHtml(response.body, response.headers)) {
          print('API - Получен HTML (ngrok warning) для продукта $id');
          // Пробуем с принудительным ngrok bypass
          if (AppConfig.enableNgrokBypass) {
            print('API - Пробуем с принудительным ngrok bypass для продукта $id');
            response = await _get(url, forceNgrokBypass: true, ttlSeconds: 1800, enableCache: false);
            if (_looksLikeHtml(response.body, response.headers)) {
              print('API - HTML получен даже с bypass для продукта $id');
              return null;
            }
          } else {
            return null;
          }
        }
        
        try {
          final jsonBody = json.decode(response.body);
          print('API - JSON успешно распарсен для продукта $id: ${jsonBody.runtimeType}');
          
          if (jsonBody is Map<String, dynamic>) {
            final product = Product.fromJson(jsonBody);
            print('API - Успешно загружен продукт: ${product.name}');
            return product;
          } else {
            print('API - Неожиданная структура ответа для продукта $id: ${jsonBody.runtimeType}');
            return null;
          }
        } catch (e) {
          print('API - Ошибка парсинга JSON для продукта $id: $e');
          print('API - Тело ответа: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('API - Продукт с ID $id не найден (404)');
        return null;
      } else if (response.statusCode == 503) {
        print('API - Сервер недоступен (503) для продукта $id');
        return null;
      } else {
        print('API - Ошибка HTTP ${response.statusCode} при загрузке продукта $id');
        print('API - Тело ответа: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        return null;
      }
    } catch (e) {
      print('API - Ошибка при загрузке продукта $id: $e');
      return null;
    }
  }

  @override
  Future<List<Section>> getSections({
    int skip = 0,
    int limit = 50,
    bool? isActive,
    String? regionCode,
  }) async {
    try {
      final queryParams = _buildQueryParams({
        'skip': skip,
        'limit': limit,
        'is_active': isActive,
      });
      final uri = Uri.parse(_sectionsUrl).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final url = uri.toString();
      print('API - Загружаем секции с URL: $url');

      // Add region header if provided
      Map<String, String> headers = _headers();
      if (regionCode != null) {
        headers['X-Region-Code'] = regionCode;
      }

      http.Response response = await _get(url, ttlSeconds: 3600, enableCache: true);
      print('API RESPONSE sections: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        // Проверяем Content-Type - если это JSON, то не проверяем на HTML
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          print('API - Получен JSON ответ, пропускаем HTML проверку');
        } else if (_looksLikeHtml(response.body, response.headers)) {
          print('API - Получен HTML (ngrok warning) для секций, пробуем с bypass');
          // Пробуем с принудительным ngrok bypass
          if (AppConfig.enableNgrokBypass) {
            print('API - Применяем ngrok bypass для секций');
            response = await _get(_sectionsUrl, forceNgrokBypass: true, ttlSeconds: 3600, enableCache: false);
            if (_looksLikeHtml(response.body, response.headers)) {
              print('API - HTML получен даже с bypass, возвращаем пустой список');
              return [];
            }
          } else {
            print('API - Ngrok bypass отключен, возвращаем пустой список');
            return [];
          }
        }

        try {
          final jsonBody = json.decode(response.body);
          print('API - JSON успешно распарсен для секций: ${jsonBody.runtimeType}');

          // FastAPI format: {success: true, data: [...], meta: {...}}
          if (jsonBody is Map<String, dynamic> && jsonBody['data'] is List) {
            final sections = List<Section>.from(
              (jsonBody['data'] as List).map((section) => Section.fromJson(section))
            );
            sections.sort((a, b) => a.order.compareTo(b.order));
            print('API - Успешно загружено ${sections.length} секций');
            for (var s in sections) {
              print('  - Section: ${s.name}, slug: "${s.slug}", id: ${s.id}');
            }
            return sections;
          } else {
            print('API - Неожиданная структура ответа для секций: ${jsonBody.runtimeType}');
            print('API - Ключи: ${jsonBody is Map ? jsonBody.keys.toList() : 'не Map'}');
            if (jsonBody is Map) {
              print('API - Содержимое: $jsonBody');
            }
            return [];
          }
        } catch (e) {
          print('API - Ошибка парсинга JSON для секций: $e');
          print('API - Тело ответа: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
          return [];
        }
      } else if (response.statusCode == 503) {
        print('API - Сервер недоступен (503) для секций');
        return [];
      } else {
        print('API - Ошибка HTTP ${response.statusCode} при загрузке секций');
        print('API - Тело ответа: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        return [];
      }
    } catch (e) {
      print('API - Ошибка при загрузке секций: $e');
      return [];
    }
  }

  @override
  Future<List<Category>> getCategories({
    int skip = 0,
    int limit = 50,
    int? sectionId,
    int? parentId,
    bool? isActive,
    String? regionCode,
  }) async {
    List<Category> allCategories = [];
    int currentSkip = skip;
    const maxPages = 5;
    int pageCount = 0;

    print('API - Начинаем загрузку категорий с URL: $_categoriesUrl');

    while (pageCount < maxPages) {
      try {
        final queryParams = _buildQueryParams({
          'skip': currentSkip,
          'limit': limit,
          'section_id': sectionId,
          'parent_id': parentId,
          'is_active': isActive,
        });
        final uri = Uri.parse(_categoriesUrl).replace(queryParameters: queryParams);
        final url = uri.toString();
        print('API - Загружаем страницу категорий $pageCount: $url');

        // Add region header if provided
        Map<String, String> headers = _headers();
        if (regionCode != null) {
          headers['X-Region-Code'] = regionCode;
        }

        http.Response response = await _get(url, ttlSeconds: 3600, enableCache: true);
        print('API RESPONSE categories for $url: Status ${response.statusCode}');

        if (response.statusCode == 200) {
          // Проверяем Content-Type - если это JSON, то не проверяем на HTML
          final contentType = response.headers['content-type'] ?? '';
          if (contentType.contains('application/json')) {
            print('API - Получен JSON ответ, пропускаем HTML проверку');
          } else if (_looksLikeHtml(response.body, response.headers)) {
            print('API - Получен HTML (ngrok warning) для категорий, пробуем с bypass');
            // Пробуем с принудительным ngrok bypass
            if (pageCount == 0 && AppConfig.enableNgrokBypass) {
              print('API - Применяем ngrok bypass для категорий');
              response = await _get(url, forceNgrokBypass: true, ttlSeconds: 3600, enableCache: false);
              if (_looksLikeHtml(response.body, response.headers)) {
                print('API - HTML получен даже с bypass, прерываем загрузку');
                break;
              }
            } else {
              print('API - Ngrok bypass недоступен, прерываем загрузку');
              break;
            }
          }

          try {
            final jsonBody = json.decode(response.body);
            print('API - JSON успешно распарсен для категорий: ${jsonBody.runtimeType}');

            // FastAPI format: {success: true, data: [...], meta: {...}}
            if (jsonBody is Map<String, dynamic> && jsonBody['data'] is List) {
              final categories = List<Category>.from(
                (jsonBody['data'] as List).map((category) => Category.fromJson(category))
              );
              allCategories.addAll(categories);
              print('API - Добавлено ${categories.length} категорий с текущей страницы');

              // Check pagination from meta
              final meta = jsonBody['meta'];
              if (meta != null) {
                final totalPages = meta['total_pages'] ?? 1;
                final currentPage = meta['page'] ?? 1;
                print('API - Страница $currentPage из $totalPages');

                if (currentPage >= totalPages || categories.isEmpty) {
                  break;
                }
              } else if (categories.isEmpty) {
                break;
              }

              currentSkip += limit;
              pageCount++;
            } else {
              print('API - Неожиданная структура ответа для категорий: ${jsonBody.runtimeType}');
              print('API - Ключи: ${jsonBody is Map ? jsonBody.keys.toList() : 'не Map'}');
              if (jsonBody is Map) {
                print('API - Содержимое: $jsonBody');
              }
              break;
            }
          } catch (e) {
            print('API - Ошибка парсинга JSON для категорий: $e');
            print('API - Тело ответа: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
            break;
          }
        } else if (response.statusCode == 503) {
          print('API - Сервер недоступен (503) для категорий');
          break;
        } else {
          print('API - Ошибка HTTP ${response.statusCode} при загрузке категорий');
          print('API - Тело ответа: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
          break;
        }
      } catch (e) {
        print('API - Ошибка при загрузке категорий: $e');
        break;
      }
    }

    allCategories.sort((a, b) => a.order.compareTo(b.order));
    print('API - Всего загружено категорий: ${allCategories.length}');
    print('API - Парсинг категорий: ${allCategories.map((c) => '${c.name} (ID: ${c.id}, sectionSlug: ${c.sectionSlug})').toList()}');
    return allCategories;
  }
}