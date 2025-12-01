import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

/// Secure HTTP client wrapper that enforces HTTPS connections
/// and provides additional security measures.
class SecureHttpClient {
  static SecureHttpClient? _instance;
  static const Duration _defaultTimeout = Duration(seconds: 30);

  SecureHttpClient._internal();

  static SecureHttpClient get instance {
    _instance ??= SecureHttpClient._internal();
    return _instance!;
  }

  /// Validates that the URL uses HTTPS protocol
  /// Throws [SecurityException] if the URL is not HTTPS in production
  void _enforceHttps(Uri uri) {
    if (!kDebugMode && uri.scheme != 'https') {
      AppLogger.error('Attempted HTTP connection blocked: ${uri.toString()}', tag: 'SecureHttpClient');
      throw SecurityException('HTTP connections are not allowed in production. Use HTTPS.');
    }

    if (kDebugMode && uri.scheme != 'https') {
      AppLogger.warning('Using insecure HTTP connection in debug mode: ${uri.toString()}', tag: 'SecureHttpClient');
    }
  }

  /// Gets security headers for all requests
  Map<String, String> _getSecurityHeaders(Map<String, String>? existingHeaders) {
    final headers = <String, String>{
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      ...?existingHeaders,
    };
    return headers;
  }

  /// Performs a secure GET request
  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    _enforceHttps(uri);

    final secureHeaders = _getSecurityHeaders(headers);
    final effectiveTimeout = timeout ?? _defaultTimeout;

    try {
      final response = await http.get(uri, headers: secureHeaders)
          .timeout(effectiveTimeout);

      _logResponse(uri, response.statusCode);
      return response;
    } catch (e) {
      AppLogger.error('Secure GET request failed: ${uri.toString()}', tag: 'SecureHttpClient', error: e);
      rethrow;
    }
  }

  /// Performs a secure POST request
  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    _enforceHttps(uri);

    final secureHeaders = _getSecurityHeaders(headers);
    final effectiveTimeout = timeout ?? _defaultTimeout;

    try {
      final response = await http.post(uri, headers: secureHeaders, body: body)
          .timeout(effectiveTimeout);

      _logResponse(uri, response.statusCode);
      return response;
    } catch (e) {
      AppLogger.error('Secure POST request failed: ${uri.toString()}', tag: 'SecureHttpClient', error: e);
      rethrow;
    }
  }

  /// Performs a secure PUT request
  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    _enforceHttps(uri);

    final secureHeaders = _getSecurityHeaders(headers);
    final effectiveTimeout = timeout ?? _defaultTimeout;

    try {
      final response = await http.put(uri, headers: secureHeaders, body: body)
          .timeout(effectiveTimeout);

      _logResponse(uri, response.statusCode);
      return response;
    } catch (e) {
      AppLogger.error('Secure PUT request failed: ${uri.toString()}', tag: 'SecureHttpClient', error: e);
      rethrow;
    }
  }

  /// Performs a secure DELETE request
  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    _enforceHttps(uri);

    final secureHeaders = _getSecurityHeaders(headers);
    final effectiveTimeout = timeout ?? _defaultTimeout;

    try {
      final response = await http.delete(uri, headers: secureHeaders, body: body)
          .timeout(effectiveTimeout);

      _logResponse(uri, response.statusCode);
      return response;
    } catch (e) {
      AppLogger.error('Secure DELETE request failed: ${uri.toString()}', tag: 'SecureHttpClient', error: e);
      rethrow;
    }
  }

  void _logResponse(Uri uri, int statusCode) {
    AppLogger.api(
      uri.path,
      uri.toString(),
      statusCode: statusCode,
    );
  }
}

/// Exception thrown when a security policy is violated
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

/// Creates an HttpClient with certificate validation
/// Note: Full certificate pinning requires platform-specific implementation
/// This provides basic SSL certificate validation
HttpClient createSecureHttpClient() {
  final client = HttpClient();

  // Enable certificate validation (default behavior)
  client.badCertificateCallback = (X509Certificate cert, String host, int port) {
    // In production, always reject bad certificates
    if (!kDebugMode) {
      AppLogger.error('Bad certificate rejected for $host:$port', tag: 'SecureHttpClient');
      return false;
    }

    // In debug mode, log but still reject by default
    // Change to return true only for specific development environments
    AppLogger.warning('Bad certificate for $host:$port in debug mode', tag: 'SecureHttpClient');
    return false;
  };

  return client;
}
