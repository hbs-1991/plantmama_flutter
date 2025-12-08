import 'dart:convert';

import '../models/collection.dart';
import '../config.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';
import '../utils/http_cache_client.dart';
import './interfaces/i_collection_service.dart';

/// Implementation of [ICollectionService] for fetching product collections from the API
class CollectionService implements ICollectionService {
  /// Cache TTL for collection list (5 minutes)
  static const int _listCacheTtl = 300;

  /// Cache TTL for collection details (5 minutes)
  static const int _detailsCacheTtl = 300;

  @override
  Future<List<Collection>> getCollections({
    int skip = 0,
    int limit = 20,
    String? search,
    int? sectionId,
    bool? isFeatured,
    bool? inStock,
    double? minPrice,
    double? maxPrice,
    String? regionCode,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sectionId != null) {
        queryParams['section_id'] = sectionId.toString();
      }
      if (isFeatured != null) {
        queryParams['is_featured'] = isFeatured.toString();
      }
      if (inStock != null) {
        queryParams['in_stock'] = inStock.toString();
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice.toString();
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/collections')
          .replace(queryParameters: queryParams);

      final headers = AppConfig.withNgrokBypass({
        'Accept': 'application/json',
      });

      if (regionCode != null) {
        headers['X-Region-Code'] = regionCode;
      }

      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        enableCache: true,
        ttlSeconds: _listCacheTtl,
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          return [];
        }

        final jsonBody = json.decode(response.body);
        // Handle various API response structures
        final data = jsonBody['data'] ?? jsonBody['results'] ?? jsonBody;

        if (data is List) {
          return data.map((c) => Collection.fromJson(c)).toList();
        }

        return [];
      }

      final appEx = ErrorHandler.handle(
        'HTTP_ERROR',
        response: response,
        context: 'getCollections',
      );
      ErrorReporter.reportNow(appEx);
      return [];
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'getCollections');
      ErrorReporter.reportNow(appEx);
      return [];
    }
  }

  @override
  Future<Collection?> getCollectionDetails(
    int collectionId, {
    String? regionCode,
  }) async {
    try {
      final uri =
          Uri.parse('${AppConfig.apiBaseUrl}/collections/$collectionId');

      final headers = AppConfig.withNgrokBypass({
        'Accept': 'application/json',
      });

      if (regionCode != null) {
        headers['X-Region-Code'] = regionCode;
      }

      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        enableCache: true,
        ttlSeconds: _detailsCacheTtl,
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          return null;
        }

        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'] ?? jsonBody;
        return Collection.fromJson(data);
      }

      if (response.statusCode == 404) {
        // Collection not found - not an error condition
        return null;
      }

      final appEx = ErrorHandler.handle(
        'HTTP_ERROR',
        response: response,
        context: 'getCollectionDetails',
      );
      ErrorReporter.reportNow(appEx);
      return null;
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'getCollectionDetails');
      ErrorReporter.reportNow(appEx);
      return null;
    }
  }

  @override
  Future<List<Collection>> getFeaturedCollections({
    int limit = 6,
    String? regionCode,
  }) async {
    return getCollections(
      isFeatured: true,
      limit: limit,
      regionCode: regionCode,
    );
  }

  @override
  Future<List<Collection>> getCollectionsBySection(
    int sectionId, {
    int skip = 0,
    int limit = 20,
    String? regionCode,
  }) async {
    return getCollections(
      sectionId: sectionId,
      skip: skip,
      limit: limit,
      regionCode: regionCode,
    );
  }

  /// Checks if response appears to be HTML instead of JSON
  bool _looksLikeHtml(String body, Map<String, String> headers) {
    final contentType = headers['content-type'] ?? '';
    return body.trim().startsWith('<!DOCTYPE') ||
        body.trim().startsWith('<html') ||
        contentType.contains('text/html');
  }
}
