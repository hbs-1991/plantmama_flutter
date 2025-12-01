import 'dart:math';

class PasswordUtils {
  static const _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _digits = '0123456789';
  static const _special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  /// Generates a cryptographically secure random password
  static String generateSecurePassword({int length = 16}) {
    final random = Random.secure();
    final allChars = _lowercase + _uppercase + _digits + _special;

    // Ensure at least one of each required character type
    final password = StringBuffer();
    password.write(_lowercase[random.nextInt(_lowercase.length)]);
    password.write(_uppercase[random.nextInt(_uppercase.length)]);
    password.write(_digits[random.nextInt(_digits.length)]);
    password.write(_special[random.nextInt(_special.length)]);

    // Fill the rest with random characters
    for (var i = 4; i < length; i++) {
      password.write(allChars[random.nextInt(allChars.length)]);
    }

    // Shuffle the password characters
    final chars = password.toString().split('');
    chars.shuffle(random);
    return chars.join();
  }

  static bool isPasswordComplex(String password) {
    if (password.length < 8) return false;
    final hasLowercase = RegExp(r'[a-z]');
    final hasUppercase = RegExp(r'[A-Z]');
    final hasDigit = RegExp(r'\d');
    final hasSpecial = RegExp(r'[^A-Za-z0-9]');
    return hasLowercase.hasMatch(password) &&
        hasUppercase.hasMatch(password) &&
        hasDigit.hasMatch(password) &&
        hasSpecial.hasMatch(password);
  }

  static String? getPasswordValidationError(String password) {
    if (password.length < 8) {
      return 'Пароль должен содержать минимум 8 символов';
    }

    final hasLowercase = RegExp(r'[a-z]');
    final hasUppercase = RegExp(r'[A-Z]');
    final hasDigit = RegExp(r'\d');
    final hasSpecial = RegExp(r'[^A-Za-z0-9]');

    if (!hasLowercase.hasMatch(password)) {
      return 'Пароль должен содержать хотя бы одну строчную букву';
    }
    if (!hasUppercase.hasMatch(password)) {
      return 'Пароль должен содержать хотя бы одну заглавную букву';
    }
    if (!hasDigit.hasMatch(password)) {
      return 'Пароль должен содержать хотя бы одну цифру';
    }
    if (!hasSpecial.hasMatch(password)) {
      return 'Пароль должен содержать хотя бы один специальный символ';
    }
    return null;
  }
}


