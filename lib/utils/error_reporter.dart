import 'dart:async';

import 'app_error.dart';

/// Глобальный репортер ошибок приложения
class ErrorReporter {
  ErrorReporter._();

  static final ErrorReporter instance = ErrorReporter._();

  final StreamController<AppException> _controller = StreamController<AppException>.broadcast();

  Stream<AppException> get stream => _controller.stream;

  void report(AppException error) {
    // Можно подключить Crashlytics/Sentry здесь
    // ignore: avoid_print
    print(error.toString());
    if (!_controller.isClosed) {
      _controller.add(error);
    }
  }

  static void reportNow(AppException error) => instance.report(error);
}


