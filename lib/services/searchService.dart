import 'dart:convert';
import '../models/search_result.dart';
import '../config.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';
import '../utils/http_cache_client.dart';
import './interfaces/i_search_service.dart';

/// Implementation of ISearchService for global search functionality
class SearchService implements ISearchService {
  @override
  Future<SearchResult?> search({
    required String query,
    String type = 'all',
    int limit = 10,
    String? regionCode,
  }) async {
    // Validate query length - return empty result for short queries
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return SearchResult(products: [], collections: [], categories: []);
    }

    try {
      final queryParams = <String, String>{
        'q': trimmedQuery,
        'type': type,
        'limit': limit.toString(),
      };

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/search/')
          .replace(queryParameters: queryParams);

      final headers = AppConfig.withNgrokBypass({
        'Accept': 'application/json',
      });

      if (regionCode != null) {
        headers['X-Region-Code'] = regionCode;
      }

      // Use cached client for search results with short TTL
      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        enableCache: true,
        ttlSeconds: 60, // Cache search results for 1 minute
        cacheAuthorizedRequests: false,
      );

      print('Search response for "$trimmedQuery": ${response.statusCode}');

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          print('SearchService: HTML response from search endpoint');
          return null;
        }

        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'] ?? jsonBody;
        return SearchResult.fromJson(data);
      }

      final appEx = ErrorHandler.handle(
        'HTTP_ERROR',
        response: response,
        context: 'search',
      );
      ErrorReporter.reportNow(appEx);
      return null;
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'search');
      ErrorReporter.reportNow(appEx);
      return null;
    }
  }

  @override
  Future<List<ProductSearchItem>> searchProducts({
    required String query,
    int limit = 20,
    String? regionCode,
  }) async {
    final result = await search(
      query: query,
      type: 'products',
      limit: limit,
      regionCode: regionCode,
    );
    return result?.products ?? [];
  }

  @override
  Future<List<CollectionSearchItem>> searchCollections({
    required String query,
    int limit = 10,
    String? regionCode,
  }) async {
    final result = await search(
      query: query,
      type: 'collections',
      limit: limit,
      regionCode: regionCode,
    );
    return result?.collections ?? [];
  }

  @override
  Future<List<CategorySearchItem>> searchCategories({
    required String query,
    int limit = 10,
    String? regionCode,
  }) async {
    final result = await search(
      query: query,
      type: 'categories',
      limit: limit,
      regionCode: regionCode,
    );
    return result?.categories ?? [];
  }

  bool _looksLikeHtml(String body, Map<String, String> headers) {
    final contentType = headers['content-type'] ?? '';
    return body.trim().startsWith('<!DOCTYPE') ||
        body.trim().startsWith('<html') ||
        contentType.contains('text/html');
  }
}
