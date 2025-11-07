import 'dart:async';
import 'dart:convert';


import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class _CacheEntry {
  _CacheEntry({
    required this.body,
    required this.headers,
    required this.statusCode,
    required this.updatedAtEpochMs,
    required this.ttlSeconds,
    this.etag,
    this.lastModified,
    this.compressed = false,
  });

  final String body;
  final Map<String, String> headers;
  final int statusCode;
  final int updatedAtEpochMs;
  final int ttlSeconds;
  final String? etag;
  final String? lastModified;
  final bool compressed;

  bool get isFresh {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - updatedAtEpochMs) <= ttlSeconds * 1000;
  }

  bool get isStale => !isFresh;

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'headers': headers,
        'updatedAtEpochMs': updatedAtEpochMs,
        'ttlSeconds': ttlSeconds,
        'etag': etag,
        'lastModified': lastModified,
        'compressed': compressed,
      };

  static _CacheEntry? fromJson(String bodyRaw, Map<String, dynamic> json) {
    try {
      return _CacheEntry(
        body: bodyRaw,
        headers: (json['headers'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
        statusCode: (json['statusCode'] as num).toInt(),
        updatedAtEpochMs: (json['updatedAtEpochMs'] as num).toInt(),
        ttlSeconds: (json['ttlSeconds'] as num).toInt(),
        etag: json['etag']?.toString(),
        lastModified: json['lastModified']?.toString(),
        compressed: json['compressed'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}

class _PrefsCacheStore {
  static const String _metaPrefix = 'http_cache_v2_meta_';
  static const String _bodyPrefix = 'http_cache_v2_body_';
  static const int _maxCacheSize = 50; // Максимальное количество кешированных запросов

  String _hashKey(String raw) {
    final bytes = utf8.encode(raw);
    return base64Url.encode(bytes);
  }

  Future<_CacheEntry?> read(String cacheKey) async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final hashed = _hashKey(cacheKey);
    final metaStr = prefs.getString('$_metaPrefix$hashed');
    final bodyStr = prefs.getString('$_bodyPrefix$hashed');
      
    if (metaStr == null || bodyStr == null) return null;
      
    try {
      final meta = json.decode(metaStr) as Map<String, dynamic>;
        final entry = _CacheEntry.fromJson(bodyStr, meta);
        
        // Проверяем актуальность кеша
        if (entry != null && entry.isFresh) {
          return entry;
        } else if (entry != null && entry.isStale) {
          // Удаляем устаревший кеш
          await remove(cacheKey);
        }
        
        return null;
    } catch (_) {
        // Удаляем поврежденный кеш
        await remove(cacheKey);
        return null;
      }
    } catch (e) {
      print('CacheStore: Ошибка чтения кеша: $e');
      return null;
    }
  }

  Future<void> write(String cacheKey, _CacheEntry entry) async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final hashed = _hashKey(cacheKey);
      
      // Ограничиваем размер кеша
      await _enforceCacheLimit(prefs);
      
    await prefs.setString('$_metaPrefix$hashed', json.encode(entry.toJson()));
    await prefs.setString('$_bodyPrefix$hashed', entry.body);
    } catch (e) {
      print('CacheStore: Ошибка записи кеша: $e');
    }
  }

  Future<void> remove(String cacheKey) async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final hashed = _hashKey(cacheKey);
    await prefs.remove('$_metaPrefix$hashed');
    await prefs.remove('$_bodyPrefix$hashed');
    } catch (e) {
      print('CacheStore: Ошибка удаления кеша: $e');
    }
  }

  Future<void> clearAll() async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final k in keys) {
      if (k.startsWith(_metaPrefix) || k.startsWith(_bodyPrefix)) {
        await prefs.remove(k);
      }
      }
    } catch (e) {
      print('CacheStore: Ошибка очистки кеша: $e');
    }
  }

  Future<void> _enforceCacheLimit(SharedPreferences prefs) async {
    try {
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((k) => k.startsWith(_metaPrefix)).toList();
      
      if (cacheKeys.length >= _maxCacheSize) {
        // Находим самые старые записи
        final entries = <String, int>{};
        for (final key in cacheKeys) {
          final metaStr = prefs.getString(key);
          if (metaStr != null) {
            try {
              final meta = json.decode(metaStr) as Map<String, dynamic>;
              final updatedAt = meta['updatedAtEpochMs'] as int? ?? 0;
              entries[key] = updatedAt;
            } catch (_) {
              // Удаляем поврежденные записи
              await prefs.remove(key);
            }
          }
        }
        
        // Сортируем по времени обновления и удаляем старые
        final sortedKeys = entries.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        
        final keysToRemove = sortedKeys.take(cacheKeys.length - _maxCacheSize + 1);
        for (final entry in keysToRemove) {
          final hashed = entry.key.replaceFirst(_metaPrefix, '');
          await prefs.remove('$_metaPrefix$hashed');
          await prefs.remove('$_bodyPrefix$hashed');
        }
      }
    } catch (e) {
      print('CacheStore: Ошибка ограничения размера кеша: $e');
    }
  }

  Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      return keys.where((k) => k.startsWith(_metaPrefix)).length;
    } catch (e) {
      print('CacheStore: Ошибка получения размера кеша: $e');
      return 0;
    }
  }
}

class CachedHttpClient {
  static final CachedHttpClient instance = CachedHttpClient._internal();
  CachedHttpClient._internal();

  final _PrefsCacheStore _cacheStore = _PrefsCacheStore();
  final Map<String, _CacheEntry> _memoryCache = {};
  static const int _maxMemoryCacheSize = 20;

  // Константы для настройки
  // Убираем таймаут - ждем загрузки столько, сколько нужно
 // Увеличиваем до 2 минут
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
    bool enableCache = true,
    int ttlSeconds = 300,
    bool cacheAuthorizedRequests = false,
  }) async {
    // Проверяем, можно ли кешировать этот запрос
    if (!enableCache || (!cacheAuthorizedRequests && _hasAuthHeader(headers))) {
      return await _makeRequest(uri, headers: headers, timeout: timeout);
    }

    final cacheKey = _generateCacheKey(uri, headers);
    
    // Проверяем память кеш
    if (_memoryCache.containsKey(cacheKey)) {
      final memoryEntry = _memoryCache[cacheKey]!;
      if (memoryEntry.isFresh) {
        return _createResponseFromCache(memoryEntry);
      } else {
        _memoryCache.remove(cacheKey);
      }
    }

    // Проверяем постоянный кеш
    final cachedEntry = await _cacheStore.read(cacheKey);
    if (cachedEntry != null) {
      // Добавляем в память кеш
      _addToMemoryCache(cacheKey, cachedEntry);
      return _createResponseFromCache(cachedEntry);
    }

    // Делаем запрос с retry логикой
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _makeRequest(
          uri,
          headers: headers,
          timeout: timeout,
        );

        // Кешируем успешные ответы
        if (response.statusCode == 200 && enableCache) {
        final entry = _CacheEntry(
          body: response.body,
            headers: response.headers,
            statusCode: response.statusCode,
          updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
          ttlSeconds: ttlSeconds,
          etag: response.headers['etag'],
          lastModified: response.headers['last-modified'],
        );

          // Сохраняем в память и постоянный кеш
          _addToMemoryCache(cacheKey, entry);
          await _cacheStore.write(cacheKey, entry);
      }

      return response;
      } catch (e) {
        print('CachedHttpClient: Попытка $attempt для $uri: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
      }
      rethrow;
    }
  }

    throw Exception('Не удалось выполнить запрос после $_maxRetries попыток');
  }

  Future<http.Response> _makeRequest(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final client = http.Client();
    try {
      // Применяем ngrok заголовки если это ngrok URL
      Map<String, String> effectiveHeaders = headers ?? {};
      if (uri.host.contains('ngrok-free.app')) {
        effectiveHeaders = AppConfig.withNgrokBypass(effectiveHeaders);
      }
      
      final response = await client.get(
        uri,
        headers: effectiveHeaders,
      );
      
      // Проверяем, не является ли ответ HTML страницей ngrok
      if (response.body.contains('<!DOCTYPE html>') && 
          response.body.contains('ngrok') &&
          response.body.contains('ERR_NGROK_6024')) {
        throw Exception('ngrok требует авторизации или недоступен. Проверьте настройки ngrok.');
      }
      
      return response;
    } finally {
      client.close();
    }
  }

  String _generateCacheKey(Uri uri, Map<String, String>? headers) {
    final key = 'GET:${uri.toString()}';
    if (headers != null && headers.isNotEmpty) {
      final sortedHeaders = headers.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final headersStr = sortedHeaders.map((e) => '${e.key}:${e.value}').join('|');
      return '$key|$headersStr';
    }
    return key;
  }

  bool _hasAuthHeader(Map<String, String>? headers) {
    if (headers == null) return false;
    return headers.containsKey('authorization') || 
           headers.containsKey('Authorization');
  }

  http.Response _createResponseFromCache(_CacheEntry entry) {
    return http.Response(
      entry.body,
      entry.statusCode,
      headers: entry.headers,
    );
  }

  void _addToMemoryCache(String key, _CacheEntry entry) {
    // Ограничиваем размер памяти кеша
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
    _memoryCache[key] = entry;
  }

  // Методы для управления кешем
  Future<void> clearCache() async {
    _memoryCache.clear();
    await _cacheStore.clearAll();
  }

  Future<void> removeFromCache(String cacheKey) async {
    _memoryCache.remove(cacheKey);
    await _cacheStore.remove(cacheKey);
  }

  Future<int> getCacheSize() async {
    return await _cacheStore.getCacheSize();
  }

  int getMemoryCacheSize() {
    return _memoryCache.length;
  }

  // Метод для предварительной загрузки часто используемых данных
  Future<void> preloadCache(List<String> urls, {Map<String, String>? headers}) async {
    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        await get(
          uri,
          headers: headers,
          enableCache: true,
          ttlSeconds: 3600, // 1 час для предзагруженных данных
        );
      } catch (e) {
        print('CachedHttpClient: Ошибка предзагрузки $url: $e');
      }
    }
  }
}


