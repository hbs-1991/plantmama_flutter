/// Centralized API endpoint paths
/// Based on PlantMama FastAPI backend documentation
///
/// Usage:
/// ```dart
/// Uri.parse('${AppConfig.apiBaseUrl}${ApiPaths.login}')
/// ```
class ApiPaths {
  ApiPaths._(); // Prevent instantiation

  // ============ Authentication ============
  /// POST - Login with email/password, returns access & refresh tokens
  static const String login = '/auth/login';

  /// POST - Refresh access token using refresh token
  static const String tokenRefresh = '/auth/refresh';

  /// POST - Logout and invalidate tokens server-side
  static const String logout = '/auth/logout';

  /// POST - Register new user account
  static const String register = '/auth/register';

  /// POST - Change user password (requires auth)
  static const String changePassword = '/auth/change-password';

  // Legacy phone verification endpoints (if still needed)
  static const String phoneVerify = '/auth/phone-verify';
  static const String phoneResend = '/auth/phone-resend';
  static const String phoneStatus = '/auth/phone-status';

  // ============ User Profile ============
  /// GET - Get current user info
  /// PATCH - Update user profile
  static const String userMe = '/users/me';

  /// GET - Get user addresses
  /// POST - Add new address
  static const String userAddresses = '/users/me/addresses';

  /// GET/PATCH/DELETE - Specific address by ID
  static String userAddress(int addressId) => '/users/me/addresses/$addressId';

  // Legacy endpoints (mapped to new structure)
  static const String updateProfile = '/users/me';
  static const String addAddress = '/users/me/addresses';
  static String updateAddress(int addressId) => '/users/me/addresses/$addressId';
  static String deleteAddress(int addressId) => '/users/me/addresses/$addressId';

  /// POST - Add product to favorites
  static const String addToFavorites = '/users/favorites';

  /// DELETE - Remove product from favorites
  static const String removeFromFavorites = '/users/favorites';

  /// GET - Check if product is in favorites
  static const String isFavorite = '/users/favorites';

  // ============ Products ============
  /// GET - List products with filtering/pagination
  static const String products = '/products';

  /// GET - Get product details by ID
  static String product(int productId) => '/products/$productId';

  /// GET - Get product images
  static String productImages(int productId) => '/products/$productId/images';

  /// GET - List product categories
  static const String productCategories = '/products/categories';

  /// GET - Get category details by ID
  static String productCategory(int categoryId) => '/products/categories/$categoryId';

  /// GET - List product sections
  static const String productSections = '/product-sections';

  /// GET - Get section details by ID
  static String productSection(int sectionId) => '/product-sections/$sectionId';

  /// GET - Get product reviews
  static const String productReviews = '/products/reviews';

  // ============ Collections ============
  /// GET - List collections with filtering/pagination
  static const String collections = '/collections';

  /// GET - Get collection details by ID
  static String collection(int collectionId) => '/collections/$collectionId';

  // ============ Cart ============
  /// POST - Validate cart items before checkout
  static const String cartValidate = '/cart/validate';

  /// GET - Check product availability
  static String cartCheckAvailability(int productId) => '/cart/check-availability/$productId';

  /// GET - Calculate delivery fee based on subtotal and location
  static const String cartDeliveryFee = '/cart/delivery-fee';

  // Legacy cart endpoints (if backend supports them)
  static const String cart = '/cart';
  static const String myCart = '/cart/my_cart';
  static const String cartAddItem = '/cart/add_item';
  static const String cartRemoveItem = '/cart/remove_item';
  static const String cartUpdateItem = '/cart/update_item';
  static const String cartClear = '/cart/clear';

  // ============ Orders ============
  /// GET - List user's orders
  /// POST - Create new order
  static const String orders = '/orders';

  /// GET - Get order details by ID
  static String order(int orderId) => '/orders/$orderId';

  /// POST - Cancel order
  static String cancelOrder(int orderId) => '/orders/$orderId/cancel';

  // Legacy endpoints
  static const String checkout = '/orders';
  static String reorder(int orderId) => '/orders/$orderId/reorder';
  static const String deliveryMethods = '/orders/delivery-methods';
  static const String paymentMethods = '/orders/payment-methods';

  // ============ Reviews ============
  /// GET - List reviews
  static const String reviews = '/reviews';

  /// GET - Get review details by ID
  static String review(int reviewId) => '/reviews/$reviewId';

  // ============ Regions ============
  /// GET - List available regions
  static const String regions = '/regions';

  /// GET - Get current region based on header
  static const String currentRegion = '/regions/current';

  // ============ Search ============
  /// GET - Global search across products, collections, categories
  static const String search = '/search';
}
