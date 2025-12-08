import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/region.dart';
import '../config.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';
import '../utils/http_cache_client.dart';
import './interfaces/i_region_service.dart';

/// Implementation of [IRegionService] with offline caching support
class RegionService implements IRegionService {
  /// Key for storing selected region code
  static const String _regionCodeKey = 'selected_region_code';

  /// Key for caching regions list locally
  static const String _cachedRegionsKey = 'cached_regions';

  /// Cache TTL for regions (1 hour - regions rarely change)
  static const int _regionsCacheTtl = 3600;

  @override
  Future<List<Region>> getRegions({bool? isActive}) async {
    try {
      final queryParams = <String, String>{};
      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/regions').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final headers = AppConfig.withNgrokBypass({
        'Accept': 'application/json',
      });

      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        enableCache: true,
        ttlSeconds: _regionsCacheTtl,
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          return await _getCachedRegions();
        }

        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'] ?? jsonBody['results'] ?? jsonBody;

        if (data is List) {
          final regions = data.map((r) => Region.fromJson(r)).toList();

          // Cache regions locally for offline access
          await _cacheRegions(regions);

          return regions;
        }

        return await _getCachedRegions();
      }

      final appEx = ErrorHandler.handle(
        'HTTP_ERROR',
        response: response,
        context: 'getRegions',
      );
      ErrorReporter.reportNow(appEx);
      return await _getCachedRegions();
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'getRegions');
      ErrorReporter.reportNow(appEx);
      return await _getCachedRegions();
    }
  }

  @override
  Future<Region?> getCurrentRegion({String? regionCode}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/regions/current');

      final headers = AppConfig.withNgrokBypass({
        'Accept': 'application/json',
      });

      // Use provided code or fall back to saved preference
      final code = regionCode ?? await getSavedRegionCode();
      if (code != null) {
        headers['X-Region-Code'] = code;
      }

      final response = await CachedHttpClient.instance.get(
        uri,
        headers: headers,
        enableCache: true,
        ttlSeconds: _regionsCacheTtl,
        cacheAuthorizedRequests: false,
      );

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          // Fall back to finding region in cached list
          if (code != null) {
            return await getRegionByCode(code);
          }
          return null;
        }

        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'] ?? jsonBody;
        return Region.fromJson(data);
      }

      // On error, try to find region in cached list
      if (code != null) {
        return await getRegionByCode(code);
      }
      return null;
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'getCurrentRegion');
      ErrorReporter.reportNow(appEx);

      // Fall back to cached region
      final code = regionCode ?? await getSavedRegionCode();
      if (code != null) {
        return await getRegionByCode(code);
      }
      return null;
    }
  }

  @override
  Future<String?> getSavedRegionCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_regionCodeKey);
  }

  @override
  Future<void> saveRegionCode(String regionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionCodeKey, regionCode);
  }

  @override
  Future<void> clearSavedRegion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_regionCodeKey);
  }

  @override
  Future<Region?> getRegionByCode(String code) async {
    // First check cached regions
    final cachedRegions = await _getCachedRegions();
    for (final region in cachedRegions) {
      if (region.code == code) {
        return region;
      }
    }

    // If not in cache, fetch fresh list and search
    final freshRegions = await getRegions();
    for (final region in freshRegions) {
      if (region.code == code) {
        return region;
      }
    }

    return null;
  }

  /// Caches regions to SharedPreferences for offline access
  Future<void> _cacheRegions(List<Region> regions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = regions.map((r) => json.encode(r.toJson())).toList();
      await prefs.setStringList(_cachedRegionsKey, jsonList);
    } catch (e) {
      // Silently fail - caching is best-effort
      print('RegionService: Failed to cache regions: $e');
    }
  }

  /// Retrieves cached regions from SharedPreferences
  Future<List<Region>> _getCachedRegions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_cachedRegionsKey) ?? [];
      return jsonList.map((s) => Region.fromJson(json.decode(s))).toList();
    } catch (e) {
      // Return empty list if cache is corrupted
      print('RegionService: Failed to read cached regions: $e');
      return [];
    }
  }

  /// Checks if response appears to be HTML instead of JSON
  bool _looksLikeHtml(String body, Map<String, String> headers) {
    final contentType = headers['content-type'] ?? '';
    return body.trim().startsWith('<!DOCTYPE') ||
        body.trim().startsWith('<html') ||
        contentType.contains('text/html');
  }
}
