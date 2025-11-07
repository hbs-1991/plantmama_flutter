import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../config.dart';

class SafeImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? sectionSlug;
  final String? page;

  const SafeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.sectionSlug,
    this.page,
  });

  @override
  State<SafeImage> createState() => _SafeImageState();
}

class _SafeImageState extends State<SafeImage> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _isHtmlResponse = false;
  bool _disposed = false;
  Uint8List? _bytes;
  String? _contentType;

  @override
  void initState() {
    super.initState();
    _validateImageUrl();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _validateImageUrl() async {
    if (widget.imageUrl.isEmpty) {
      _setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    // Пропускаем проверку для asset изображений и локальных файлов
    if (widget.imageUrl.startsWith('assets/') || 
        widget.imageUrl.startsWith('file://') ||
        widget.imageUrl.startsWith('data:')) {
      _setState(() {
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    // Проверяем, что URL выглядит как изображение или содержит base64
    if (!widget.imageUrl.contains('.') && 
        !widget.imageUrl.startsWith('data:image/') &&
        !['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].any(
          (ext) => widget.imageUrl.toLowerCase().contains(ext))) {
      _setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    // Для base64 изображений пропускаем HTTP проверку
    if (widget.imageUrl.startsWith('data:image/')) {
      _setState(() {
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    try {
      // Эффективный URL: форсируем https для ngrok
      Uri uri = Uri.parse(widget.imageUrl);
      if (uri.scheme == 'http' && uri.host.contains('ngrok-free.app')) {
        uri = uri.replace(scheme: 'https');
      }

      // Всегда применяем ngrok-заголовки для медиа файлов
      Map<String, String> headers = AppConfig.withImageHeaders({
        'Accept': 'image/*, */*',
        'User-Agent': 'PlantMana-Flutter-App/1.0',
        'Cache-Control': 'no-cache',
      });
      
      // Применяем ngrok bypass заголовки
      headers = AppConfig.withNgrokBypass(headers);

      final response = await http
          .get(uri, headers: headers)
          ; // Убираем таймаут - ждем загрузки столько, сколько нужно

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        final body = response.body;
        _contentType = contentType;

        // Проверяем HTML/предупреждение ngrok
        if (contentType.contains('text/html') ||
            body.startsWith('<!DOCTYPE') ||
            body.startsWith('<html') ||
            body.toLowerCase().contains('ngrok') ||
            body.contains('ERR_NGROK')) {
          _setState(() {
            _isLoading = false;
            _hasError = true;
            _isHtmlResponse = true;
            _bytes = null;
          });
          return;
        }

        // Проверяем, что это действительно изображение
        if (contentType.startsWith('image/') || 
            response.bodyBytes.length > 100) { // Если нет content-type, но есть байты
          _setState(() {
            _bytes = response.bodyBytes;
            _isLoading = false;
            _hasError = false;
          });
        } else {
          _setState(() {
            _isLoading = false;
            _hasError = true;
            _bytes = null;
          });
        }
      } else {
        _setState(() {
          _isLoading = false;
          _hasError = true;
          _bytes = null;
        });
      }
    } catch (e) {
      print('SafeImage: Ошибка валидации ${widget.imageUrl}: $e');
      _setState(() {
        _isLoading = false;
        _hasError = true;
        _bytes = null;
      });
      
      // Если это таймаут, показываем ошибку быстрее
              if (e.toString().contains('connection') || e.toString().contains('ConnectionException')) {
        print('SafeImage: Таймаут загрузки изображения, показываем fallback');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (_isLoading) {
        print('SafeImage: Показываем placeholder для: ${widget.imageUrl}');
        return _buildPlaceholder();
      }

      if (_hasError) {
        print('SafeImage: Показываем error widget для: ${widget.imageUrl}, HTML ответ: $_isHtmlResponse');
        return _buildErrorWidget();
      }

      // Для asset изображений используем Image.asset или SvgPicture.asset
      if (widget.imageUrl.startsWith('assets/')) {
        print('SafeImage: Отображаем asset изображение: ${widget.imageUrl}');
        // Проверяем, является ли файл SVG
        if (_isSvgUrl(widget.imageUrl)) {
          return SizedBox(
            width: widget.width ?? 100,
            height: widget.height ?? 100,
            child: SvgPicture.asset(
              widget.imageUrl,
              width: widget.width ?? 100,
              height: widget.height ?? 100,
              fit: widget.fit,
              placeholderBuilder: (context) => _buildPlaceholder(),
            ),
          );
        } else {
          return SizedBox(
            width: widget.width ?? 100,
            height: widget.height ?? 100,
            child: Image.asset(
              widget.imageUrl,
              width: widget.width ?? 100,
              height: widget.height ?? 100,
              fit: widget.fit,
              errorBuilder: (context, error, stackTrace) {
                print('SafeImage: Ошибка отображения asset изображения: $error');
                return _buildErrorWidget();
              },
            ),
          );
        }
      }

      // Для base64 изображений используем Image.memory
      if (widget.imageUrl.startsWith('data:image/')) {
        print('SafeImage: Отображаем base64 изображение');
        try {
          final data = widget.imageUrl.split(',')[1];
          final bytes = base64.decode(data);
          return SizedBox(
            width: widget.width ?? 100,
            height: widget.height ?? 100,
            child: Image.memory(
              bytes,
              width: widget.width ?? 100,
              height: widget.height ?? 100,
              fit: widget.fit,
              errorBuilder: (context, error, stackTrace) {
                print('SafeImage: Ошибка декодирования base64: $error');
                return _buildErrorWidget();
              },
            ),
          );
        } catch (e) {
          print('SafeImage: Ошибка декодирования base64: $e');
          return _buildErrorWidget();
        }
      }

      // Если байты уже загружены (рекомендуемый путь для ngrok/web) — показываем их
      if (_bytes != null) {
        print('SafeImage: Отображаем изображение из памяти. Content-Type: $_contentType, Размер: ${_bytes!.length} байт');
        
        // Проверяем, является ли изображение SVG
        if (_contentType?.contains('svg') == true || 
            _isSvgContent(_bytes!)) {
          print('SafeImage: Пробуем отобразить как SVG');
          try {
            return SizedBox(
              width: widget.width ?? 100,
              height: widget.height ?? 100,
              child: SvgPicture.memory(
                _bytes!,
                width: widget.width ?? 100,
                height: widget.height ?? 100,
                fit: widget.fit,
                placeholderBuilder: (context) => _buildPlaceholder(),
              ),
            );
          } catch (e) {
            print('SafeImage: Ошибка отображения SVG, пробуем как обычное изображение: $e');
            // Пробуем отобразить как обычное изображение
          }
        }

        print('SafeImage: Отображаем как обычное изображение из памяти');
        return SizedBox(
          width: widget.width ?? 100,
          height: widget.height ?? 100,
          child: Image.memory(
            _bytes!,
            width: widget.width ?? 100,
            height: widget.height ?? 100,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              print('SafeImage: Ошибка отображения изображения из памяти: $error');
              return _buildErrorWidget();
            },
            filterQuality: FilterQuality.medium,
          ),
        );
      }

      // Фолбэк: прямой сетевой показ (для платформ, где заголовки не нужны)
      // Примечание: headers в Image.network игнорируются на вебе
      print('SafeImage: Используем прямой сетевой показ для: ${widget.imageUrl}');
      String effectiveUrl = widget.imageUrl;
      try {
        final u = Uri.parse(widget.imageUrl);
        if (u.scheme == 'http' && u.host.contains('ngrok-free.app')) {
          effectiveUrl = u.replace(scheme: 'https').toString();
          print('SafeImage: Изменен URL на HTTPS: $effectiveUrl');
        }
      } catch (_) {}

      // Проверяем, является ли URL SVG
      if (_isSvgUrl(effectiveUrl)) {
        print('SafeImage: Пробуем отобразить SVG через сеть');
        try {
          return SizedBox(
            width: widget.width ?? 100,
            height: widget.height ?? 100,
            child: SvgPicture.network(
              effectiveUrl,
              width: widget.width ?? 100,
              height: widget.height ?? 100,
              fit: widget.fit,
              placeholderBuilder: (context) => _buildPlaceholder(),
              errorBuilder: (context, error, stackTrace) {
                print('SafeImage: Ошибка загрузки SVG: $error');
                return _buildErrorWidget();
              },
            ),
          );
        } catch (e) {
          print('SafeImage: Ошибка создания SVG widget: $e');
          // Пробуем обычное изображение
        }
      }

      Map<String, String>? imageHeaders;
      try {
        final host = Uri.parse(effectiveUrl).host;
        if (host.contains('ngrok')) {
          imageHeaders = AppConfig.withNgrokBypass({
            'Accept': 'image/*',
            'User-Agent': 'PlantMana-Flutter-App/1.0',
          });
        }
      } catch (_) {}

      return SizedBox(
        width: widget.width ?? 100,
        height: widget.height ?? 100,
        child: Image.network(
          effectiveUrl,
          width: widget.width ?? 100,
          height: widget.height ?? 100,
          fit: widget.fit,
          headers: imageHeaders,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) {
            print('SafeImage: Ошибка загрузки изображения $effectiveUrl: $error');
            return _buildErrorWidget();
          },
          cacheWidth: (widget.width ?? 100).toInt(),
          cacheHeight: (widget.height ?? 100).toInt(),
          filterQuality: FilterQuality.medium,
        ),
      );
    } catch (e) {
      print('SafeImage: Критическая ошибка в build: $e');
      return _buildErrorWidget();
    }
  }

  Widget _buildPlaceholder() {
    try {
      if (widget.placeholder != null) {
        return widget.placeholder!;
      }

      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    } catch (e) {
      print('SafeImage: Ошибка в placeholder: $e');
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      );
    }
  }

  Widget _buildErrorWidget() {
    try {
      if (widget.errorWidget != null) {
        return widget.errorWidget!;
      }

      // Определяем иконку и цвет в зависимости от секции
      final section = widget.sectionSlug ?? widget.page ?? '';
      final isFlowers = section == 'flowers' || section.contains('flower');
      final isPlants = section == 'plants' || section.contains('plant');
      final isCafe = section == 'cafe' || section.contains('drink') || section.contains('food');

      IconData icon;
      Color color;

      if (isFlowers) {
        icon = Icons.local_florist;
        color = const Color(0xFF8B3A3A);
      } else if (isPlants) {
        icon = Icons.eco;
        color = const Color(0xFF4B2E2E);
      } else if (isCafe) {
        icon = Icons.coffee;
        color = const Color(0xFF8B3A3A);
      } else {
        icon = Icons.image_not_supported;
        color = Colors.grey[600]!;
      }

      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: (widget.width ?? 100) * 0.3,
              ),
              if (_isHtmlResponse) ...[
                const SizedBox(height: 4),
                Text(
                  'Ошибка загрузки',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      print('SafeImage: Ошибка в error widget: $e');
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(SafeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _setState(() {
        _isLoading = true;
        _hasError = false;
        _isHtmlResponse = false;
        _bytes = null;
      });
      _validateImageUrl();
    }
  }

  // Проверяем, является ли контент SVG по первым байтам
  bool _isSvgContent(Uint8List bytes) {
    if (bytes.length < 10) return false;
    
    // Проверяем SVG заголовок: <?xml или <svg
    final start = String.fromCharCodes(bytes.take(10));
    return start.contains('<?xml') || start.contains('<svg');
  }

  // Проверяем, является ли URL SVG
  bool _isSvgUrl(String url) {
    return url.toLowerCase().endsWith('.svg') || 
           url.toLowerCase().contains('.svg?') ||
           url.toLowerCase().contains('svg');
  }
}
