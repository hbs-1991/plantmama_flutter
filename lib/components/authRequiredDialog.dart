import 'package:flutter/material.dart';

class AuthRequiredDialog extends StatelessWidget {
  final String? title;
  final String? message;
  
  const AuthRequiredDialog({
    super.key,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, // Белый цвет для всех секций
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF8B3A3A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                color: Color(0xFF8B3A3A),
                size: 30,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Заголовок
            Text(
              title ?? 'Требуется авторизация',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B3A3A),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Описание
            Text(
              message ?? 'Для совершения этого действия необходимо зарегистрироваться или войти в аккаунт.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8B3A3A),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Кнопки
            Row(
              children: [
                // Кнопка "Позже"
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8B3A3A)),
                      foregroundColor: const Color(0xFF8B3A3A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Позже',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Кнопка "Войти"
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: Навигация на страницу входа/регистрации
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Переход на страницу авторизации...'),
                          backgroundColor: Color(0xFF8B3A3A),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B3A3A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Войти',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Ссылка на регистрацию
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Навигация на страницу регистрации
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Переход на страницу регистрации...'),
                    backgroundColor: Color(0xFF8B3A3A),
                  ),
                );
              },
              child: const Text(
                'Нет аккаунта? Зарегистрироваться',
                style: TextStyle(
                  color: Color(0xFF8B3A3A),
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}