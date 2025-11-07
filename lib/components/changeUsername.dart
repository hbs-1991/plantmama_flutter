import 'package:flutter/material.dart';
import 'package:styled_divider/styled_divider.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class ChangeUsernameWidget extends StatefulWidget {
  const ChangeUsernameWidget({super.key, this.page});
  final String? page;

  @override
  State<ChangeUsernameWidget> createState() => _ChangeUsernameWidgetState();
}

class _ChangeUsernameWidgetState extends State<ChangeUsernameWidget> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
        _usernameController.text = user.username;
      });
    }
  }

  Future<void> _saveUsername() async {
    if (_currentUser == null) return;

    if (_usernameController.text.trim().isEmpty) {
      _showMessage('Username не может быть пустым');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('ChangeUsernameWidget: Обновляем username: ${_usernameController.text.trim()}');
      
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.updateUsername(_usernameController.text.trim());
      
      if (result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username успешно обновлен'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Не удалось обновить username');
      }
    } catch (e) {
      if (mounted) {
        print('ChangeUsernameWidget: Ошибка обновления username: $e');
        _showMessage('Ошибка обновления: ${e.toString().replaceFirst('Exception: ', '')}');
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

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: IntrinsicHeight(
          child: Container(
            width: 300,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white, // Белый фон для всех секций
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Align(
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.alternate_email,
                        color: Color(0xFF8B3A3A),
                        size: 200,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white, // Белый цвет для всех секций
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Text(
                                  'Username',
                                  style: TextStyle(
                                    color: Color(0xFF8C7070),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Введите username',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(20)),
                                  ),
                                  filled: true,
                                  fillColor: Color(0x00FFFFFF),
                                ),
                                style: const TextStyle(
                                  fontSize: 20,
                                  letterSpacing: 0.0,
                                  height: 1,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              const SizedBox(height: 8),
                              const StyledDivider(
                                thickness: 2,
                                color: Color(0xFF2F3F24),
                                lineStyle: DividerLineStyle.dotted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: const Color(0xFF8B3A3A),
                          minimumSize: const Size(60, 60),
                        ),
                        onPressed: _isLoading ? null : _saveUsername,
                        child: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check, color: Colors.white, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}