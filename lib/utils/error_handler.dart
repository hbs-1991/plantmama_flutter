import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'app_error.dart';

class ErrorHandler {
  static bool _looksLikeHtml(String body, Map<String, String> headers) {
    final contentType = headers['content-type'] ?? '';
    final trimmed = body.trimLeft();
    return trimmed.startsWith('<!DOCTYPE') ||
        trimmed.startsWith('<html') ||
        contentType.contains('text/html');
  }

  /// Определяет тип ошибки по статус-коду HTTP
  static AppErrorType _typeFromStatus(int statusCode) {
    if (statusCode == 401) return AppErrorType.unauthorized;
    if (statusCode == 403) return AppErrorType.forbidden;
    if (statusCode == 404) return AppErrorType.notFound;
    if (statusCode >= 400 && statusCode < 500) return AppErrorType.validation;
    if (statusCode >= 500) return AppErrorType.server;
    return AppErrorType.unknown;
  }

  /// Извлекает человеко-читаемое сообщение из тела ошибки API
  static String _extractMessage(String body) {
    try {
      final dynamic decoded = json.decode(body);
      if (decoded is Map) {
        for (final key in ['detail', 'message', 'error']) {
          final v = decoded[key];
          if (v is String && v.isNotEmpty) return v;
        }
        // Склеиваем первые ошибки валидации
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String) return first;
          }
          if (value is String && value.isNotEmpty) return value;
        }
      }
    } catch (_) {}
    return body.length > 200 ? body.substring(0, 200) : body;
  }

  /// Преобразует любые исключения/ответы в унифицированный AppException
  static AppException handle(Object error, {StackTrace? stackTrace, String? context, http.Response? response}) {
    // Обработка по http.Response, если передан
    if (response != null) {
      final isHtml = _looksLikeHtml(response.body, response.headers);
      if (isHtml) {
        return AppException(
          type: AppErrorType.cors,
          message: 'Ответ содержит HTML. Возможна проблема с туннелем/прокси (ngrok) или CORS.',
          statusCode: response.statusCode,
          cause: error,
          stackTrace: stackTrace,
          context: context,
        );
      }
      final type = _typeFromStatus(response.statusCode);
      final message = _extractMessage(response.body);
      return AppException(
        type: type,
        message: message,
        statusCode: response.statusCode,
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }

    // Исключения сети/таймаута/отмены
    if (error is SocketException) {
      return AppException(
        type: AppErrorType.network,
        message: 'Ошибка подключения к серверу. Проверьте интернет-соединение.',
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }
    if (error is HttpException) {
      return AppException(
        type: AppErrorType.network,
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }
    if (error is FormatException) {
      return AppException(
        type: AppErrorType.parsing,
        message: 'Ошибка обработки данных ответа.',
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }
    if (error is TimeoutException) {
      return AppException(
        type: AppErrorType.timeout,
        message: 'Превышено время ожидания ответа сервера.',
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }

    // Уже приведенная ошибка
    if (error is AppException) return error;

    // Фолбэк
    return AppException(
      type: AppErrorType.unknown,
      message: error.toString(),
      cause: error,
      stackTrace: stackTrace,
      context: context,
    );
  }
}


