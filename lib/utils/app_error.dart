import 'package:meta/meta.dart';

/// Типы ошибок приложения для унифицированной обработки
enum AppErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  cors,
  parsing,
  cancelled,
  unknown,
}

/// Исключение приложения с классификацией и доп. контекстом
@immutable
class AppException implements Exception {
  final AppErrorType type;
  final String message;
  final int? statusCode;
  final Object? cause;
  final StackTrace? stackTrace;
  final String? context;

  const AppException({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
    this.stackTrace,
    this.context,
  });

  @override
  String toString() {
    final code = statusCode != null ? ' [status=$statusCode]' : '';
    final ctx = context != null ? ' [context=$context]' : '';
    return 'AppException($type$code$ctx): $message';
  }
}


