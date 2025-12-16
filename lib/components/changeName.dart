import 'package:flutter/material.dart';
import 'package:styled_divider/styled_divider.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';

/// Widget for changing user's full name.
///
/// Aligned with FastAPI backend which uses:
/// - full_name instead of first_name/last_name
class ChangeNameWidget extends StatefulWidget {
  const ChangeNameWidget({super.key, this.page});
  final String? page;

  @override
  State<ChangeNameWidget> createState() => _ChangeNameWidgetState();
}

class _ChangeNameWidgetState extends State<ChangeNameWidget> {
  final TextEditingController _fullNameController = TextEditingController();
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
        _fullNameController.text = user.fullName;
      });
    }
  }

  Future<void> _saveName() async {
    if (_currentUser == null) return;

    final fullName = _fullNameController.text.trim();

    if (fullName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      AppLogger.debug('Updating profile: fullName=$fullName', tag: 'ChangeNameWidget');

      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.updateProfile(fullName: fullName);

      AppLogger.debug('Update result: $result', tag: 'ChangeNameWidget');

      if (result == true) {
        if (mounted) {
          AppLogger.info('Profile updated successfully', tag: 'ChangeNameWidget');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        AppLogger.warning('updateProfile returned false', tag: 'ChangeNameWidget');
        throw Exception('Profile update failed');
      }
    } catch (e) {
      AppLogger.error('Profile update error', tag: 'ChangeNameWidget', error: e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
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
    _fullNameController.dispose();
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
              color: Colors.white,
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
                        Icons.person,
                        color: Color(0xFF8B3A3A),
                        size: 200,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                                  'Full Name',
                                  style: TextStyle(
                                    color: Color(0xFF8C7070),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: _fullNameController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Enter your full name',
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
                        onPressed: _isLoading ? null : _saveName,
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
