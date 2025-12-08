import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/http_cache_client.dart';
import '../utils/secure_storage.dart';
import '../config.dart';
import '../utils/password_utils.dart';
import '../utils/input_sanitizer.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';
import '../utils/app_logger.dart';
import './interfaces/i_auth_service.dart';

class AuthService implements IAuthService {
  final SecureStorage _secureStorage = SecureStorage.instance;

  // Убираем таймауты - ждем загрузки столько, сколько нужно
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  @override
  Future<Map<String, dynamic>?> login(String email, String password) async {
    int retryCount = 0;

    while (retryCount < _maxRetries) {
      try {
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

        if (response.statusCode == 200) {
          try {
            final jsonBody = json.decode(response.body);
            final token = jsonBody['access'];
            final refreshToken = jsonBody['refresh'];

            if (token != null) {
              await _saveToken(token);
              await _saveRefreshToken(refreshToken);

              final userInfo = await _getUserInfo(token);
              if (userInfo != null) {
                await _saveUser(userInfo);
                return userInfo;
              }
            }

            throw Exception('Неверный ответ сервера');
          } catch (e) {
            throw Exception('Ошибка обработки ответа сервера');
          }
        } else if (response.statusCode == 401) {
          throw Exception('Неверный email или пароль');
        } else {
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          rethrow;
        }
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
        final sanitizedEmail = InputSanitizer.sanitizeEmail(email);
        final sanitizedPhone = InputSanitizer.sanitizePhone(phone);
        final sanitizedPassword = InputSanitizer.sanitizeString(password, maxLength: 128);

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

        if (response.statusCode == 201) {
          try {
            final jsonBody = json.decode(response.body);
            final token = jsonBody['access'];
            final refreshToken = jsonBody['refresh'];

            if (token != null) {
              await _saveToken(token);
              await _saveRefreshToken(refreshToken);

              final userInfo = await _getUserInfo(token);
              if (userInfo != null) {
                await _saveUser(userInfo);
                return userInfo;
              }
            }

            return {
              'email': sanitizedEmail,
              'phone': sanitizedPhone,
              'message': 'Пользователь успешно зарегистрирован'
            };
          } catch (e) {
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
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          rethrow;
        }
        await Future.delayed(_retryDelay * retryCount);
      }
    }

    throw Exception('Не удалось зарегистрироваться после $_maxRetries попыток');
  }

  // ==== Phone login flow ====
  @override
  Future<Map<String, dynamic>?> loginWithPhone(String phone, String password) async {
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

      // Generate secure password if not provided
      final effectivePassword = password ?? PasswordUtils.generateSecurePassword();

      final body = <String, dynamic>{
        'phone': sanitizedPhone,
        'email': email ?? '$sanitizedPhone@phone.local',
        'password': effectivePassword,
      };

      if (firstName != null && firstName.isNotEmpty) {
        body['first_name'] = InputSanitizer.sanitizeName(firstName, maxLength: 120);
      }
      if (lastName != null && lastName.isNotEmpty) {
        body['last_name'] = InputSanitizer.sanitizeName(lastName, maxLength: 120);
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/register/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;

        // Если регистрация успешна, сразу входим
        try {
          final loginResult = await login(sanitizedPhone, effectivePassword);
          if (loginResult != null) {
            return {
              'status': 'registration_complete',
              'user': loginResult,
              'message': 'Регистрация и вход выполнены успешно'
            };
          }
        } catch (e) {
          // Auto-login failed, return registration result
        }

        return result;
      }

      // Try to parse error
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
  Future<Map<String, dynamic>?> verifyPhoneCode({
    required String phone,
    required String code,
  }) async {
    try {
      final sanitizedPhone = InputSanitizer.sanitizePhone(phone);
      final sanitizedCode = InputSanitizer.sanitizeString(code, maxLength: 6);

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/register-phone-verify/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
        body: json.encode({'phone': sanitizedPhone, 'code': sanitizedCode}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['user'] != null) {
          if (data['access'] != null) {
            await _saveToken(data['access']);
          }
          if (data['refresh'] != null) {
            await _saveRefreshToken(data['refresh']);
          }
          await _saveUser(Map<String, dynamic>.from(data['user'] as Map));
        }
        return data;
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
          body: json.encode({'refresh': refreshToken}),
        );

        if (response.statusCode == 200) {
          final jsonBody = json.decode(response.body);
          final newToken = jsonBody['access'];

          if (newToken != null) {
            await _saveToken(newToken);
            return {'access': newToken};
          }

          throw Exception('Неверный ответ сервера');
        } else if (response.statusCode == 401) {
          await logout();
          throw Exception('Сессия истекла. Войдите снова.');
        } else {
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) rethrow;
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
          return json.decode(response.body);
        } else if (response.statusCode == 401) {
          throw Exception('Пользователь не авторизован');
        } else {
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) rethrow;
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

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/users/me/');
      final baseHeaders = AppConfig.withNgrokBypass({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'User-Agent': 'PlantMana-Flutter-App/1.0',
      });

      if (uri.host.contains('ngrok')) {
        baseHeaders.addAll({
          'ngrok-skip-browser-warning': 'true',
          'X-Requested-With': 'XMLHttpRequest',
        });
      }

      var response = await http.get(uri, headers: baseHeaders).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) {
          final retryHeaders = Map<String, String>.from(baseHeaders)
            ..addAll({'Cache-Control': 'no-cache'});
          response = await http.get(uri, headers: retryHeaders).timeout(const Duration(seconds: 30));
          if (_looksLikeHtml(response.body, response.headers)) {
            return null;
          }
        }

        try {
          return json.decode(response.body);
        } catch (e) {
          return null;
        }
      } else if (response.statusCode == 401) {
        await logout();
        return null;
      }
      return null;
    } catch (e) {
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
      if (token == null) return null;

      final Map<String, dynamic> data = {};
      if (firstName != null) data['first_name'] = InputSanitizer.sanitizeName(firstName, maxLength: 120);
      if (lastName != null) data['last_name'] = InputSanitizer.sanitizeName(lastName, maxLength: 120);
      if (phone != null) data['phone'] = InputSanitizer.sanitizePhone(phone);
      if (address != null) data['address'] = InputSanitizer.sanitizeAddressLine(address, maxLength: 200);

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/users/update_profile/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) return null;
        try {
          return json.decode(response.body);
        } catch (e) {
          return null;
        }
      } else {
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'updateProfile');
        ErrorReporter.reportNow(appEx);
        return null;
      }
    } catch (e) {
      final appEx = ErrorHandler.handle(e, context: 'updateProfile');
      ErrorReporter.reportNow(appEx);
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> updateUsername(String username) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final sanitizedUsername = InputSanitizer.sanitizeString(username, maxLength: 150);
      if (sanitizedUsername.isEmpty) {
        throw Exception('Username не может быть пустым');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/users/update_profile/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode({'username': sanitizedUsername}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) return null;
        try {
          return json.decode(response.body);
        } catch (e) {
          return null;
        }
      } else {
        final appEx = ErrorHandler.handle('HTTP_ERROR', response: response, context: 'updateUsername');
        ErrorReporter.reportNow(appEx);
        return null;
      }
    } catch (e) {
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

      if (safeNew != safeConfirm) return false;

      final validationError = PasswordUtils.getPasswordValidationError(safeNew);
      if (validationError != null) return false;

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
        if (_looksLikeHtml(response.body, response.headers)) return false;
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
    return await _secureStorage.getToken();
  }

  @override
  Future<Map<String, dynamic>?> getSavedUser() async {
    final userData = await _secureStorage.getUserData();
    if (userData != null) {
      try {
        return json.decode(userData);
      } catch (e) {
        AppLogger.error('Failed to decode saved user data', tag: 'AuthService', error: e);
        return null;
      }
    }
    return null;
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final userInfo = await getUserInfo();
      if (userInfo != null) {
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      await logout();
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearAll();
    await CachedHttpClient.instance.clearCache();
    AppLogger.info('User logged out, secure storage cleared', tag: 'AuthService');
  }

  @override
  Future<bool> logoutFromServer() async {
    try {
      final token = await getToken();
      if (token == null) {
        // No token to invalidate, just clear local storage
        await logout();
        return true;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/logout'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      ).timeout(const Duration(seconds: 15));

      // Always clear local storage regardless of server response
      await logout();

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.info('Server logout successful', tag: 'AuthService');
        return true;
      } else {
        AppLogger.warning(
          'Server logout returned ${response.statusCode}, local tokens cleared',
          tag: 'AuthService',
        );
        return false;
      }
    } catch (e) {
      // Fail gracefully - always clear local tokens even if server request fails
      await logout();
      AppLogger.warning(
        'Server logout failed, local tokens cleared: $e',
        tag: 'AuthService',
      );
      return false;
    }
  }

  Future<void> _saveToken(String token) async {
    await _secureStorage.saveToken(token);
  }

  Future<void> _saveRefreshToken(String token) async {
    await _secureStorage.saveRefreshToken(token);
  }

  Future<String?> _getRefreshToken() async {
    return await _secureStorage.getRefreshToken();
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
        return json.decode(response.body);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    await _secureStorage.saveUserData(json.encode(user));
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
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/addresses/'),
        headers: AppConfig.withNgrokBypass({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) return [];

        try {
          final jsonBody = json.decode(response.body);
          if (jsonBody is List) {
            return List<Map<String, dynamic>>.from(jsonBody);
          }
          return [];
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
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
      if (token == null) return null;

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

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/add_address/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) return null;
        try {
          return json.decode(response.body);
        } catch (e) {
          return null;
        }
      }
      return null;
    } catch (e) {
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
      if (token == null) return null;

      final Map<String, dynamic> data = {'address_id': addressId};
      if (streetAddress != null) data['street_address'] = streetAddress;
      if (apartment != null) data['apartment'] = apartment;
      if (city != null) data['city'] = city;
      if (postalCode != null) data['postal_code'] = postalCode;
      if (country != null) data['country'] = country;
      if (isDefault != null) data['is_default'] = isDefault;

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/users/update_address/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (_looksLikeHtml(response.body, response.headers)) return null;
        try {
          return json.decode(response.body);
        } catch (e) {
          return null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> deleteAddress(int addressId) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/users/delete_address/'),
        headers: AppConfig.withNgrokBypass({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
        body: json.encode({'address_id': addressId}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}