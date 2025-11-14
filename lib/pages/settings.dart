import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:plantmana_test/components/changeNumber.dart';
import 'package:plantmana_test/components/changeName.dart';
import 'package:plantmana_test/components/mapsModal.dart';
import 'package:plantmana_test/components/changePassword.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../pages/login.dart';
import '../pages/addressList.dart';
import '../pages/orders.dart';
import '../components/changeUsername.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.page});
  final String? page;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  User? _currentUser;
  bool _isLoading = true;
  bool _isUpdatingProfile = false;
  
  bool get isUserAuthenticated => _currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Загружаем данные сразу
    // Периодическое обновление каждые 5 секунд
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadUserData();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    try {
      // Используем read в initState, watch только в build
      final user = context.read<AuthProvider>().currentUser;
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Settings: Ошибка загрузки данных пользователя: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
  
  // Функция для показа модального окна настройки уведомлений
  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Настройка уведомлений',
                style: TextStyle(
                  color: Color(0xFF4B2E2E),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Хотите ли вы получать уведомления о новых акциях, скидках и поступлениях товаров?',
                style: TextStyle(
                  color: Color(0xFF4B2E2E),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: _notificationsEnabled 
                      ? (widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A))
                      : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _notificationsEnabled ? 'Уведомления включены' : 'Уведомления отключены',
                    style: TextStyle(
                      color: _notificationsEnabled 
                        ? (widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A))
                        : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _notificationsEnabled = false;
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Уведомления отключены'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      minimumSize: const Size(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Нет',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _notificationsEnabled = true;
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Уведомления включены! Вы будете получать актуальную информацию.'),
                          backgroundColor: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
                      minimumSize: const Size(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Да',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Функция для показа экрана чата с саппортом
  void _showChatSupport() {
    // Проверяем авторизацию перед открытием чата
    if (!isUserAuthenticated) {
      _showAuthRequiredDialog();
      return;
    }

    // Если пользователь авторизован, открываем чат
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ChatSupportScreen(page: widget.page),
        fullscreenDialog: true,
      ),
    );
  }

  // Функция для показа модалки регистрации
  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.person_add,
                color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Требуется регистрация',
                style: TextStyle(
                  color: Color(0xFF4B2E2E),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Чтобы получить поддержку и связаться с нашими специалистами, необходимо зарегистрироваться или войти в аккаунт.',
                style: TextStyle(
                  color: Color(0xFF4B2E2E),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
                      minimumSize: const Size(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Регистрация',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Align(
          alignment: Alignment.center,
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
                      // Заголовок "Настройки" слева
                      Row(
                        children: [
                          const Text(
                            'Настройки',
                            style: TextStyle(
                              color: Colors.black, // Черный заголовок для лучшей видимости
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Индикатор загрузки
                      if (_isLoading)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          child: const Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B3A3A)),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Загрузка настроек...',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Основной контент (показываем только когда загружено)
                      if (!_isLoading) ...[
                      // Профиль
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white, // Белый цвет для всех секций
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(
                                Icons.person_rounded,
                                color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
                                size: 150,
                              ),
                              const SizedBox(height: 16),
                              // Имя (кастомный виджет)
                              Row(
                                children: [
                                  Icon(Icons.person, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), size: 24),
                                  const SizedBox(width: 5),
                                 GestureDetector(
                                  onTap: isUserAuthenticated ? () async {
                                    final result = await showDialog<bool>(
                                      context: context, 
                                      builder: (context) => ChangeNameWidget(page: widget.page)
                                    );
                                    if (result == true) {
                                      _loadUserData(); // Обновляем данные пользователя
                                    }
                                  } : null,
                                  child:  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _isLoading 
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2)
                                            )
                                          : Text(
                                              isUserAuthenticated 
                                                  ? '${_currentUser?.firstName ?? ''} ${_currentUser?.lastName ?? ''}'.trim().isEmpty 
                                                      ? _currentUser?.email ?? 'Гость'
                                                      : '${_currentUser?.firstName ?? ''} ${_currentUser?.lastName ?? ''}'.trim()
                                                  : 'Гость',
                                              style: TextStyle(color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), fontSize: 20)
                                            ),
                                      Text(
                                        isUserAuthenticated ? 'Ваше имя' : 'Войдите в аккаунт',
                                        style: const TextStyle(color: Color(0xFF8C7070), fontSize: 13)
                                      ),
                                    ],
                                  ),
                                 )
                                  // ChangeNameWidget() // <- кастомный виджет, не импортируем
                                ],
                              ),
                              Divider(thickness: 2, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A)),
                              // Email
                              Row(
                                children: [
                                  Icon(Icons.email, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), size: 24),
                                  const SizedBox(width: 5),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _isLoading 
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2)
                                            )
                                          : Text(
                                              isUserAuthenticated 
                                                  ? _currentUser?.email ?? 'Добавить email'
                                                  : 'Войдите в аккаунт',
                                              style: TextStyle(color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), fontSize: 20)
                                            ),
                                      Text(
                                        isUserAuthenticated ? 'Ваш email' : 'Email',
                                        style: const TextStyle(color: Color(0xFF8C7070), fontSize: 13)
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Divider(thickness: 2, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A)),
                              // Номер (кастомный виджет)
                              GestureDetector(
                                onTap: isUserAuthenticated ? () async {
                                  final result = await showDialog<bool>(
                                    context: context, 
                                    builder: (context) => ChangeNumberWidget(page: widget.page)
                                  );
                                  if (result == true) {
                                    _loadUserData(); // Обновляем данные пользователя
                                  }
                                } : null,
                                child: Row(
                                children: [
                                  Icon(Icons.phone, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), size: 24),
                                  const SizedBox(width: 5),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _isLoading 
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2)
                                            )
                                          : Text(
                                              isUserAuthenticated 
                                                  ? _currentUser?.phone.isEmpty == true ? 'Добавить номер' : _currentUser?.phone ?? 'Добавить номер'
                                                  : 'Войдите в аккаунт',
                                              style: TextStyle(color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), fontSize: 20)
                                            ),
                                      Text(
                                        isUserAuthenticated ? 'Ваш номер' : 'Номер телефона',
                                        style: const TextStyle(color: Color(0xFF8C7070), fontSize: 13)
                                      ),
                                    ],
                                  ),
                                  // ChangeNumberWidget() // <- кастомный виджет, не импортируем
                                ],
                              ),
                              ),
                              Divider(thickness: 2, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A)),
                              // Пароль (кастомный виджет)
                              GestureDetector(
                                onTap: isUserAuthenticated ? () {
                                  showDialog(context: context, builder: (context) => ChangePasswordWidget(page: widget.page));
                                } : null,
                                child: Row(
                                  children: [
                                    Icon(Icons.lock, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), size: 24),
                                    const SizedBox(width: 5),
                                    Text('Change password', style: TextStyle(color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), fontSize: 20)),
                                  ],
                                ),
                              ),
                              
                              Divider(thickness: 2, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A)),
                              // Мои адреса
                              GestureDetector(
                                onTap: isUserAuthenticated ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddressListPage(),
                                    ),
                                  );
                                } : null,
                                child: Row(
                                  children: [
                                    Icon(Icons.home, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), size: 24),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _isLoading 
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2)
                                                )
                                              : Text(
                                                  isUserAuthenticated ? 'Мои адреса' : 'Войдите в аккаунт',
                                                  style: TextStyle(color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), fontSize: 20),
                                                ),
                                          Text(
                                            isUserAuthenticated ? 'Управление адресами доставки' : 'Адреса доставки',
                                            style: const TextStyle(color: Color(0xFF8C7070), fontSize: 13)
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(thickness: 2, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A)),
                              // Заказы
                              GestureDetector(
                                onTap: isUserAuthenticated ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrdersPage(page: widget.page),
                                    ),
                                  );
                                } : null,
                                child: Row(
                                  children: [
                                    Icon(Icons.shopping_bag, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), size: 24),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _isLoading 
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2)
                                                )
                                              : Text(
                                                  isUserAuthenticated ? 'Мои заказы' : 'Войдите в аккаунт',
                                                  style: TextStyle(color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), fontSize: 20),
                                                ),
                                          Text(
                                            isUserAuthenticated ? 'История заказов' : 'История покупок',
                                            style: const TextStyle(color: Color(0xFF8C7070), fontSize: 13)
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(thickness: 2, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A)),
                              // Премиум
                              Row(
                                children: [
                                  Icon(Icons.workspace_premium, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), size: 24),
                                  const SizedBox(width: 5),
                                  Text('Buy premium', style: TextStyle(color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), fontSize: 20)),
                                ],
                              ),
                              if (isUserAuthenticated) ...[
                                Divider(thickness: 2, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A)),
                                GestureDetector(
                                  onTap: _logout,
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout, color: Colors.red, size: 24),
                                      const SizedBox(width: 5),
                                      const Text('Выйти из аккаунта', style: TextStyle(color: Colors.red, fontSize: 20)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                                             // Уведомления
                       Container(
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: Colors.white, // Белый цвет для всех секций
                           borderRadius: BorderRadius.circular(20),
                         ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              GestureDetector(
                                onTap: _showNotificationsDialog,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        FaIcon(
                                          _notificationsEnabled ? FontAwesomeIcons.solidBell : FontAwesomeIcons.bell, 
                                          color: _notificationsEnabled 
                                            ? (widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A))
                                            : Colors.grey,
                                          size: 24
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'Notifications', 
                                          style: TextStyle(
                                            color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), 
                                            fontSize: 20
                                          )
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          _notificationsEnabled ? 'Вкл' : 'Выкл',
                                          style: TextStyle(
                                            color: _notificationsEnabled 
                                              ? (widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A))
                                              : Colors.grey,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Divider(thickness: 2, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A)),
                              Row(
                                children: [
                                  Icon(Icons.help_rounded, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), size: 24),
                                  SizedBox(width: 5),
                                  Text('Help', style: TextStyle(color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), fontSize: 20)),
                                ],
                              ),
                              Divider(thickness: 2, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A)),
                              GestureDetector(
                                onTap: _showChatSupport,
                                child: Row(
                                  children: [
                                    Icon(Icons.support_agent_sharp, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), size: 24),
                                    SizedBox(width: 5),
                                    Text('Online support', style: TextStyle(color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), fontSize: 20)),
                                  ],
                                ),
                              ),
                              Divider(thickness: 2, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A)),
                              Row(
                                children: [
                                  FaIcon(FontAwesomeIcons.userGroup, color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), size: 24),
                                  SizedBox(width: 5),
                                  Text('Invite your friends', style: TextStyle(color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A), fontSize: 20)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      ], // Закрываем if (!_isLoading) ...
                    ],
                  ),
                ),
              ),
              // Нижняя навигация (кастомный виджет, не импортируем)
              // BottomNavBarWidget(),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

// Экран чата с саппортом
class _ChatSupportScreen extends StatefulWidget {
  final String? page;
  
  const _ChatSupportScreen({this.page});

  @override
  State<_ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<_ChatSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello, I\'m supporter how can I help you',
      'isFromSupport': true,
      'time': DateTime.now(),
    }
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'isFromSupport': false,
        'time': DateTime.now(),
      });
    });
    
    _messageController.clear();
    
    // Имитация ответа саппорта через 2 секунды
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': 'Thank you for your message. Our team will get back to you shortly.',
            'isFromSupport': true,
            'time': DateTime.now(),
          });
        });
      }
    });
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isFromSupport = message['isFromSupport'] as bool;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isFromSupport ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFromSupport) ...[
            // Аватар саппорта
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.page == 'flowers' 
                  ? const Color(0xFF8B6B6B) 
                  : const Color(0xF23A5430),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Облачко сообщения
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromSupport 
                  ? (widget.page == 'flowers' 
                      ? const Color(0xFF8B6B6B) 
                      : const Color(0xF23A5430))
                  : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isFromSupport ? 4 : 16),
                  bottomRight: Radius.circular(isFromSupport ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                   color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message['text'] as String,
                style: TextStyle(
                  color: isFromSupport ? Colors.white : const Color(0xFF4B2E2E),
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (!isFromSupport) const SizedBox(width: 48),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: widget.page == 'flowers' ? const Color(0xFFB58484) : Colors.white,
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.page == 'flowers' 
              ? const Color(0xFFB58484) 
              : widget.page == 'plants'
                ? const Color(0xFF3A5220)
                : const Color(0xFFA3B6CC),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Заголовок с кнопкой закрытия
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chat Support',
                        style: TextStyle(
                          color: widget.page == 'flowers' ? Colors.white : Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: widget.page == 'flowers' ? Colors.white : Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: widget.page == 'flowers' ? const Color(0xFFB58484) : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Область сообщений
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
                ),
                
                // Поле ввода сообщения
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                   color: Colors.white.withValues(alpha: 0.9),
                    border: Border(
                      top: BorderSide(
                       color: Colors.grey.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: widget.page == 'flowers' 
                            ? const Color(0xFF8B6B6B) 
                            : const Color(0xF23A5430),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
