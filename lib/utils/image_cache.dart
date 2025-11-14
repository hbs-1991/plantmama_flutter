import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class ImageCache {
  static const String _cacheKey = 'product_images_cache';
  static const int _maxCacheSize = 50; // Maximum number of cached images

  // Save image bytes for a product
  static Future<void> saveProductImage(int productId, Uint8List imageBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = await _loadCache();

      // Add or update the image
      cache[productId.toString()] = base64Encode(imageBytes);

      // Limit cache size - remove oldest entries if needed
      if (cache.length > _maxCacheSize) {
        final keysToRemove = cache.keys.take(cache.length - _maxCacheSize).toList();
        for (final key in keysToRemove) {
          cache.remove(key);
        }
      }

      await _saveCache(cache);
      print('ImageCache: Saved image for product $productId (${imageBytes.length} bytes)');
    } catch (e) {
      print('ImageCache: Error saving image for product $productId: $e');
    }
  }

  // Load image bytes for a product
  static Future<Uint8List?> loadProductImage(int productId) async {
    try {
      final cache = await _loadCache();
      final encoded = cache[productId.toString()];
      if (encoded != null) {
        final bytes = base64Decode(encoded);
        print('ImageCache: Found cached image for product $productId (${bytes.length} bytes)');
        return bytes;
      } else {
        print('ImageCache: No cached image found for product $productId');
      }
    } catch (e) {
      print('ImageCache: Error loading image for product $productId: $e');
    }
    return null;
  }

  // Download and cache image from URL
  static Future<Uint8List?> downloadAndCacheImage(int productId, String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return null;

      // Check if already cached
      final cached = await loadProductImage(productId);
      if (cached != null) {
        return cached;
      }

      // Download image
      final uri = Uri.parse(imageUrl);
      if (uri.scheme == 'http' && uri.host.contains('ngrok-free.app')) {
        uri.replace(scheme: 'https');
      }

      final headers = AppConfig.withNgrokBypass({
        'Accept': 'image/*',
        'User-Agent': 'PlantMana-Flutter-App/1.0',
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await saveProductImage(productId, bytes);
        print('ImageCache: Downloaded and cached image for product $productId');
        return bytes;
      }
    } catch (e) {
      print('ImageCache: Error downloading image for product $productId: $e');
    }
    return null;
  }

  // Clear all cached images
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      print('ImageCache: Cache cleared');
    } catch (e) {
      print('ImageCache: Error clearing cache: $e');
    }
  }

  // Load cache from shared preferences
  static Future<Map<String, String>> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        final decoded = json.decode(jsonString);
        return Map<String, String>.from(decoded);
      }
    } catch (e) {
      print('ImageCache: Error loading cache: $e');
    }
    return {};
  }

  // Save cache to shared preferences
  static Future<void> _saveCache(Map<String, String> cache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(cache);
      await prefs.setString(_cacheKey, jsonString);
    } catch (e) {
      print('ImageCache: Error saving cache: $e');
    }
  }
}