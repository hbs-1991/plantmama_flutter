import 'package:flutter/foundation.dart';

/// Application logger that only outputs in debug mode.
/// Use this instead of print() statements throughout the app.
class AppLogger {
  static const String _tag = 'PlantMama';

  /// Log debug information (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }

  /// Log info messages (only in debug mode)
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] INFO: $message');
    }
  }

  /// Log warning messages (only in debug mode)
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] WARNING: $message');
    }
  }

  /// Log error messages (always logged, uses debugPrint for safety)
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    debugPrint('[$_tag${tag != null ? ':$tag' : ''}] ERROR: $message');
    if (error != null) {
      debugPrint('[$_tag] Exception: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('[$_tag] StackTrace: $stackTrace');
    }
  }

  /// Log API request/response (only in debug mode)
  static void api(String method, String url, {int? statusCode, String? body}) {
    if (kDebugMode) {
      debugPrint('[$_tag:API] $method $url');
      if (statusCode != null) {
        debugPrint('[$_tag:API] Status: $statusCode');
      }
      if (body != null && body.length < 500) {
        debugPrint('[$_tag:API] Body: $body');
      }
    }
  }
}
