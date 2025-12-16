import 'package:flutter/foundation.dart';
import '../services/interfaces/i_auth_service.dart';
import '../di/locator.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';

/// Authentication provider for managing user state.
///
/// Aligned with FastAPI backend which uses:
/// - full_name instead of first_name/last_name
/// - access_token/refresh_token instead of access/refresh
class AuthProvider extends ChangeNotifier {
  final IAuthService _authService = locator.get<IAuthService>();
  bool _isChecking = true;
  bool _isLoading = false;
  User? _currentUser;
  bool _isLoggedIn = false;

  bool get isChecking => _isChecking;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;

  Future<void> initialize() async {
    _isChecking = true;
    notifyListeners();
    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        final savedUser = await _authService.getSavedUser();
        if (savedUser != null) {
          _currentUser = User.fromJson(savedUser);
          AppLogger.debug('User loaded from saved data', tag: 'AuthProvider');
        } else {
          AppLogger.debug('No saved data, fetching from server', tag: 'AuthProvider');
          final currentUser = await _authService.getCurrentUser();
          if (currentUser != null) {
            _currentUser = User.fromJson(currentUser);
            AppLogger.debug('User fetched from server', tag: 'AuthProvider');
          } else {
            AppLogger.debug('Failed to get user data, logging out', tag: 'AuthProvider');
            _isLoggedIn = false;
            await _authService.logout();
          }
        }
      } else {
        AppLogger.debug('User not authenticated', tag: 'AuthProvider');
      }
    } catch (e) {
      AppLogger.error('Initialization error', tag: 'AuthProvider', error: e);
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      AppLogger.debug('Starting login for $email', tag: 'AuthProvider');
      final result = await _authService.login(email, password);
      if (result != null) {
        AppLogger.debug('Login successful', tag: 'AuthProvider');
        _isLoggedIn = true;

        // FastAPI returns user data in various formats
        if (result['user'] != null) {
          _currentUser = User.fromJson(result['user']);
        } else {
          // Try to get user from saved data or construct from response
          final savedUser = await _authService.getSavedUser();
          if (savedUser != null) {
            _currentUser = User.fromJson(savedUser);
          } else {
            // Construct User from login response (FastAPI format)
            _currentUser = User(
              id: result['user_id'] ?? result['id'] ?? 0,
              email: result['email'] ?? email,
              fullName: result['full_name'] ?? '',
              phone: result['phone'] ?? '',
              role: UserRole.fromString(result['role']),
            );
          }
        }
        return true;
      }
      AppLogger.debug('Login failed - null result', tag: 'AuthProvider');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String phone, String password) async {
    if (_isLoading) {
      AppLogger.debug('Registration already in progress', tag: 'AuthProvider');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      AppLogger.debug('Starting registration for $email', tag: 'AuthProvider');
      final result = await _authService.register(email, phone, password);

      if (result != null) {
        AppLogger.info('Registration successful', tag: 'AuthProvider');

        // Check for tokens in FastAPI response format
        final hasTokens = result.containsKey('access_token') ||
                          result.containsKey('access') ||
                          result.containsKey('token');

        if (hasTokens) {
          _currentUser = User(
            id: result['user_id'] ?? result['id'] ?? 0,
            email: result['email'] ?? email,
            fullName: result['full_name'] ?? '',
            phone: result['phone'] ?? phone,
            role: UserRole.fromString(result['role']),
          );
          _isLoggedIn = true;
          AppLogger.info('User authenticated after registration', tag: 'AuthProvider');
        } else {
          _currentUser = User(
            id: result['user_id'] ?? result['id'] ?? 0,
            email: result['email'] ?? email,
            fullName: result['full_name'] ?? '',
            phone: result['phone'] ?? phone,
          );
          _isLoggedIn = false;
          AppLogger.info('Registration success, login required', tag: 'AuthProvider');
        }

        return true;
      } else {
        AppLogger.debug('Registration failed - no result', tag: 'AuthProvider');
        return false;
      }
    } catch (e) {
      AppLogger.error('Registration error', tag: 'AuthProvider', error: e);
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

  /// Update user profile.
  ///
  /// FastAPI expects: full_name, phone (no separate first/last name)
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      AppLogger.debug('Updating profile: fullName=$fullName', tag: 'AuthProvider');

      // Map to the auth service which still uses firstName/lastName internally
      // but the API now expects full_name
      final result = await _authService.updateProfile(
        firstName: fullName,  // Service internally sends as full_name
        phone: phone,
      );

      if (result != null) {
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            fullName: result['full_name'] ?? _currentUser!.fullName,
            phone: result['phone'] ?? _currentUser!.phone,
          );
          AppLogger.debug('Profile updated: fullName=${_currentUser!.fullName}', tag: 'AuthProvider');
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Profile update error', tag: 'AuthProvider', error: e);
      return false;
    }
  }

  // Address management methods - delegate to auth service
  Future<List<Map<String, dynamic>>> getUserAddresses() async {
    try {
      return await _authService.getUserAddresses();
    } catch (e) {
      AppLogger.error('Error getting addresses', tag: 'AuthProvider', error: e);
      return [];
    }
  }

  /// Add address using FastAPI schema fields.
  Future<bool> addAddress({
    required String fullName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String postalCode,
    required String country,
    bool isDefault = false,
  }) async {
    try {
      final result = await _authService.addAddress(
        label: fullName,  // Map fullName to label for service compatibility
        streetAddress: addressLine1,
        apartment: addressLine2,
        city: city,
        postalCode: postalCode,
        country: country,
        isDefault: isDefault,
      );

      if (result != null) {
        await _refreshUserData();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error adding address', tag: 'AuthProvider', error: e);
      return false;
    }
  }

  Future<bool> updateAddress({
    required int addressId,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    String? country,
    bool? isDefault,
  }) async {
    try {
      final result = await _authService.updateAddress(
        addressId: addressId,
        streetAddress: addressLine1,
        apartment: addressLine2,
        city: city,
        postalCode: postalCode,
        country: country,
        isDefault: isDefault,
      );

      if (result != null) {
        await _refreshUserData();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error updating address', tag: 'AuthProvider', error: e);
      return false;
    }
  }

  Future<bool> deleteAddress(int addressId) async {
    try {
      final result = await _authService.deleteAddress(addressId);
      if (result) {
        await _refreshUserData();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error deleting address', tag: 'AuthProvider', error: e);
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
      AppLogger.error('Error refreshing user data', tag: 'AuthProvider', error: e);
    }
  }
}
