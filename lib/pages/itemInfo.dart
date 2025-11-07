import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/review.dart';
import '../components/bottomNavBar.dart';
import '../components/authRequiredDialog.dart';
import '../components/safe_image.dart';

import '../services/interfaces/i_review_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../di/locator.dart';
// removed direct CartService usage; using CartProvider/FavoritesProvider
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/cart_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ItemInfoPage extends StatefulWidget {
  final Product product;
  
  const ItemInfoPage({super.key, required this.product});

  @override
  State<ItemInfoPage> createState() => _ItemInfoPageState();
}

class _ItemInfoPageState extends State<ItemInfoPage> {
  int quantity = 1;
  final IReviewService _reviewService = locator.get<IReviewService>();
  final IAuthService _authService = locator.get<IAuthService>();
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  final TextEditingController _quickReviewController = TextEditingController();
  bool _isFavorite = false; // Состояние избранного
  bool _isUserAuthenticated = false; // Состояние авторизации пользователя
  int _selectedRating = 5; // Выбранный рейтинг для отзыва

  // Рассчитываем общую цену на основе количества
  double get totalPrice => widget.product.currentPrice * quantity;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _checkAuthStatus();
    _checkIfFavorite();
  }

  Future<void> _checkAuthStatus() async {
    final isAuthenticated = await _authService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isUserAuthenticated = isAuthenticated;
      });
    }
  }

  @override
  void dispose() {
    _quickReviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      print('Загружаем отзывы для товара ${widget.product.id}');
      final reviews = await _reviewService.getProductReviews(widget.product.id);
      print('Загружено отзывов: ${reviews.length}');
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
      print('Отзывы загружены в UI: ${_reviews.length}');
    } catch (e) {
      setState(() {
        _isLoadingReviews = false;
      });
      print('Error loading reviews: $e');
      
      // Показываем пользователю понятное сообщение об ошибке
      if (mounted && e.toString().contains('API сервером')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Проблема с загрузкой отзывов. Попробуйте позже.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Принудительная перезагрузка отзывов без кеша
  Future<void> _loadReviewsForceRefresh() async {
    try {
      print('Принудительно обновляем отзывы для товара ${widget.product.id}');
      // Принудительно загружаем свежие данные без кеша
      final reviews = await _reviewService.getProductReviews(
        widget.product.id,
        forceRefresh: true,
      );
      print('Получено отзывов: ${reviews.length}');
      if (mounted) {
        setState(() {
          _reviews = reviews;
        });
        print('UI обновлен, отзывов в списке: ${_reviews.length}');
      }
    } catch (e) {
      print('Error force refreshing reviews: $e');
      // При ошибке оставляем текущий список (с новым отзывом)
      
      // Показываем пользователю понятное сообщение об ошибке
      if (mounted && e.toString().contains('API сервером')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось обновить отзывы. Попробуйте позже.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Проверка, находится ли товар в избранном
  Future<void> _checkIfFavorite() async {
    try {
      final fav = context.read<FavoritesProvider>();
      final isFavorite = fav.isFavoriteSync(widget.product.id);
      if (mounted) {
        setState(() { _isFavorite = isFavorite; });
      }
    } catch (e) {
      print('Ошибка при проверке избранного: $e');
    }
  }

  Widget _buildDefaultIcon() {
    final section = widget.product.sectionSlug;
    final isFlowers = section == 'flowers';
    final isPlants = section == 'plants';
    final icon = isFlowers
        ? Icons.local_florist
        : isPlants
            ? Icons.eco
            : Icons.coffee;
    final color = isPlants ? const Color(0xFF4B2E2E) : const Color(0xFF8B3A3A);
    return Icon(icon, color: color, size: 80);
  }

  // Создаем красивый fallback для главного изображения товара
  Widget _buildProductImageFallback() {
    final section = widget.product.sectionSlug;
    final isFlowers = section == 'flowers';
    final isPlants = section == 'plants';
    final icon = isFlowers
        ? Icons.local_florist
        : isPlants
            ? Icons.eco
            : Icons.coffee;
    final color = isPlants ? const Color(0xFF4B2E2E) : const Color(0xFF8B3A3A);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            widget.product.name,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B3A3A), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B3A3A),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF8B3A3A),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFB800),
                  size: 16,
                );
              }),
              const Spacer(),
              Text(
                review.formattedDate,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              if (review.isVerifiedPurchase) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF8B3A3A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            review.comment,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                review.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF8B3A3A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Список отзывов
        if (_isLoadingReviews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Color(0xFF8B3A3A),
              ),
            ),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Пока нет отзывов. Будьте первым, кто оставит отзыв!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8B3A3A),
                fontSize: 14,
              ),
            ),
          )
        else
          ..._reviews.map((review) => _buildReviewCard(review)).toList(),
      ],
    );
  }

  Future<void> _submitQuickReview() async {
    // Проверяем авторизацию
    if (!_isUserAuthenticated) {
      _showAuthRequiredDialog(
        title: 'Отзывы только для пользователей',
        message: 'Чтобы оставить отзыв, необходимо зарегистрироваться или войти в аккаунт. Это поможет нам поддерживать качество отзывов.',
      );
      return;
    }

    final reviewText = _quickReviewController.text.trim();
    if (reviewText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите текст отзыва'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Получаем данные пользователя
      final userData = await _authService.getSavedUser();
      final userName = userData?['username'] ?? 'Аноним';
      final userEmail = userData?['email'] ?? '';
      
      // Создаем быстрый отзыв с данными пользователя
      final reviewRequest = CreateReviewRequest(
        title: 'Отзыв о товаре', // Простой заголовок
        comment: reviewText,
        rating: _selectedRating, // Используем выбранный рейтинг
        userName: userName,
        userEmail: userEmail,
      );

      print('Отправляем отзыв для товара ${widget.product.id}');
      final newReview = await _reviewService.addReview(widget.product.id, reviewRequest);
      print('Ответ от API: ${newReview?.toJson()}');

      if (newReview != null) {
        _quickReviewController.clear();
        setState(() {
          _selectedRating = 5; // Сбрасываем рейтинг к значению по умолчанию
          // Добавляем новый отзыв в начало списка
          _reviews.insert(0, newReview);
        });
        
        // Принудительно перезагружаем отзывы с сервера (без кеша)
        await _loadReviewsForceRefresh();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отзыв добавлен!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при добавлении отзыва'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Ошибка при добавлении отзыва: $e');
      String errorMessage = 'Произошла ошибка при добавлении отзыва';
      
      if (e.toString().contains('не авторизован')) {
        errorMessage = 'Необходимо войти в аккаунт для добавления отзыва';
        _showAuthRequiredDialog(
          title: 'Авторизация требуется',
          message: 'Чтобы оставить отзыв, необходимо войти в аккаунт.',
        );
      } else if (e.toString().contains('API сервером')) {
        errorMessage = 'Проблема с сервером. Попробуйте позже.';
      } else if (e.toString().contains('валидации')) {
        errorMessage = 'Проверьте правильность введенных данных';
      } else {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAuthRequiredDialog({String? title, String? message}) {
    showDialog(
      context: context,
      builder: (context) => AuthRequiredDialog(
        title: title,
        message: message,
      ),
    );
  }

  Future<void> _addToCart() async {
    try {
      await context.read<CartProvider>().add(widget.product, quantity);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} добавлен в корзину!'),
            backgroundColor: const Color(0xFF4CAF50),
            action: SnackBarAction(
              label: 'В корзину',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Навигация в корзину
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorites() async {
    try {
      if (_isFavorite) {
        await context.read<FavoritesProvider>().toggle(widget.product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product.name} удален из избранного'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        await context.read<FavoritesProvider>().toggle(widget.product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product.name} добавлен в избранное!'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        }
      }
      
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // SVG фон
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/images/flowerbg.svg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // Основной контент
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 70),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Заголовок "Информация о товаре" слева
                      Row(
                        children: [
                          const Text(
                            'Информация о товаре',
                            style: TextStyle(
                              color: Colors.black, // Черный заголовок для лучшей видимости
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Главное изображение товара
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Изображение товара
                              if (widget.product.mainImage.isNotEmpty)
                                SafeImage(
                                  imageUrl: widget.product.mainImage,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  sectionSlug: widget.product.sectionSlug,
                                  page: widget.product.sectionSlug, // Используем секцию товара
                                  placeholder: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B3A3A)),
                                      ),
                                    ),
                                  ),
                                  errorWidget: _buildProductImageFallback(),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDECEC),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: _buildDefaultIcon(),
                                ),
                              // Индикаторы
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Карточка с информацией о товаре
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white, // Белый цвет для всех секций
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Название и иконка избранного
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.product.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8B3A3A),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _toggleFavorites(),
                                  child: Icon(
                                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: const Color(0xFF8B3A3A),
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Подзаголовок - категория
                            Text(
                              widget.product.categoryName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF8B3A3A),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Описание
                            Text(
                              widget.product.shortDescription.isNotEmpty 
                                ? widget.product.shortDescription 
                                : 'The fiddle leaf fig is famous for its large, violin-shaped leaves and is a popular choice for modern interior spaces.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8B3A3A),
                                height: 1.4,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Цена и количество
                            Row(
                              children: [
                                // Цена
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${totalPrice.toStringAsFixed(0)}TMT',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF8B3A3A),
                                      ),
                                    ),
                                    if (quantity > 1)
                                      Text(
                                        '${widget.product.currentPrice.toStringAsFixed(0)}TMT за шт.',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    if (widget.product.discountPrice != null)
                                      Text(
                                        '${widget.product.price.toStringAsFixed(0)}TMT',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                  ],
                                ),
                                
                                const Spacer(),
                                
                                // Количество
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF8B3A3A)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          if (quantity > 1) {
                                            setState(() {
                                              quantity--; // Цена автоматически пересчитается через totalPrice
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.remove, size: 20, color: Color(0xFF8B3A3A)),
                                        padding: const EdgeInsets.all(8),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          quantity.toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF8B3A3A),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            quantity++; // Цена автоматически пересчитается через totalPrice
                                          });
                                        },
                                        icon: const Icon(Icons.add, size: 20, color: Color(0xFF8B3A3A)),
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Кнопка Add to Cart
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _addToCart(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B3A3A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Характеристики
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white, // Белый цвет для всех секций
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildCharacteristicRow(Icons.local_florist, 'Category', widget.product.categoryName),
                            const Divider(color: Color(0xFF8B3A3A)),
                            _buildCharacteristicRow(Icons.local_florist_outlined, 'Section', widget.product.sectionName),
                            const Divider(color: Color(0xFF8B3A3A)),
                            _buildCharacteristicRow(Icons.inventory, 'SKU', widget.product.sku),
                            const Divider(color: Color(0xFF8B3A3A)),
                            _buildCharacteristicRow(Icons.storage, 'Stock', '${widget.product.stock} шт.'),
                            if (widget.product.isFeatured) ...[
                              const Divider(color: Color(0xFF8B3A3A)),
                              _buildCharacteristicRow(Icons.star, 'Status', 'Featured'),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Отзывы (динамические)
                      // _buildReviewsSection(),
                      
                      const SizedBox(height: 16),
                      
                      // Поле для быстрого отзыва
                      // Container(
                      //   width: double.infinity,
                      //   padding: const EdgeInsets.all(16),
                      //   decoration: BoxDecoration(
                      //     color: Colors.white, // Белый цвет для всех секций
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       // Выбор рейтинга
                      //       Row(
                      //         children: [
                      //           Text(
                      //             'Ваша оценка: ',
                      //             style: TextStyle(
                      //               color: Colors.grey[600],
                      //               fontSize: 14,
                      //             ),
                      //           ),
                      //           const SizedBox(width: 8),
                      //           ...List.generate(5, (index) {
                      //             return GestureDetector(
                      //               onTap: () {
                      //                 setState(() {
                      //                   _selectedRating = index + 1;
                      //                 });
                      //               },
                      //               child: Icon(
                      //                 index < _selectedRating ? Icons.star : Icons.star_border,
                      //                 color: const Color(0xFFFFB800),
                      //                 size: 24,
                      //               ),
                      //             );
                      //           }),
                      //         ],
                      //       ),
                      //       const SizedBox(height: 12),
                      //       // Поле для текста отзыва
                      //       Row(
                      //         children: [
                      //           Expanded(
                      //             child: TextField(
                      //               controller: _quickReviewController,
                      //               decoration: InputDecoration(
                      //                 hintText: 'Напишите ваш отзыв...',
                      //                 border: InputBorder.none,
                      //                 hintStyle: TextStyle(
                      //                   color: Colors.grey[400],
                      //                 ),
                      //               ),
                      //               maxLines: 3,
                      //               onSubmitted: (text) => _submitQuickReview(),
                      //             ),
                      //           ),
                      //           const SizedBox(width: 8),
                      //           GestureDetector(
                      //             onTap: _submitQuickReview,
                      //             child: Container(
                      //               width: 40,
                      //               height: 40,
                      //               decoration: const BoxDecoration(
                      //                 color: Color(0xFF4CAF50),
                      //                 shape: BoxShape.circle,
                      //               ),
                      //               child: const Icon(
                      //                 Icons.send,
                      //                 color: Colors.white,
                      //                 size: 20,
                      //               ),
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              // Нижняя навигация
              Align(
                alignment: Alignment.bottomCenter,
                child: BottomNavBarWidget(page: widget.product.sectionSlug),
              ),
            ],
          ),
        ),
      ),
    );
  }
}