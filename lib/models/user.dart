/// User role enumeration matching FastAPI schema.
enum UserRole {
  customer,
  staff,
  admin;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'staff':
        return UserRole.staff;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }

  String toJson() => name;
}

/// User model aligned with FastAPI backend schema.
///
/// API Schema (from api-docs/_common/schemas.yaml):
/// - id: integer (required)
/// - email: string (required)
/// - full_name: string
/// - phone: string
/// - role: enum (customer, staff, admin)
/// - is_active: boolean
/// - is_verified: boolean
/// - created_at: datetime
/// - updated_at: datetime
class User {
  final int id;
  final String email;
  final String fullName;
  final String phone;
  final UserRole role;
  final bool isActive;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    this.fullName = '',
    this.phone = '',
    this.role = UserRole.customer,
    this.isActive = true,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates User from FastAPI JSON response.
  ///
  /// FastAPI response format:
  /// ```json
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "id": 1,
  ///     "email": "user@example.com",
  ///     "full_name": "John Doe",
  ///     "phone": "+1234567890",
  ///     "role": "customer",
  ///     "is_active": true,
  ///     "is_verified": false,
  ///     "created_at": "2024-01-01T00:00:00Z",
  ///     "updated_at": "2024-01-01T00:00:00Z"
  ///   }
  /// }
  /// ```
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      role: UserRole.fromString(json['role']),
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Converts to JSON for FastAPI requests.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role.toJson(),
      'is_active': isActive,
      'is_verified': isVerified,
    };
  }

  /// Converts to JSON for profile update request.
  /// Only includes updatable fields.
  Map<String, dynamic> toUpdateJson() {
    return {
      if (fullName.isNotEmpty) 'full_name': fullName,
      if (phone.isNotEmpty) 'phone': phone,
    };
  }

  static DateTime? _parseDateTime(dynamic dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return null;
    }
  }

  /// Display name for UI (falls back to email prefix).
  String get displayName {
    if (fullName.isNotEmpty) return fullName;
    final atIndex = email.indexOf('@');
    return atIndex > 0 ? email.substring(0, atIndex) : email;
  }

  /// Initials for avatar display.
  String get initials {
    if (fullName.isNotEmpty) {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return fullName[0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? phone,
    UserRole? role,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'User(id: $id, email: $email, fullName: $fullName)';
}

/// Authentication response model for FastAPI login/register.
///
/// FastAPI returns:
/// ```json
/// {
///   "access_token": "...",
///   "refresh_token": "...",
///   "token_type": "bearer",
///   "user_id": 1,
///   "email": "user@example.com",
///   "full_name": "John Doe",
///   "role": "customer"
/// }
/// ```
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int userId;
  final String email;
  final String fullName;
  final UserRole role;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
    required this.userId,
    required this.email,
    this.fullName = '',
    this.role = UserRole.customer,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? json['access'] ?? '',
      refreshToken: json['refresh_token'] ?? json['refresh'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      userId: json['user_id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: UserRole.fromString(json['role']),
    );
  }

  /// Convert to User object for storage.
  User toUser() {
    return User(
      id: userId,
      email: email,
      fullName: fullName,
      role: role,
    );
  }
}

/// Register request model for FastAPI.
///
/// FastAPI expects:
/// ```json
/// {
///   "email": "user@example.com",
///   "password": "securepassword",
///   "full_name": "John Doe",
///   "phone": "+1234567890"
/// }
/// ```
class RegisterRequest {
  final String email;
  final String password;
  final String fullName;
  final String phone;

  const RegisterRequest({
    required this.email,
    required this.password,
    this.fullName = '',
    this.phone = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (fullName.isNotEmpty) 'full_name': fullName,
      if (phone.isNotEmpty) 'phone': phone,
    };
  }
}

/// Login request model for FastAPI.
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}
