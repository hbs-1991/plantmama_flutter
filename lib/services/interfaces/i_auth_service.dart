import 'dart:async';

abstract class IAuthService {
  Future<Map<String, dynamic>?> login(String username, String password);
  Future<Map<String, dynamic>?> loginWithPhone(String phone, String password);
  Future<Map<String, dynamic>?> register(String email, String phone, String password);
  Future<Map<String, dynamic>?> getCurrentUser();
  Future<Map<String, dynamic>?> getUserInfo();
  Future<Map<String, dynamic>?> getSavedUser();
  Future<bool> isLoggedIn();
  Future<void> logout();
  Future<String?> getToken();
  Future<Map<String, dynamic>?> refreshToken();
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<Map<String, dynamic>?> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  });

  Future<Map<String, dynamic>?> updateUsername(String username);

  // Phone registration/login flow
  Future<Map<String, dynamic>?> startPhoneRegistration({
    required String phone,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
  });

  Future<Map<String, dynamic>?> verifyPhoneCode({
    required String phone,
    required String code,
  });

  Future<Map<String, dynamic>?> resendPhoneCode({
    required String phone,
  });

  Future<Map<String, dynamic>?> getPhoneRegistrationStatus({
    required String phone,
  });

  // Address management methods
  Future<List<Map<String, dynamic>>> getUserAddresses();
  Future<Map<String, dynamic>?> addAddress({
    required String label,
    required String streetAddress,
    String? apartment,
    required String city,
    required String postalCode,
    required String country,
    bool isDefault = false,
  });
  Future<Map<String, dynamic>?> updateAddress({
    required int addressId,
    String? streetAddress,
    String? apartment,
    String? city,
    String? postalCode,
    String? country,
    bool? isDefault,
  });
  Future<bool> deleteAddress(int addressId);
}


