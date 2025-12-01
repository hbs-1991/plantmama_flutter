import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data like authentication tokens.
/// Uses platform-specific secure storage (Android Keystore / iOS Keychain).
class SecureStorage {
  static SecureStorage? _instance;
  late final FlutterSecureStorage _storage;

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  SecureStorage._internal() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        sharedPreferencesName: 'plantmama_secure_prefs',
        preferencesKeyPrefix: 'plantmama_',
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        accountName: 'PlantMama',
      ),
    );
  }

  static SecureStorage get instance {
    _instance ??= SecureStorage._internal();
    return _instance!;
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Refresh token management
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // User data management
  Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userKey, value: userData);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: _userKey);
  }

  Future<void> deleteUserData() async {
    await _storage.delete(key: _userKey);
  }

  // Clear all secure data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Generic methods for custom keys
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
}
