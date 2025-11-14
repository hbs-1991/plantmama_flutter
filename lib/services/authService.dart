import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/http_cache_client.dart';
import '../config.dart';
import '../utils/password_utils.dart';
import '../utils/input_sanitizer.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';
import './interfaces/i_auth_service.dart';

class AuthService implements IAuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  // Убираем таймауты - ждем загрузки столько, сколько нужно
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  @override
  Future<Map<String, dynamic>?> login(String email, String password) async {
    int retryCount = 0;
    
    while (retryCount < _maxRetries) {
      try {
        print('AuthService: Попытка входа $retryCount/$_maxRetries');
        
        final sanitizedEmail = InputSanitizer.sanitizeEmail(email);
        final sanitizedPassword = InputSanitizer.sanitizeString(password, maxLength: 128);

        final response = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/token/'),
          headers: AppConfig.withNgrokBypass({
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          }),
          body: json.encode({
            'email': sanitizedEmail,
            'password': sanitizedPassword,
          }),
        );

        print('Login API RESPONSE: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final jsonBody = json.decode(response.body);
            final token = jsonBody['access'];
            final refreshToken = jsonBody['refresh'];
            
            if (token != null) {
              await _saveToken(token);
              await _saveRefreshToken(refreshToken);
              
              // Получаем информацию о пользователе
              final userInfo = await _getUserInfo(token);
              if (userInfo != null) {
                await _saveUser(userInfo);
                return userInfo;
              }
            }
            
            throw Exception('Неверный ответ сервера');
          } catch (e) {
            print('AuthService: Ошибка парсинга JSON ответа: $e');
            throw Exception('Ошибка обработки ответа сервера');
          }
        } else if (response.statusCode == 401) {
          throw Exception('Неверный email или пароль');
        } else {
          print('AuthService: Неожиданный статус код: ${response.statusCode}');
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          print('AuthService: Ошибка входа после $_maxRetries попыток: $e');
          rethrow;
        }
        
        print('AuthService: Ошибка входа, повторная попытка $retryCount/$_maxRetries: $e');
        await Future.delayed(_retryDelay * retryCount);
      }
    }
    
    throw Exception('Не удалось войти после $_maxRetries попыток');
  }

  @override
  Future<Map<String, dynamic>?> register(String email, String phone, String password) async {
    int retryCount = 0;
    
    while (retryCount < _maxRetries) {
      try {
        print('AuthService: Попытка регистрации $retryCount/$_maxRetries');
        
        final sanitizedEmail = InputSanitizer.sanitizeEmail(email);
        final sanitizedPhone = InputSanitizer.sanitizePhone(phone);
        final sanitizedPassword = InputSanitizer.sanitizeString(password, maxLength: 128);

        // Проверяем сложность пароля
        final passwordError = PasswordUtils.getPasswordValidationError(sanitizedPassword);
        if (passwordError != null) {
          throw Exception(passwordError);
        }

        final response = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/users/register/'),
          headers: AppConfig.withNgrokBypass({
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          }),
          body: json.encode({
            'email': sanitizedEmail,
            'phone': sanitizedPhone,
            'password': sanitizedPassword,
          }),
        );

        print('Register API RESPONSE: ${response.body}');

        if (response.statusCode == 201) {
          try {
            final jsonBody = json.decode(response.body);
            final token = jsonBody['access'];
            final refreshToken = jsonBody['refresh'];
            
            if (token != null) {
              await _saveToken(token);
              await _saveRefreshToken(refreshToken);
              
              // Получаем информацию о пользователе
              final userInfo = await _getUserInfo(token);
              if (userInfo != null) {
                await _saveUser(userInfo);
                return userInfo;
              }
            }
            
            // Если нет токена, но пользователь создан
            return {
              'email': sanitizedEmail,
              'phone': sanitizedPhone,
              'message': 'Пользователь успешно зарегистрирован'
            };
          } catch (e) {
            print('AuthService: Ошибка парсинга JSON ответа: $e');
            // Даже если не удалось распарсить ответ, пользователь создан
            return {
              'email': sanitizedEmail,
              'phone': sanitizedPhone,
              'message': 'Пользователь успешно зарегистрирован'
            };
          }
        } else if (response.statusCode == 400) {
          try {
            final errorBody = json.decode(response.body);
            final detail = errorBody['detail'] ?? 'Неизвестная ошибка';
            throw Exception(detail);
          } catch (e) {
            throw Exception('Ошибка валидации данных');
          }
        } else if (response.statusCode == 409) {
          throw Exception('Пользователь с таким email уже существует');
        } else {
          print('AuthService: Неожиданный статус код: ${response.statusCode}');
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          print('AuthService: Ошибка регистрации после $_maxRetries попыток: $e');
          rethrow;
        }
        
        print('AuthService: Ошибка регистрации, повторная попытка $retryCount/$_maxRetries: $e');
        await Future.delayed(_retryDelay * retryCount);
      }
    }
    
    throw Exception('Не удалось зарегистрироваться после $_maxRetries попыток');
  }

  // ==== Phone login flow ====
  @override
  Future<Map<String, dynamic>?> loginWithPhone(String phone, String password) async {
    // Пока что просто возвращаем null, так как API не поддерживает вход по номеру телефона
    // Вместо этого будем использовать только регистрацию через SMS
    print('❌ loginWithPhone - API не поддерживает вход по номеру телефона');
    throw Exception('Вход по номеру телефона не поддерживается. Используйте регистрацию через SMS.');
  }

  // ==== Phone registration/login flow (per PHON.md) ====
  @override
  Future<Map<String, dynamic>?> startPhoneRegistration({
    required String phone,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
  }) async {
    try {
      final sanitizedPhone = InputSanitizer.sanitizePhone(phone);
      
      // Попробуем использовать обычную регистрацию вместо phone-specific эндпоинта
      final body = <String, dynamic>{
        'phone': sanitizedPhone,
        'email': email ?? '${sanitizedPhone}@temp.com', // Временный email
        'password': password ?? 'temp123456', // Временный пароль
      };
      
      if (firstName != null && firstName.isNotEmpty) body['first_name'] = InputSanitizer.sanitizeName(firstName, maxLength: 120);
      if (lastName != null && lastName.isNotEmpty) body['last_name'] = InputSanitizer.sanitizeName(lastName, maxLength: 120);

      print('🔵 startPhoneRegistration - Пробуем обычную регистрацию:');
      print('URL: ${AppConfig.apiBaseUrl}/users/register/');
      print('Тело запроса: $body');
      print('Заголовки: ${AppConfig.withNgrokBypass({'Content-Type': 'application/json', 'Accept': 'application/json'})}');

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/register/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
        body: json.encode(body),
      );

      print('🔵 startPhoneRegistration - Получен ответ:');
      print('Статус код: ${response.statusCode}');
      print('Заголовки ответа: ${response.headers}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        print('✅ startPhoneRegistration - Успешная регистрация: $result');
        
        // Если регистрация успешна, сразу входим
        try {
          final loginResult = await login(sanitizedPhone, password ?? 'temp123456');
          if (loginResult != null) {
            print('✅ startPhoneRegistration - Автоматический вход выполнен');
            return {
              'status': 'registration_complete',
              'user': loginResult,
              'message': 'Регистрация и вход выполнены успешно'
            };
          }
        } catch (e) {
          print('❌ startPhoneRegistration - Ошибка автоматического входа: $e');
        }
        
        return result;
      }

      // Try to parse error
      try {
        final err = json.decode(response.body);
        print('❌ startPhoneRegistration - Ошибка сервера: $err');
        throw Exception(err['error']?.toString() ?? err.toString());
      } catch (_) {
        print('❌ startPhoneRegistration - Ошибка парсинга ответа, статус: ${response.statusCode}');
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ startPhoneRegistration - Исключение: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> verifyPhoneCode({
    required String phone,
    required String code,
  }) async {
    try {
      final sanitizedPhone = InputSanitizer.sanitizePhone(phone);
      final sanitizedCode = InputSanitizer.sanitizeString(code, maxLength: 6);

      print('🟢 verifyPhoneCode - Отправляем запрос:');
      print('URL: ${AppConfig.apiBaseUrl}/users/register-phone-verify/');
      print('Тело запроса: {"phone": "$sanitizedPhone", "code": "$sanitizedCode"}');
      print('Заголовки: ${AppConfig.withNgrokBypass({'Content-Type': 'application/json', 'Accept': 'application/json'})}');

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/register-phone-verify/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
        body: json.encode({'phone': sanitizedPhone, 'code': sanitizedCode}),
      );

      print('🟢 verifyPhoneCode - Получен ответ:');
      print('Статус код: ${response.statusCode}');
      print('Заголовки ответа: ${response.headers}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('✅ verifyPhoneCode - Успешный ответ: $data');
        
        // If backend returns user and possibly tokens, persist
        if (data['user'] != null) {
          print('💾 Сохраняем данные пользователя: ${data['user']}');
          // Optional: if tokens included
          if (data['access'] != null) {
            print('💾 Сохраняем access token');
            await _saveToken(data['access']);
          }
          if (data['refresh'] != null) {
            print('💾 Сохраняем refresh token');
            await _saveRefreshToken(data['refresh']);
          }
          await _saveUser(Map<String, dynamic>.from(data['user'] as Map));
          print('✅ Данные пользователя сохранены');
        }
        return data;
      }

      try {
        final err = json.decode(response.body);
        print('❌ verifyPhoneCode - Ошибка сервера: $err');
        throw Exception(err['error']?.toString() ?? err.toString());
      } catch (_) {
        print('❌ verifyPhoneCode - Ошибка парсинга ответа, статус: ${response.statusCode}');
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ verifyPhoneCode - Исключение: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> resendPhoneCode({
    required String phone,
  }) async {
    try {
      final sanitizedPhone = InputSanitizer.sanitizePhone(phone);
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/register-phone-resend/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
        body: json.encode({'phone': sanitizedPhone}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      try {
        final err = json.decode(response.body);
        throw Exception(err['error']?.toString() ?? err.toString());
      } catch (_) {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getPhoneRegistrationStatus({
    required String phone,
  }) async {
    try {
      final sanitizedPhone = InputSanitizer.sanitizePhone(phone);
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/register-phone-status/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
        body: json.encode({'phone': sanitizedPhone}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      try {
        final err = json.decode(response.body);
        throw Exception(err['error']?.toString() ?? err.toString());
      } catch (_) {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> refreshToken() async {
    int retryCount = 0;
    
    while (retryCount < _maxRetries) {
      try {
        print('AuthService: Попытка обновления токена $retryCount/$_maxRetries');
        
        final refreshToken = await _getRefreshToken();
        if (refreshToken == null) {
          throw Exception('Refresh токен не найден');
        }

        final response = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/token/refresh/'),
          headers: AppConfig.withNgrokBypass({
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          }),
          body: json.encode({
            'refresh': refreshToken,
          }),
        );

        if (response.statusCode == 200) {
          try {
            final jsonBody = json.decode(response.body);
            final newToken = jsonBody['access'];
            
            if (newToken != null) {
              await _saveToken(newToken);
              return {'access': newToken};
            }
            
            throw Exception('Неверный ответ сервера');
          } catch (e) {
            print('AuthService: Ошибка парсинга JSON ответа: $e');
            throw Exception('Ошибка обработки ответа сервера');
          }
        } else if (response.statusCode == 401) {
          // Refresh токен истек, нужно перелогиниться
          await logout();
          throw Exception('Сессия истекла. Войдите снова.');
        } else {
          print('AuthService: Неожиданный статус код: ${response.statusCode}');
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          print('AuthService: Ошибка обновления токена после $_maxRetries попыток: $e');
          rethrow;
        }
        
        print('AuthService: Ошибка обновления токена, повторная попытка $retryCount/$_maxRetries: $e');
        await Future.delayed(_retryDelay * retryCount);
      }
    }
    
    throw Exception('Не удалось обновить токен после $_maxRetries попыток');
  }

  @override
  Future<Map<String, dynamic>?> getUserInfo() async {
    int retryCount = 0;
    
    while (retryCount < _maxRetries) {
      try {
        print('AuthService: Попытка получения информации о пользователе $retryCount/$_maxRetries');
        
        final token = await getToken();
        if (token == null) {
          throw Exception('Пользователь не авторизован');
        }

        final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/users/me/'),
          headers: AppConfig.withNgrokBypass({
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          }),
        );

        if (response.statusCode == 200) {
          try {
            final jsonBody = json.decode(response.body);
            return jsonBody;
          } catch (e) {
            print('AuthService: Ошибка парсинга JSON ответа: $e');
            throw Exception('Ошибка обработки ответа сервера');
          }
        } else if (response.statusCode == 401) {
          throw Exception('Пользователь не авторизован');
        } else {
          print('AuthService: Неожиданный статус код: ${response.statusCode}');
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          print('AuthService: Ошибка получения информации о пользователе после $_maxRetries попыток: $e');
          rethrow;
        }
        
        print('AuthService: Ошибка получения информации о пользователе, повторная попытка $retryCount/$_maxRetries: $e');
        await Future.delayed(_retryDelay * retryCount);
      }
    }
    
    throw Exception('Не удалось получить информацию о пользователе после $_maxRetries попыток');
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      http.Response response;
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/users/me/');
      final baseHeaders = AppConfig.withNgrokBypass({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'User-Agent': 'PlantMana-Flutter-App/1.0',
      });
      
      // Принудительно применяем ngrok bypass для всех запросов к ngrok
      if (uri.host.contains('ngrok')) {
        baseHeaders.addAll({
          'ngrok-skip-browser-warning': 'true',
          'X-Requested-With': 'XMLHttpRequest',
        });
      }
      
      response = await http.get(uri, headers: baseHeaders).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Проверяем, не является ли ответ HTML (ngrok warning)
        if (_looksLikeHtml(response.body, response.headers)) {
          print('AuthService: Получен HTML-ответ от ngrok при получении пользователя');
          // Пробуем с дополнительными заголовками
          final retryHeaders = Map<String, String>.from(baseHeaders);
          retryHeaders.addAll({
            'ngrok-skip-browser-warning': 'true',
            'X-Requested-With': 'XMLHttpRequest',
            'Cache-Control': 'no-cache',
          });
          
          response = await http.get(uri, headers: retryHeaders).timeout(const Duration(seconds: 30));
          if (_looksLikeHtml(response.body, response.headers)) {
            print('AuthService: HTML получен даже с retry, возвращаем null');
            return null;
          }
        }
        
        try {
          final jsonBody = json.decode(response.body);
          return jsonBody;
        } catch (e) {
          print('AuthService: Ошибка парсинга JSON ответа: $e');
          return null;
        }
      } else if (response.statusCode == 401) {
        print('AuthService: Токен недействителен (401)');
        await logout();
        return null;
      } else {
        print('AuthService: Неожиданный статус код: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('AuthService: Ошибка получения текущего пользователя: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('AuthService: updateProfile - токен не найден');
        return null;
      }

      final Map<String, dynamic> data = {};
      if (firstName != null) data['first_name'] = InputSanitizer.sanitizeName(firstName, maxLength: 120);
      if (lastName != null) data['last_name'] = InputSanitizer.sanitizeName(lastName, maxLength: 120);
      if (phone != null) data['phone'] = InputSanitizer.sanitizePhone(phone);
      if (address != null) data['address'] = InputSanitizer.sanitizeAddressLine(address, maxLength: 200);

      print('AuthService: updateProfile - отправляем данные: $data');

      // Проверяем доступность API
      print('AuthService: updateProfile - проверяем доступность API: ${AppConfig.apiBaseUrl}');
      
      print('AuthService: updateProfile - отправляем запрос на ${AppConfig.apiBaseUrl}/users/update_profile/');
      print('AuthService: updateProfile - заголовки: ${AppConfig.withNgrokBypass({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token.substring(0, 10)}...',
        'Accept': 'application/json',
      })}');
      
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/users/update_profile/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 15)); // Уменьшаем таймаут до 15 секунд

      print('AuthService: updateProfile - статус ответа: ${response.statusCode}');
      print('AuthService: updateProfile - тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        // Проверяем, не является ли ответ HTML (ngrok warning)
        if (_looksLikeHtml(response.body, response.headers)) {
          print('AuthService: Получен HTML-ответ от ngrok при обновлении профиля');
          return null;
        }

        try {
          final jsonBody = json.decode(response.body);
          print('AuthService: updateProfile - успешно обновлен профиль: $jsonBody');
          return jsonBody;
        } catch (e) {
          print('AuthService: updateProfile - ошибка парсинга JSON: $e');
          return null;
        }
      } else {
        print('AuthService: updateProfile - ошибка HTTP: ${response.statusCode}');
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'updateProfile');
        ErrorReporter.reportNow(appEx);
        return null;
      }
    } catch (e) {
      print('AuthService: updateProfile - исключение: $e');
      print('AuthService: updateProfile - тип исключения: ${e.runtimeType}');
      
      if (e.toString().contains('TimeoutException')) {
        print('AuthService: updateProfile - ТАЙМАУТ! API не отвечает в течение 15 секунд');
        print('AuthService: updateProfile - Возможные причины:');
        print('AuthService: updateProfile - 1. API недоступен');
        print('AuthService: updateProfile - 2. Медленное соединение');
        print('AuthService: updateProfile - 3. Проблемы с ngrok');
      }
      
      final appEx = ErrorHandler.handle(e, context: 'updateProfile');
      ErrorReporter.reportNow(appEx);
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> updateUsername(String username) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('AuthService: updateUsername - токен не найден');
        return null;
      }

      final sanitizedUsername = InputSanitizer.sanitizeString(username, maxLength: 150);
      
      if (sanitizedUsername.isEmpty) {
        throw Exception('Username не может быть пустым');
      }

      print('AuthService: updateUsername - отправляем username: $sanitizedUsername');

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/users/update_profile/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode({
          'username': sanitizedUsername,
        }),
      ).timeout(const Duration(seconds: 30));

      print('AuthService: updateUsername - статус ответа: ${response.statusCode}');
      print('AuthService: updateUsername - тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        // Проверяем, не является ли ответ HTML (ngrok warning)
        if (_looksLikeHtml(response.body, response.headers)) {
          print('AuthService: Получен HTML-ответ от ngrok при обновлении username');
          return null;
        }

        try {
          final jsonBody = json.decode(response.body);
          print('AuthService: updateUsername - успешно обновлен username: $jsonBody');
          return jsonBody;
        } catch (e) {
          print('AuthService: updateUsername - ошибка парсинга JSON: $e');
          return null;
        }
      } else {
        print('AuthService: updateUsername - ошибка HTTP: ${response.statusCode}');
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'updateUsername');
        ErrorReporter.reportNow(appEx);
        return null;
      }
    } catch (e) {
      print('AuthService: updateUsername - исключение: $e');
      final appEx = ErrorHandler.handle(e, context: 'updateUsername');
      ErrorReporter.reportNow(appEx);
      return null;
    }
  }

  @override
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final safeOld = InputSanitizer.sanitizePassword(oldPassword);
      final safeNew = InputSanitizer.sanitizePassword(newPassword);
      final safeConfirm = InputSanitizer.sanitizePassword(confirmPassword);

      if (safeNew != safeConfirm) {
        print('AuthService: Пароли не совпадают');
        return false;
      }

      final validationError = PasswordUtils.getPasswordValidationError(safeNew);
      if (validationError != null) {
        print('AuthService: $validationError');
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/change_password/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode({
          'old_password': safeOld,
          'new_password': safeNew,
          'confirm_password': safeConfirm,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Проверяем, не является ли ответ HTML (ngrok warning)
        if (_looksLikeHtml(response.body, response.headers)) {
          print('AuthService: Получен HTML-ответ от ngrok при смене пароля');
          return false;
        }
        return true;
      } else {
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'changePassword');
        ErrorReporter.reportNow(appEx);
        return false;
      }
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'changePassword');
      ErrorReporter.reportNow(appEx);
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token;
  }

  @override
  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      try {
        return json.decode(userData);
      } catch (e) {
        print('AuthService: Ошибка декодирования сохраненного пользователя: $e');
        return null;
      }
    }
    return null;
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) {
      print('AuthService: isLoggedIn() - токен не найден');
      return false;
    }

    // Проверяем валидность токена, пытаясь получить информацию о пользователе
    try {
      final userInfo = await getUserInfo();
      if (userInfo != null) {
        print('AuthService: isLoggedIn() - токен валиден');
        return true;
      } else {
        print('AuthService: isLoggedIn() - токен не валиден, очищаем данные');
        await logout();
        return false;
      }
    } catch (e) {
      print('AuthService: isLoggedIn() - ошибка проверки токена: $e');
      // При ошибке считаем, что токен не валиден
      await logout();
      return false;
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
    // Чистим HTTP-кэш при выходе
    await CachedHttpClient.instance.clearCache();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('AuthService: _saveToken() - токен сохранен: ${token.substring(0, 10)}...');
  }

  Future<void> _saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<Map<String, dynamic>?> _getUserInfo(String token) async {
    final response = await http.get(
              Uri.parse('${AppConfig.apiBaseUrl}/users/me/'),
      headers: AppConfig.withNgrokBypass({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }),
    );

    if (response.statusCode == 200) {
      try {
        final jsonBody = json.decode(response.body);
        return jsonBody;
      } catch (e) {
        print('AuthService: Ошибка парсинга JSON ответа при получении пользователя: $e');
        return null;
      }
    } else {
      print('AuthService: Неожиданный статус код при получении пользователя: ${response.statusCode}');
      return null;
    }
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user));
  }

  bool _looksLikeHtml(String body, Map<String, String> headers) {
    final contentType = headers['content-type'] ?? '';
    return body.trim().startsWith('<!DOCTYPE') || 
           body.trim().startsWith('<html') ||
           contentType.contains('text/html');
  }

  // Address management methods
  @override
  Future<List<Map<String, dynamic>>> getUserAddresses() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('AuthService: getUserAddresses - токен не найден');
        return [];
      }

      print('AuthService: getUserAddresses - запрашиваем адреса пользователя');

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/addresses/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      ).timeout(const Duration(seconds: 30));

      print('AuthService: getUserAddresses - статус ответа: ${response.statusCode}');
      print('AuthService: getUserAddresses - тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          print('AuthService: getUserAddresses - получен HTML-ответ от ngrok');
          return [];
        }

        try {
          final jsonBody = json.decode(response.body);
          if (jsonBody is List) {
            print('AuthService: getUserAddresses - получено ${jsonBody.length} адресов');
            return List<Map<String, dynamic>>.from(jsonBody);
          } else {
            print('AuthService: getUserAddresses - неожиданный формат ответа: $jsonBody');
            return [];
          }
        } catch (e) {
          print('AuthService: getUserAddresses - ошибка парсинга JSON: $e');
          return [];
        }
      } else {
        print('AuthService: getUserAddresses - ошибка HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('AuthService: getUserAddresses - исключение: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> addAddress({
    required String label,
    required String streetAddress,
    String? apartment,
    required String city,
    required String postalCode,
    required String country,
    bool isDefault = false,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('AuthService: addAddress - токен не найден');
        return null;
      }

      final data = {
        'label': label,
        'street_address': streetAddress,
        'city': city,
        'postal_code': postalCode,
        'country': country,
        'is_default': isDefault,
      };

      if (apartment != null && apartment.isNotEmpty) {
        data['apartment'] = apartment;
      }

      print('AuthService: addAddress - отправляем данные: $data');

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/add_address/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));

      print('AuthService: addAddress - статус ответа: ${response.statusCode}');
      print('AuthService: addAddress - тело ответа: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          print('AuthService: addAddress - получен HTML-ответ от ngrok');
          return null;
        }

        try {
          final jsonBody = json.decode(response.body);
          print('AuthService: addAddress - адрес успешно добавлен: $jsonBody');
          return jsonBody;
        } catch (e) {
          print('AuthService: addAddress - ошибка парсинга JSON: $e');
          return null;
        }
      } else {
        print('AuthService: addAddress - ошибка HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('AuthService: addAddress - исключение: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> updateAddress({
    required int addressId,
    String? streetAddress,
    String? apartment,
    String? city,
    String? postalCode,
    String? country,
    bool? isDefault,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('AuthService: updateAddress - токен не найден');
        return null;
      }

      final Map<String, dynamic> data = {'address_id': addressId};
      if (streetAddress != null) data['street_address'] = streetAddress;
      if (apartment != null) data['apartment'] = apartment;
      if (city != null) data['city'] = city;
      if (postalCode != null) data['postal_code'] = postalCode;
      if (country != null) data['country'] = country;
      if (isDefault != null) data['is_default'] = isDefault;

      print('AuthService: updateAddress - отправляем данные: $data');

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/users/update_address/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));

      print('AuthService: updateAddress - статус ответа: ${response.statusCode}');
      print('AuthService: updateAddress - тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          print('AuthService: updateAddress - получен HTML-ответ от ngrok');
          return null;
        }

        try {
          final jsonBody = json.decode(response.body);
          print('AuthService: updateAddress - адрес успешно обновлен: $jsonBody');
          return jsonBody;
        } catch (e) {
          print('AuthService: updateAddress - ошибка парсинга JSON: $e');
          return null;
        }
      } else {
        print('AuthService: updateAddress - ошибка HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('AuthService: updateAddress - исключение: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteAddress(int addressId) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('AuthService: deleteAddress - токен не найден');
        return false;
      }

      print('AuthService: deleteAddress - удаляем адрес с ID: $addressId');

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/users/delete_address/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode({'address_id': addressId}),
      ).timeout(const Duration(seconds: 30));

      print('AuthService: deleteAddress - статус ответа: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('AuthService: deleteAddress - адрес успешно удален');
        return true;
      } else {
        print('AuthService: deleteAddress - ошибка HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('AuthService: deleteAddress - исключение: $e');
      return false;
    }
  }
}