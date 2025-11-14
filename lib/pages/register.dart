import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'homepage.dart';
import 'login.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _selectedCountryCode = '+7';
  String _formattedPhone = '';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+7', 'country': 'RU', 'name': 'Россия'},
    {'code': '+993', 'country': 'TM', 'name': 'Туркменистан'},
    {'code': '+1', 'country': 'US', 'name': 'США'},
    {'code': '+44', 'country': 'GB', 'name': 'Великобритания'},
    {'code': '+49', 'country': 'DE', 'name': 'Германия'},
    {'code': '+33', 'country': 'FR', 'name': 'Франция'},
    {'code': '+86', 'country': 'CN', 'name': 'Китай'},
    {'code': '+81', 'country': 'JP', 'name': 'Япония'},
    {'code': '+82', 'country': 'KR', 'name': 'Южная Корея'},
    {'code': '+91', 'country': 'IN', 'name': 'Индия'},
    {'code': '+55', 'country': 'BR', 'name': 'Бразилия'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    // Убираем все символы кроме цифр
    String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Форматируем в зависимости от кода страны
    if (_selectedCountryCode == '+7') {
      // Российский формат: +7 (XXX) XXX-XX-XX
      if (digitsOnly.length <= 3) {
        return digitsOnly;
      } else if (digitsOnly.length <= 6) {
        return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3)}';
      } else if (digitsOnly.length <= 8) {
        return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
      } else {
        return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6, 8)}-${digitsOnly.substring(8, 10)}';
      }
    } else if (_selectedCountryCode == '+993') {
      // Туркменский формат: +993 XX XXXXXX
      if (digitsOnly.length <= 2) {
        return digitsOnly;
      } else if (digitsOnly.length <= 4) {
        return '${digitsOnly.substring(0, 2)} ${digitsOnly.substring(2)}';
      } else {
        return '${digitsOnly.substring(0, 2)} ${digitsOnly.substring(2, 8)}';
      }
    } else if (_selectedCountryCode == '+1') {
      // Американский формат: (XXX) XXX-XXXX
      if (digitsOnly.length <= 3) {
        return digitsOnly;
      } else if (digitsOnly.length <= 6) {
        return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3)}';
      } else {
        return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6, 10)}';
      }
    } else {
      // Общий формат для других стран: XXX XXX XXXX
      if (digitsOnly.length <= 3) {
        return digitsOnly;
      } else if (digitsOnly.length <= 6) {
        return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3)}';
      } else {
        return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6)}';
      }
    }
  }

  void _onPhoneChanged(String value) {
    String formatted = _formatPhoneNumber(value);
    if (formatted != _formattedPhone) {
      _formattedPhone = formatted;
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Выберите страну',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _countryCodes.length,
                itemBuilder: (context, index) {
                  final country = _countryCodes[index];
                  final isSelected = country['code'] == _selectedCountryCode;
                  
                  return ListTile(
                    leading: Text(
                      country['country']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(country['name']!),
                    trailing: Text(
                      country['code']!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF8B3A3A) : Colors.black54,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedCountryCode = country['code']!;
                        // Переформатируем номер при смене кода страны
                        if (_phoneController.text.isNotEmpty) {
                          _onPhoneChanged(_phoneController.text);
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_isLoading) {
      print('RegisterPage: Регистрация уже выполняется, пропускаем');
      return;
    }

    if (_emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage('Заполните все поля');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Пароли не совпадают');
      return;
    }

    // Получаем только цифры из номера и проверяем длину
    String digitsOnly = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    int minLength = _selectedCountryCode == '+993' ? 8 : 10;
    int maxLength = _selectedCountryCode == '+993' ? 8 : 15;
    if (digitsOnly.length < minLength) {
      String message = _selectedCountryCode == '+993' 
          ? 'Туркменский номер должен содержать 8 цифр'
          : 'Номер телефона должен содержать минимум 10 цифр';
      _showMessage(message);
      return;
    }
    if (digitsOnly.length > maxLength) {
      String message = _selectedCountryCode == '+993' 
          ? 'Туркменский номер должен содержать ровно 8 цифр'
          : 'Номер телефона слишком длинный';
      _showMessage(message);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('RegisterPage: Начинаем регистрацию');
      final auth = context.read<AuthProvider>();
      final fullPhone = '$_selectedCountryCode$digitsOnly';
      final ok = await auth.register(
        _emailController.text,
        fullPhone,
        _passwordController.text,
      );
      
      if (mounted) {
        if (ok) {
          print('RegisterPage: Регистрация успешна');

          // Проверяем, авторизован ли пользователь после регистрации
          final authProvider = context.read<AuthProvider>();
          if (authProvider.isLoggedIn) {
            print('RegisterPage: Пользователь авторизован, переходим на главную');
            _showMessage('Регистрация успешна!');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else {
            print('RegisterPage: Пользователь не авторизован, пытаемся войти автоматически');
            // Пытаемся войти автоматически с теми же данными
            try {
              final loginOk = await authProvider.login(
                _emailController.text,
                _passwordController.text,
              );

              if (loginOk) {
                print('RegisterPage: Автоматический вход успешен');
                _showMessage('Регистрация и вход успешны!');
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              } else {
                print('RegisterPage: Автоматический вход не удался');
                _showMessage('Регистрация успешна! Войдите в систему.');
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            } catch (e) {
              print('RegisterPage: Ошибка автоматического входа: $e');
              _showMessage('Регистрация успешна! Войдите в систему.');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }
          }
        } else {
          print('RegisterPage: Регистрация не удалась');
          _showMessage('Ошибка регистрации. Попробуйте еще раз.');
        }
      }
    } catch (e) {
      if (mounted) {
        print('RegisterPage: Ошибка регистрации: $e');
        _showMessage(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Container(
      width: 350,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black54.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Icon(icon, color: Colors.black54, size: 24),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.black54, fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      width: 350,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black54.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Кнопка выбора кода страны
          GestureDetector(
            onTap: _showCountryCodePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, color: Colors.black54, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    _selectedCountryCode,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Разделитель
          Container(
            width: 1,
            height: 30,
            color: Colors.black54.withOpacity(0.3),
          ),
          // Поле ввода номера
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black54, fontSize: 16),
                onChanged: _onPhoneChanged,
                decoration: const InputDecoration(
                  hintText: 'Номер телефона',
                  hintStyle: TextStyle(color: Colors.black54, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.black54,
        body: SafeArea(
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
              Container(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        child: const Icon(
                          Icons.person_add,
                          size: 80,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Регистрация',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'EMAIL',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildPhoneField(),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'PASSWORD',
                        icon: Icons.lock,
                        isPassword: true,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: 'CONFIRM PASSWORD',
                        icon: Icons.lock,
                        isPassword: true,
                      ),
                      const SizedBox(height: 50),
                      SizedBox(
                        width: 350,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLoading ? Colors.grey : Colors.white,
                            foregroundColor: Colors.black54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black54,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'REGISTER',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}