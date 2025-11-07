import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/app_error.dart';
import '../utils/error_reporter.dart';

class AppErrorListener extends StatefulWidget {
  const AppErrorListener({super.key, required this.child});

  final Widget child;

  @override
  State<AppErrorListener> createState() => _AppErrorListenerState();
}

class _AppErrorListenerState extends State<AppErrorListener> {
  StreamSubscription<AppException>? _subscription;
  DateTime? _lastShownAt;
  String? _lastMessage;

  static const Duration _throttle = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _subscription = ErrorReporter.instance.stream.listen(_handleError);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleError(AppException error) {
    if (!mounted) return;

    final now = DateTime.now();
    if (_lastShownAt != null && _lastMessage == error.message) {
      if (now.difference(_lastShownAt!) < _throttle) return;
    }

    _lastShownAt = now;
    _lastMessage = error.message;

    final (icon, color) = _iconAndColor(error.type);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color.withValues(alpha: 0.95),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: _buildAction(error),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  SnackBarAction? _buildAction(AppException error) {
    if (error.type == AppErrorType.unauthorized) {
      return SnackBarAction(
        label: 'Войти',
        textColor: Colors.white,
        onPressed: () {
          // Приложение само переключит экран через AuthWrapper после логина
          // Здесь можно открыть страницу логина, если требуется принудительно
          // Navigator.of(context).push(...)
        },
      );
    }
    return null;
  }

  (IconData, Color) _iconAndColor(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return (Icons.wifi_off, Colors.orange);
      case AppErrorType.timeout:
        return (Icons.timer_off, Colors.orange);
      case AppErrorType.unauthorized:
        return (Icons.lock_outline, Colors.redAccent);
      case AppErrorType.forbidden:
        return (Icons.block, Colors.redAccent);
      case AppErrorType.notFound:
        return (Icons.search_off, Colors.blueGrey);
      case AppErrorType.validation:
        return (Icons.error_outline, Colors.deepOrange);
      case AppErrorType.server:
        return (Icons.dns, Colors.redAccent);
      case AppErrorType.cors:
        return (Icons.public_off, Colors.purple);
      case AppErrorType.parsing:
        return (Icons.code_off, Colors.indigo);
      case AppErrorType.cancelled:
        return (Icons.cancel, Colors.grey);
      case AppErrorType.unknown:
        return (Icons.error, Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


