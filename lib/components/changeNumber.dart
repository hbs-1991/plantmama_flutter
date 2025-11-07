import 'package:flutter/material.dart';
import 'package:styled_divider/styled_divider.dart';
import '../services/interfaces/i_auth_service.dart';
import '../di/locator.dart';
import '../models/user.dart';

class ChangeNumberWidget extends StatefulWidget {
  const ChangeNumberWidget({super.key, this.page});
  final String? page;

  @override
  State<ChangeNumberWidget> createState() => _ChangeNumberWidgetState();
}

class _ChangeNumberWidgetState extends State<ChangeNumberWidget> {
  final TextEditingController _phoneController = TextEditingController();
  final IAuthService _authService = locator.get<IAuthService>();
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final savedUser = await _authService.getSavedUser();
    if (savedUser != null && mounted) {
      final parsed = User.fromJson(savedUser);
      setState(() {
        _currentUser = parsed;
        _phoneController.text = parsed.phone;
      });
    }
  }

  Future<void> _savePhone() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateProfile(
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Номер телефона успешно обновлен')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
                    const Align(
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.phone,
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
                                  'Phone number',
                                  style: TextStyle(
                                    color: Color(0xFF8C7070),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'TextField',
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
                              Positioned(
                                top: 10,
                                child: const StyledDivider(
                                thickness: 2,
                                color: Color(0xFF2F3F24),
                                lineStyle: DividerLineStyle.dotted,
                              ),
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
                          backgroundColor: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFF8B3A3A),
                          minimumSize: const Size(60, 60),
                        ),
                        onPressed: _isLoading ? null : _savePhone,
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
