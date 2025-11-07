import '../services/interfaces/i_auth_service.dart';
import '../services/interfaces/i_order_service.dart';
import '../services/interfaces/i_cart_service.dart';
import '../services/interfaces/i_address_service.dart';
import '../services/interfaces/i_product_api_service.dart';
import '../services/interfaces/i_review_service.dart';
import '../services/authService.dart';
import '../services/orderService.dart' show OrderService;
import '../services/cartService.dart';
import '../services/addressService.dart' show AddressApiService;
import '../services/apiTest.dart';
import '../services/reviewService.dart';

class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  final Map<Type, Object> _singletons = {};

  void registerSingleton<T extends Object>(T instance) {
    _singletons[T] = instance;
  }

  T get<T extends Object>() {
    final instance = _singletons[T];
    if (instance == null) {
      throw StateError('Service of type $T is not registered in ServiceLocator');
    }
    return instance as T;
  }

  void reset() {
    _singletons.clear();
  }
}

final ServiceLocator locator = ServiceLocator.instance;

void setupLocator() {
  locator.reset();

  // Core services
  locator.registerSingleton<IAuthService>(AuthService());

  // Services that depend on auth
  locator.registerSingleton<IOrderService>(
    OrderService(authService: locator.get<IAuthService>()),
  );
  locator.registerSingleton<IAddressService>(AddressApiService());

  // Other services
  locator.registerSingleton<ICartService>(CartService());
  locator.registerSingleton<IProductApiService>(ProductApiService());
  locator.registerSingleton<IReviewService>(ReviewApiService());
}


