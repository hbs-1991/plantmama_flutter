class AppConfig {
  // Компилируемые переменные окружения:
  //   --dart-define=API_BASE_URL=https://example.com/api
  //   --dart-define=APP_ENV=production|staging|development
  //   --dart-define=WEB_ORIGIN=https://app.example.com
  static const String _apiBaseUrlEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://plantmama.cloud/api',
  );

  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String _webOriginEnv = String.fromEnvironment(
    'WEB_ORIGIN',
    defaultValue: 'https://plantmama.cloud',
  );

  // Нормализованный base URL без завершающего слэша
  static String get apiBaseUrl {
    return _apiBaseUrlEnv.endsWith('/')
        ? _apiBaseUrlEnv.substring(0, _apiBaseUrlEnv.length - 1)
        : _apiBaseUrlEnv;
  }

  static String get environment => _appEnv;
  static bool get isProduction => _appEnv.toLowerCase() == 'production';
  static bool get isStaging => _appEnv.toLowerCase() == 'staging';
  static bool get isDevelopment => _appEnv.toLowerCase() == 'development';

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


