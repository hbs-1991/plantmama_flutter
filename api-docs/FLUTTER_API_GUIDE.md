# PlantMama Store API Guide for Flutter Developers

Complete guide for integrating the PlantMama Store API into Flutter mobile applications.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Authentication](#authentication)
3. [API Client Setup](#api-client-setup)
4. [Common Patterns](#common-patterns)
5. [Error Handling](#error-handling)
6. [Dart Code Examples](#dart-code-examples)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Base URL

```
Production: https://api.plantmama.com/api/v1
Development: http://localhost:8000/api/v1
```

### Required Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  dio: ^5.3.0  # Alternative to http
  flutter_secure_storage: ^9.0.0  # For secure token storage
  shared_preferences: ^2.2.0  # For user preferences
  json_serializable: ^6.6.0  # For JSON serialization
  get_it: ^7.5.0  # For dependency injection

dev_dependencies:
  json_serializable: ^6.6.0
  build_runner: ^2.4.0
```

### Setup for Different Environments

Create separate configuration files for development and production:

**lib/config/api_config.dart**

```dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
```

Build with environment configuration:

```bash
# Development
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1

# Production
flutter run --dart-define=API_BASE_URL=https://api.plantmama.com/api/v1
```

---

## Authentication

### JWT Token Management

The API uses JWT (JSON Web Token) authentication. Tokens are obtained during login/registration and must be included in subsequent requests.

#### Token Lifecycle

- **Access Token**: Expires after 1 hour
- **Refresh Token**: Expires after 30 days
- **Storage**: Use secure storage (not SharedPreferences for sensitive data)

### Secure Token Storage

**lib/services/secure_storage_service.dart**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_available,
    ),
  );

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<void> saveUserEmail(String email) =>
      _storage.write(key: _userEmailKey, value: email);

  Future<void> saveUserId(int userId) =>
      _storage.write(key: _userIdKey, value: userId.toString());

  Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  Future<String?> getUserEmail() =>
      _storage.read(key: _userEmailKey);

  Future<int?> getUserId() async {
    final id = await _storage.read(key: _userIdKey);
    return id != null ? int.parse(id) : null;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }
}
```

---

## API Client Setup

### HTTP Client with Interceptors

**lib/services/api_client.dart**

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

class ApiClient {
  late Dio _dio;
  final SecureStorageService _secureStorage = SecureStorageService();

  ApiClient({
    String baseUrl = 'http://localhost:8000/api/v1',
    String? regionCode = 'TM',
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (regionCode != null) 'X-Region-Code': regionCode,
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  /// Request interceptor - adds auth token to requests
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  /// Response interceptor - handles responses and errors
  Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    return handler.next(response);
  }

  /// Error interceptor - handles 401 and refreshes token
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      // Try to refresh the token
      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken != null) {
          final newTokens = await _refreshAccessToken(refreshToken);
          if (newTokens != null) {
            // Save new tokens
            await _secureStorage.saveAccessToken(newTokens['access_token']);
            await _secureStorage.saveRefreshToken(newTokens['refresh_token']);

            // Retry original request with new token
            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer ${newTokens['access_token']}';

            return handler.resolve(await _dio.request(
              options.path,
              options: options,
            ));
          }
        }
      } catch (e) {
        debugPrint('Token refresh failed: $e');
        await _secureStorage.clearAll();
        // Redirect to login screen
      }
    }

    return handler.next(error);
  }

  /// Refresh access token
  Future<Map<String, dynamic>?> _refreshAccessToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Authorization': null}, // Don't include old auth header
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
    }
    return null;
  }

  // HTTP Methods
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Set region code header
  void setRegionCode(String regionCode) {
    _dio.options.headers['X-Region-Code'] = regionCode;
  }

  /// Update base URL (for testing or multiple environments)
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }
}
```

### Debug Logging Interceptor

```dart
class LoggingInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('==> ${options.method} ${options.path}');
    debugPrint('Headers: ${options.headers}');
    if (options.data != null) {
      debugPrint('Body: ${options.data}');
    }
    return super.onRequest(options, handler);
  }

  @override
  Future<void> onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('<== ${response.statusCode} ${response.requestOptions.path}');
    debugPrint('Response: ${response.data}');
    return super.onResponse(response, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('<== ${err.response?.statusCode} ${err.requestOptions.path}');
    debugPrint('Error: ${err.message}');
    if (err.response?.data != null) {
      debugPrint('Error Body: ${err.response?.data}');
    }
    return super.onError(err, handler);
  }
}
```

---

## Common Patterns

### Standard Response Wrapper

All API responses follow this structure:

```dart
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ErrorDetail? error;
  final PaginationMeta? meta;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      error: json['error'] != null
          ? ErrorDetail.fromJson(json['error'])
          : null,
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'])
          : null,
    );
  }
}

class ErrorDetail {
  final String code;
  final String message;
  final dynamic details;

  ErrorDetail({
    required this.code,
    required this.message,
    this.details,
  });

  factory ErrorDetail.fromJson(Map<String, dynamic> json) {
    return ErrorDetail(
      code: json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? 'An error occurred',
      details: json['details'],
    );
  }
}

class PaginationMeta {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  PaginationMeta({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}
```

### Repository Pattern

**lib/repositories/auth_repository.dart**

```dart
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/secure_storage_service.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _storage = secureStorage;

  /// Register new user
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data['data'];

        // Save tokens
        await _storage.saveAccessToken(data['access_token']);
        await _storage.saveRefreshToken(data['refresh_token']);
        await _storage.saveUserId(data['user_id']);
        await _storage.saveUserEmail(data['email']);

        return User.fromJson(data);
      } else {
        throw Exception('Registration failed');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Login user
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Save tokens and user info
        await _storage.saveAccessToken(data['access_token']);
        await _storage.saveRefreshToken(data['refresh_token']);
        await _storage.saveUserId(data['user_id']);
        await _storage.saveUserEmail(data['email']);

        return User.fromJson(data);
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Password change failed');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _storage.clearAll();
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() =>
      _storage.hasValidTokens();

  Exception _handleDioException(DioException e) {
    if (e.response?.statusCode == 400) {
      final error = e.response?.data['error'];
      if (error != null) {
        return ApiException(
          code: error['code'],
          message: error['message'],
        );
      }
    } else if (e.response?.statusCode == 401) {
      return UnauthorizedException('Invalid credentials');
    } else if (e.response?.statusCode == 422) {
      return ValidationException('Validation failed');
    }

    return NetworkException(e.message ?? 'Unknown error');
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String code;
  final String message;

  ApiException({required this.code, required this.message});

  @override
  String toString() => '$code: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'Unauthorized: $message';
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => 'Validation Error: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'Network Error: $message';
}
```

---

## Error Handling

### API Error Codes

| Code | HTTP Status | Description |
|------|------------|-------------|
| `VALIDATION_ERROR` | 422 | Request validation failed |
| `UNAUTHORIZED` | 401 | Invalid or missing authentication token |
| `FORBIDDEN` | 403 | User lacks permission for this action |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource already exists |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

### Global Error Handler

**lib/services/error_handler.dart**

```dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    } else if (error is ApiException) {
      return error.message;
    } else if (error is UnauthorizedException) {
      return 'Session expired. Please log in again.';
    } else if (error is ValidationException) {
      return 'Please check your input and try again.';
    } else if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  static String _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your network.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Request timeout. Please try again.';
    } else if (e.type == DioExceptionType.unknown) {
      return 'Network error. Please check your connection.';
    }

    if (e.response != null) {
      final errorData = e.response!.data;

      if (errorData is Map && errorData.containsKey('error')) {
        final error = errorData['error'];
        if (error is Map && error.containsKey('message')) {
          return error['message'];
        }
      }
    }

    return 'An error occurred. Please try again.';
  }

  static void showErrorDialog(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

---

## Dart Code Examples

### Complete Authentication Flow

**lib/screens/login_screen.dart**

```dart
import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../models/user.dart';
import '../services/error_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository(
    apiClient: /* get from DI */,
    secureStorage: /* get from DI */,
  );

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepository.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        // Navigate to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (error) {
      setState(() => _errorMessage = ErrorHandler.getErrorMessage(error));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Products Repository and Usage

**lib/repositories/product_repository.dart**

```dart
import '../models/product.dart';
import '../services/api_client.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get paginated list of products
  Future<PaginatedResponse<Product>> getProducts({
    int skip = 0,
    int limit = 20,
    String? search,
    int? sectionId,
    int? categoryId,
    bool? isFeatured,
    bool? inStock,
    Decimal? minPrice,
    Decimal? maxPrice,
  }) async {
    try {
      final response = await _apiClient.get(
        '/products',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (search != null) 'search': search,
          if (sectionId != null) 'section_id': sectionId,
          if (categoryId != null) 'category_id': categoryId,
          if (isFeatured != null) 'is_featured': isFeatured,
          if (inStock != null) 'in_stock': inStock,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
        },
      );

      final data = response.data;
      return PaginatedResponse<Product>(
        items: List<Product>.from(
          (data['data'] as List).map((item) => Product.fromJson(item)),
        ),
        meta: PaginationMeta.fromJson(data['meta']),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get single product details
  Future<Product> getProduct(int productId) async {
    try {
      final response = await _apiClient.get('/products/$productId');
      return Product.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Search products
  Future<List<Product>> searchProducts(String query, {int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/search',
        queryParameters: {
          'q': query,
          'type': 'products',
          'limit': limit,
        },
      );

      return List<Product>.from(
        (response.data['data']['products'] as List)
            .map((item) => Product.fromJson(item)),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    // Handle specific error codes
    if (e.response?.statusCode == 404) {
      throw NotFoundException('Product not found');
    }
    return NetworkException(e.message ?? 'Error fetching products');
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta meta;

  PaginatedResponse({required this.items, required this.meta});

  bool get hasNextPage => meta.page < meta.totalPages;
  int get nextPage => meta.page + 1;
}
```

### Infinite Scroll List with Pagination

**lib/screens/products_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late ProductRepository _productRepository;
  static const _pageSize = 20;

  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _productRepository = ProductRepository(
      apiClient: /* get from DI */,
    );

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newPage = await _productRepository.getProducts(
        skip: pageKey,
        limit: _pageSize,
      );

      final isLastPage = !newPage.hasNextPage;
      if (isLastPage) {
        _pagingController.appendLastPage(newPage.items);
      } else {
        final nextPageKey = pageKey + _pageSize;
        _pagingController.appendPage(newPage.items, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: PagedListView<int, Product>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Product>(
          itemBuilder: (context, product, index) => ProductTile(
            product: product,
            onTap: () => Navigator.of(context).pushNamed(
              '/product/${product.id}',
            ),
          ),
          noItemsFoundIndicatorBuilder: (_) => const Center(
            child: Text('No products found'),
          ),
          firstPageErrorIndicatorBuilder: (_) => Center(
            child: Text('Error: ${_pagingController.error}'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductTile({
    required this.product,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.images.isNotEmpty)
              Image.network(
                product.images.first.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${product.price}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.compareAtPrice != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '\$${product.compareAtPrice}',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (product.inventory != null)
                    Text(
                      product.inventory!.isOutOfStock
                          ? 'Out of Stock'
                          : '${product.inventory!.availableQuantity} in stock',
                      style: TextStyle(
                        color: product.inventory!.isOutOfStock
                            ? Colors.red
                            : Colors.green,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Order Creation Example

**lib/repositories/order_repository.dart**

```dart
import '../models/order.dart';
import '../models/address.dart';
import '../services/api_client.dart';

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Create a new order
  Future<Order> createOrder({
    required String paymentMethod,
    required String deliveryMethod,
    required List<OrderItem> items,
    required int? deliveryAddressId,
    String? deliveryDate,
    String? deliveryTimeSlot,
    String? customerNotes,
    Decimal? discountAmount,
  }) async {
    try {
      final response = await _apiClient.post(
        '/orders',
        data: {
          'payment_method': paymentMethod,
          'delivery_method': deliveryMethod,
          'delivery_address_id': deliveryAddressId,
          'delivery_date': deliveryDate,
          'delivery_time_slot': deliveryTimeSlot,
          'customer_notes': customerNotes,
          'discount_amount': discountAmount ?? 0,
          'items': items.map((item) => item.toJson()).toList(),
        },
      );

      return Order.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's orders
  Future<PaginatedResponse<Order>> getUserOrders({
    int skip = 0,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _apiClient.get(
        '/orders',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );

      final data = response.data;
      return PaginatedResponse<Order>(
        items: List<Order>.from(
          (data['data'] as List).map((item) => Order.fromJson(item)),
        ),
        meta: PaginationMeta.fromJson(data['meta']),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get order details
  Future<Order> getOrder(int orderId) async {
    try {
      final response = await _apiClient.get('/orders/$orderId');
      return Order.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel an order
  Future<void> cancelOrder(int orderId, {String? reason}) async {
    try {
      await _apiClient.post(
        '/orders/$orderId/cancel',
        data: {
          if (reason != null) 'reason': reason,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 400) {
      final error = e.response?.data['error'];
      if (error is Map) {
        throw ApiException(
          code: error['code'] ?? 'ORDER_ERROR',
          message: error['message'] ?? 'Failed to create order',
        );
      }
    }
    return NetworkException(e.message ?? 'Error with order');
  }
}
```

### Cart Management with Validation

**lib/repositories/cart_repository.dart**

```dart
import '../models/cart.dart';
import '../services/api_client.dart';

class CartRepository {
  final ApiClient _apiClient;

  CartRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Validate cart items and calculate totals
  Future<CartValidation> validateCart({
    required List<CartItem> items,
    required String deliveryMethod,
    String? regionCode,
  }) async {
    try {
      final response = await _apiClient.post(
        '/cart/validate',
        data: {
          'items': items.map((item) => item.toJson()).toList(),
          'delivery_method': deliveryMethod,
          if (regionCode != null) 'region_code': regionCode,
        },
      );

      return CartValidation.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Check product availability
  Future<ProductAvailability> checkAvailability(
    int productId, {
    int quantity = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        '/cart/check-availability/$productId',
        queryParameters: {'quantity': quantity},
      );

      return ProductAvailability.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Calculate delivery fee
  Future<DeliveryFee> calculateDeliveryFee({
    required Decimal subtotal,
    required String regionCode,
    String? postalCode,
  }) async {
    try {
      final response = await _apiClient.get(
        '/cart/delivery-fee',
        queryParameters: {
          'subtotal': subtotal.toString(),
          'region_code': regionCode,
          if (postalCode != null) 'postal_code': postalCode,
        },
      );

      return DeliveryFee.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 400) {
      final message = e.response?.data['error']['message'];
      throw ValidationException(message ?? 'Cart validation failed');
    }
    return NetworkException(e.message ?? 'Cart error');
  }
}

class CartValidation {
  final List<CartItemValidation> items;
  final Decimal subtotal;
  final Decimal? estimatedDeliveryFee;
  final bool allItemsAvailable;

  CartValidation({
    required this.items,
    required this.subtotal,
    this.estimatedDeliveryFee,
    required this.allItemsAvailable,
  });

  factory CartValidation.fromJson(Map<String, dynamic> json) {
    return CartValidation(
      items: List<CartItemValidation>.from(
        (json['items'] as List)
            .map((item) => CartItemValidation.fromJson(item)),
      ),
      subtotal: Decimal.parse(json['subtotal'].toString()),
      estimatedDeliveryFee: json['estimated_delivery_fee'] != null
          ? Decimal.parse(json['estimated_delivery_fee'].toString())
          : null,
      allItemsAvailable: json['all_items_available'] ?? false,
    );
  }
}
```

---

## Best Practices

### 1. Token Management

- Always store tokens securely using `FlutterSecureStorage`
- Implement automatic token refresh before expiration
- Clear tokens on logout
- Handle 401 responses gracefully

### 2. Error Handling

- Always wrap API calls in try-catch blocks
- Use custom exception classes for different error scenarios
- Display user-friendly error messages
- Log errors for debugging (in development only)

### 3. State Management

- Use Provider, Riverpod, or Bloc for state management
- Separate data layer (repositories) from UI layer
- Implement proper loading, success, and error states
- Cache data appropriately

### 4. Performance

- Implement pagination for list endpoints
- Use infinite scroll for better UX
- Cache product data where appropriate
- Lazy load images with proper sizing

### 5. Network Best Practices

- Set appropriate timeouts (30 seconds recommended)
- Implement request/response logging in development only
- Use compression for large requests/responses
- Handle network timeouts gracefully

### 6. Security

- Never store sensitive data in SharedPreferences
- Use HTTPS for all API calls
- Implement certificate pinning for production
- Validate all user input before sending

### 7. Code Organization

```
lib/
├── models/          # Data models
├── repositories/    # Data access layer
├── services/        # API client, storage, etc.
├── screens/         # UI screens
├── widgets/         # Reusable widgets
├── providers/       # State management (if using Provider)
├── utils/           # Utility functions
└── config/          # Configuration files
```

---

## Troubleshooting

### Common Issues

**Issue: Token refresh fails and user is logged out unexpectedly**

```dart
// Solution: Ensure refresh token is being saved correctly
Future<void> _refreshAccessToken(String refreshToken) async {
  try {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(headers: {'Authorization': null}),
    );

    if (response.statusCode == 200) {
      // Verify tokens are being saved
      await _secureStorage.saveAccessToken(response.data['access_token']);
      await _secureStorage.saveRefreshToken(response.data['refresh_token']);
      debugPrint('Tokens refreshed successfully');
    }
  } catch (e) {
    // Token refresh failed - force logout
    await _secureStorage.clearAll();
    rethrow;
  }
}
```

**Issue: 401 Unauthorized even with valid token**

```dart
// Solution: Check token format and expiration
Future<bool> _isTokenValid(String token) async {
  try {
    // Parse JWT and check expiration
    final parts = token.split('.');
    if (parts.length != 3) return false;

    final payload = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );

    final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
    return expiry.isAfter(DateTime.now());
  } catch (e) {
    return false;
  }
}
```

**Issue: Images not loading**

```dart
// Solution: Ensure proper image URL handling
Image.network(
  imageUrl,
  errorBuilder: (context, error, stackTrace) => Container(
    color: Colors.grey[300],
    child: const Icon(Icons.error),
  ),
  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          value: progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded /
                  progress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  },
)
```

### Debugging Tips

1. **Enable HTTP Logging**
   ```dart
   // Add to API client initialization
   if (kDebugMode) {
     _dio.interceptors.add(LoggingInterceptor());
   }
   ```

2. **Check Token in Device**
   ```dart
   // View stored tokens (development only)
   final token = await _secureStorage.getAccessToken();
   debugPrint('Access Token: $token');
   ```

3. **Test with Postman**
   - Export API documentation to Postman
   - Test endpoints with valid tokens
   - Verify request/response format

4. **Network Profiling**
   - Use Flutter's DevTools Network tab
   - Monitor request/response sizes
   - Check for excessive API calls

---

## Additional Resources

- [OpenAPI Documentation](../flutter-api-documentation.yaml)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Dio Package](https://pub.dev/packages/dio)
- [Flutter Security Best Practices](https://flutter.dev/docs/platform-integration/web-and-platform-specific-code/native-code)

---

## Support

For API support or issues, please contact: support@plantmama.com
