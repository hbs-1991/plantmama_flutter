import 'package:flutter/foundation.dart';
import '../services/interfaces/i_auth_service.dart';
import '../di/locator.dart';
import '../models/user.dart'; // Added import for User model

class AuthProvider extends ChangeNotifier {
  final IAuthService _authService = locator.get<IAuthService>();
  bool _isChecking = true;
  bool _isLoading = false;
  User? _currentUser; // Изменяем тип на User?
  bool _isLoggedIn = false;

  bool get isChecking => _isChecking;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser; // Изменяем тип возвращаемого значения

  Future<void> initialize() async {
    _isChecking = true;
    notifyListeners();
    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        final savedUser = await _authService.getSavedUser();
        if (savedUser != null) {
          _currentUser = User.fromJson(savedUser);
          print('AuthProvider: initialize() - пользователь загружен из сохраненных данных');
        } else {
          print('AuthProvider: initialize() - сохраненные данные не найдены, пытаемся получить с сервера');
          final currentUser = await _authService.getCurrentUser();
          if (currentUser != null) {
            _currentUser = User.fromJson(currentUser);
            print('AuthProvider: initialize() - пользователь получен с сервера');
          } else {
            print('AuthProvider: initialize() - не удалось получить данные пользователя, сбрасываем авторизацию');
            _isLoggedIn = false;
            await _authService.logout();
          }
        }
      } else {
        print('AuthProvider: initialize() - пользователь не авторизован');
      }
    } catch (e) {
      print('AuthProvider: initialize() - ошибка инициализации: $e');
      // При ошибке сбрасываем состояние авторизации
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      print('AuthProvider: login() - начинаем вход для $username');
      final result = await _authService.login(username, password);
      if (result != null) {
        print('AuthProvider: login() - вход успешен, результат: $result');
        _isLoggedIn = true;
        if (result['user'] != null) {
          _currentUser = User.fromJson(result['user']);
          print('AuthProvider: login() - пользователь создан из результата');
        } else {
          final savedUser = await _authService.getSavedUser();
          if (savedUser != null) {
            _currentUser = User.fromJson(savedUser);
            print('AuthProvider: login() - пользователь загружен из сохраненных данных');
          }
        }
        print('AuthProvider: login() - вход завершен, isLoggedIn: $_isLoggedIn');
        return true;
      }
      print('AuthProvider: login() - вход не удался, результат null');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String phone, String password) async {
    if (_isLoading) {
      print('AuthProvider: Регистрация уже выполняется, пропускаем');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      print('AuthProvider: Начинаем регистрацию для $email');
      final result = await _authService.register(email, phone, password);

      if (result != null) {
        print('AuthProvider: Регистрация успешна');

        // Проверяем, есть ли токены в результате
        final hasTokens = result.containsKey('access') || result.containsKey('token');

        if (hasTokens) {
          // Если токены есть, устанавливаем пользователя как авторизованного
          _currentUser = User(
            id: result['id'] ?? 0,
            username: result['username'] ?? '',
            email: result['email'] ?? email,
            firstName: result['first_name'] ?? '',
            lastName: result['last_name'] ?? '',
            phone: result['phone'] ?? phone,
            address: result['address'] ?? '',
            dateJoined: result['date_joined'] ?? DateTime.now().toIso8601String(),
            token: result['access'] ?? result['token'],
          );
          _isLoggedIn = true;
          print('AuthProvider: Пользователь авторизован после регистрации');
        } else {
          // Если токенов нет, создаем пользователя без авторизации
          _currentUser = User(
            id: result['id'] ?? 0,
            username: result['username'] ?? '',
            email: result['email'] ?? email,
            firstName: result['first_name'] ?? '',
            lastName: result['last_name'] ?? '',
            phone: result['phone'] ?? phone,
            address: result['address'] ?? '',
            dateJoined: result['date_joined'] ?? DateTime.now().toIso8601String(),
            token: null,
          );
          _isLoggedIn = false;
          print('AuthProvider: Регистрация успешна, но требуется вход для получения токенов');
        }

        return true;
      } else {
        print('AuthProvider: Регистрация не удалась - нет результата');
        return false;
      }
    } catch (e) {
      print('AuthProvider: Ошибка регистрации: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    try {
      print('AuthProvider: updateProfile - начинаем обновление: firstName=$firstName, lastName=$lastName');
      
      final result = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        address: address,
      );

      print('AuthProvider: updateProfile - получен результат: $result');

      if (result != null) {
        // Обновляем локальные данные пользователя
        if (_currentUser != null) {
          print('AuthProvider: updateProfile - обновляем локальные данные');
          print('AuthProvider: updateProfile - старые данные: firstName=${_currentUser!.firstName}, lastName=${_currentUser!.lastName}');
          
          _currentUser = User(
            id: _currentUser!.id,
            username: _currentUser!.username,
            email: _currentUser!.email,
            firstName: result['first_name'] ?? _currentUser!.firstName,
            lastName: result['last_name'] ?? _currentUser!.lastName,
            phone: result['phone'] ?? _currentUser!.phone,
            address: result['address'] ?? _currentUser!.address,
            dateJoined: _currentUser!.dateJoined,
            token: _currentUser!.token,
          );
          
          print('AuthProvider: updateProfile - новые данные: firstName=${_currentUser!.firstName}, lastName=${_currentUser!.lastName}');
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('AuthProvider: Ошибка обновления профиля: $e');
      return false;
    }
  }

  Future<bool> updateUsername(String username) async {
    try {
      final result = await _authService.updateUsername(username);

      if (result != null) {
        // Обновляем локальные данные пользователя
        if (_currentUser != null) {
          _currentUser = User(
            id: _currentUser!.id,
            username: username,
            email: _currentUser!.email,
            firstName: _currentUser!.firstName,
            lastName: _currentUser!.lastName,
            phone: _currentUser!.phone,
            address: _currentUser!.address,
            dateJoined: _currentUser!.dateJoined,
            token: _currentUser!.token,
          );
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('AuthProvider: Ошибка обновления username: $e');
      return false;
    }
  }

  // Address management methods
  Future<List<Map<String, dynamic>>> getUserAddresses() async {
    try {
      return await _authService.getUserAddresses();
    } catch (e) {
      print('AuthProvider: Ошибка получения адресов: $e');
      return [];
    }
  }

  Future<bool> addAddress({
    required String label,
    required String streetAddress,
    String? apartment,
    required String city,
    required String postalCode,
    required String country,
    bool isDefault = false,
  }) async {
    try {
      final result = await _authService.addAddress(
        label: label,
        streetAddress: streetAddress,
        apartment: apartment,
        city: city,
        postalCode: postalCode,
        country: country,
        isDefault: isDefault,
      );

      if (result != null) {
        // Обновляем локальные данные пользователя
        await _refreshUserData();
        return true;
      }
      return false;
    } catch (e) {
      print('AuthProvider: Ошибка добавления адреса: $e');
      return false;
    }
  }

  Future<bool> updateAddress({
    required int addressId,
    String? streetAddress,
    String? apartment,
    String? city,
    String? postalCode,
    String? country,
    bool? isDefault,
  }) async {
    try {
      final result = await _authService.updateAddress(
        addressId: addressId,
        streetAddress: streetAddress,
        apartment: apartment,
        city: city,
        postalCode: postalCode,
        country: country,
        isDefault: isDefault,
      );

      if (result != null) {
        // Обновляем локальные данные пользователя
        await _refreshUserData();
        return true;
      }
      return false;
    } catch (e) {
      print('AuthProvider: Ошибка обновления адреса: $e');
      return false;
    }
  }

  Future<bool> deleteAddress(int addressId) async {
    try {
      final result = await _authService.deleteAddress(addressId);
      if (result) {
        // Обновляем локальные данные пользователя
        await _refreshUserData();
        return true;
      }
      return false;
    } catch (e) {
      print('AuthProvider: Ошибка удаления адреса: $e');
      return false;
    }
  }

  Future<void> _refreshUserData() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        _currentUser = User.fromJson(currentUser);
        notifyListeners();
      }
    } catch (e) {
      print('AuthProvider: Ошибка обновления данных пользователя: $e');
    }
  }
}


