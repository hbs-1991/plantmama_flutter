import 'package:flutter/material.dart';
import 'package:styled_divider/styled_divider.dart';
import '../services/interfaces/i_auth_service.dart';
import '../di/locator.dart';
import '../utils/password_utils.dart';

class ChangePasswordWidget extends StatefulWidget {
  const ChangePasswordWidget({super.key, this.page});
  final String? page;

  @override
  State<ChangePasswordWidget> createState() => _ChangePasswordWidgetState();
}

class _ChangePasswordWidgetState extends State<ChangePasswordWidget> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();
  final IAuthService _authService = locator.get<IAuthService>();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _repeatPasswordController.text.isEmpty) {
      _showMessage('Заполните все поля');
      return;
    }

    if (_newPasswordController.text != _repeatPasswordController.text) {
      _showMessage('Пароли не совпадают');
      return;
    }

    final passwordError = PasswordUtils.getPasswordValidationError(_newPasswordController.text);
    if (passwordError != null) {
      _showMessage(passwordError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _repeatPasswordController.text,
      );

      if (!success) {
        if (mounted) {
          _showMessage('Не удалось изменить пароль');
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароль успешно изменен')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
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

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
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
              color: widget.page == 'plants' ? const Color(0xFFE8F5E8) : const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.lock,
                        color: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
                        size: 40,
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
                                  'Old password',
                                  style: TextStyle(
                                    color: Color(0xFF8C7070),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: _oldPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  isDense: true,
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
                                  'New password',
                                  style: TextStyle(
                                    color: Color(0xFF8C7070),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  isDense: true,
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
                                  'Rewrite the new password',
                                  style: TextStyle(
                                    color: Color(0xFF8C7070),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: _repeatPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  isDense: true,
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
                        onPressed: _isLoading ? null : _changePassword,
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
