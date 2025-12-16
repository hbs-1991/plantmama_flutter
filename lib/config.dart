import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for platform detection
import 'config_platform_stub.dart'
    if (dart.library.io) 'config_platform_io.dart' as platform_helper;

class AppConfig {
  // Компилируемые переменные окружения:
  //   --dart-define=API_BASE_URL=https://example.com/api
  //   --dart-define=APP_ENV=production|staging|development
  //   --dart-define=WEB_ORIGIN=https://app.example.com
  static const String _apiBaseUrlEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '', // Empty means auto-detect for development
  );

  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String _webOriginEnv = String.fromEnvironment(
    'WEB_ORIGIN',
    defaultValue: 'https://plantmama.cloud',
  );

  // Local backend port for development
  static const int _localBackendPort = 8000;

  // API version prefix
  static const String _apiVersion = '/api/v1';

  // Get the appropriate localhost URL based on platform
  static String get _localBackendUrl {
    if (kIsWeb) {
      // Web browser - use localhost directly
      return 'http://localhost:$_localBackendPort$_apiVersion';
    }
    // Use platform helper for mobile/desktop
    return platform_helper.getLocalBackendUrl(_localBackendPort, _apiVersion);
  }

  // Нормализованный base URL без завершающего слэша
  static String get apiBaseUrl {
    String url;

    if (_apiBaseUrlEnv.isEmpty) {
      // No URL provided - use local backend for development, production for release
      if (isDevelopment) {
        url = _localBackendUrl;
      } else {
        url = 'https://plantmama.cloud/api/v1';
      }
    } else {
      url = _apiBaseUrlEnv;
    }

    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get environment => _appEnv;
  static bool get isProduction => _appEnv.toLowerCase() == 'production';
  static bool get isStaging => _appEnv.toLowerCase() == 'staging';
  static bool get isDevelopment => _appEnv.toLowerCase() == 'development';

  // Debug helper to print current configuration
  static void printConfig() {
    print('=== AppConfig ===');
    print('Environment: $environment');
    print('API Base URL: $apiBaseUrl');
    print('Is Production: $isProduction');
    print('Is Development: $isDevelopment');
    print('Is Web: $kIsWeb');
    print('=================');
  }

  static bool get enableNgrokBypass {
    return false; // Отключено по запросу пользователя
  }

  static String get webOrigin => _webOriginEnv;

  // Вспомогательный метод для условного добавления ngrok-заголовка
  static Map<String, String> withNgrokBypass(Map<String, String> headers) {
    if (!enableNgrokBypass) return headers;

    final result = Map<String, String>.from(headers);

    // Основной заголовок для пропуска страницы предупреждения ngrok
    result['ngrok-skip-browser-warning'] = 'true';

    // Дополнительные заголовки для лучшей совместимости с ngrok
    result['Accept'] = 'application/json, text/plain, */*';
    result['User-Agent'] = 'PlantMana-Flutter-App/1.0';

    // Заголовки для обхода CORS и других ограничений ngrok
    result['X-Requested-With'] = 'XMLHttpRequest';
    result['X-Forwarded-Proto'] = 'https';

    // Дополнительные заголовки для стабильности
    result['Cache-Control'] = 'no-cache';
    result['Pragma'] = 'no-cache';

    return result;
  }

  // Специальный метод для изображений
  static Map<String, String> withImageHeaders(Map<String, String> headers) {
    final result = Map<String, String>.from(headers);

    if (enableNgrokBypass) {
      result['ngrok-skip-browser-warning'] = 'true';
      result['X-Requested-With'] = 'XMLHttpRequest';
    }

    result['Accept'] = 'image/*, */*';
    result['User-Agent'] = 'PlantMana-Flutter-App/1.0';
    result['Cache-Control'] = 'no-cache';

    return result;
  }

  // Проверяем, является ли URL ngrok
  static bool isNgrokUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('ngrok');
    } catch (_) {
      return false;
    }
  }
}
