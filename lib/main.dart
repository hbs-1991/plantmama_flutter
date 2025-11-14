import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './pages/homepage.dart';
import './pages/login.dart';
import './providers/auth_provider.dart';
import './providers/cart_provider.dart';
import './providers/products_provider.dart';
import './providers/favorites_provider.dart';
import './providers/orders_provider.dart';
import './providers/addresses_provider.dart';
import './bloc/orders/orders_bloc.dart';
import './services/interfaces/i_order_service.dart';
import './di/locator.dart';
import './utils/error_handler.dart';
import './utils/error_reporter.dart';
import 'dart:async';
import './widgets/app_error_listener.dart';

void main() {
  setupLocator();

  // Configure status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white, // White status bar for visibility
    statusBarIconBrightness: Brightness.dark, // Dark icons for white background
    statusBarBrightness: Brightness.light, // For iOS
    systemNavigationBarColor: Colors.white, // White navigation bar
    systemNavigationBarIconBrightness: Brightness.dark, // Dark navigation icons
  ));

  // Ensure immersive mode is disabled
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);

  // Глобальные обработчики ошибок
  FlutterError.onError = (FlutterErrorDetails details) {
    final appEx = ErrorHandler.handle(details.exception, stackTrace: details.stack, context: 'FlutterError');
    ErrorReporter.reportNow(appEx);
  };

  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    final appEx = ErrorHandler.handle(error, stackTrace: stack, context: 'Zone');
    ErrorReporter.reportNow(appEx);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => AddressesProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => OrdersBloc(orderService: locator.get<IOrderService>())),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
            useMaterial3: true,
          ),
          builder: (context, child) => AppErrorListener(child: child ?? const SizedBox.shrink()),
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Инициализация после первого кадра, чтобы избежать notifyListeners в build
      try {
        // Сначала инициализируем авторизацию
        await context.read<AuthProvider>().initialize();

        // Затем последовательно загружаем данные
        await _loadDataSequentially();

        // Запускаем загрузку заказов только если пользователь авторизован
        final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
        if (isLoggedIn) {
          context.read<OrdersBloc>().add(OrdersRequested());
        }
      } catch (e) {
        print('AuthWrapper: Ошибка инициализации: $e');
        // Продолжаем работу даже при ошибках
      }
    });
  }

  Future<void> _loadDataSequentially() async {
    try {
      print('AuthWrapper: _loadDataSequentially() - начинаем загрузку данных');
      
      // Загружаем основные данные последовательно
      await context.read<ProductsProvider>().loadSections();
      await context.read<ProductsProvider>().loadCategories();
      await context.read<ProductsProvider>().loadProducts();
      
      // Загружаем пользовательские данные
      await Future.wait([
        context.read<CartProvider>().loadCart(),
        context.read<FavoritesProvider>().loadFavorites(),
      ]);
      
      // Загружаем адреса и заказы (только если пользователь авторизован)
      final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
      print('AuthWrapper: _loadDataSequentially() - пользователь авторизован: $isLoggedIn');
      
      if (isLoggedIn) {
        print('AuthWrapper: _loadDataSequentially() - загружаем пользовательские данные');
        await Future.wait([
          context.read<AddressesProvider>().loadAddresses(),
          context.read<OrdersProvider>().loadOrders(),
          context.read<OrdersProvider>().loadMethods(),
        ]);
        
        // ✅ Запускаем OrdersBloc ТОЛЬКО после проверки авторизации и загрузки данных
        print('AuthWrapper: _loadDataSequentially() - запускаем OrdersBloc');
        context.read<OrdersBloc>().add(OrdersRequested());
      } else {
        print('AuthWrapper: _loadDataSequentially() - пользователь не авторизован, пропускаем загрузку заказов');
      }
    } catch (e) {
      print('AuthWrapper: Ошибка загрузки данных: $e');
      // Продолжаем работу даже при ошибках
    }
  }

  @override
  Widget build(BuildContext context) {
    final (isChecking, isLoggedIn) = context.select<AuthProvider, (bool, bool)>((a) => (a.isChecking, a.isLoggedIn));
    if (isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return isLoggedIn ? const HomePage() : const LoginPage();
  }
}
