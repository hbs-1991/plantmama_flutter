class PasswordUtils {
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
    print('PasswordUtils: Проверяем пароль: "$password"');
    print('PasswordUtils: Длина пароля: ${password.length}');
    
    if (password.length < 8) {
      print('PasswordUtils: Пароль слишком короткий');
      return 'Пароль должен содержать минимум 8 символов';
    }
    
    final hasLowercase = RegExp(r'[a-z]');
    final hasUppercase = RegExp(r'[A-Z]');
    final hasDigit = RegExp(r'\d');
    final hasSpecial = RegExp(r'[^A-Za-z0-9]');
    
    final lowercaseMatch = hasLowercase.hasMatch(password);
    final uppercaseMatch = hasUppercase.hasMatch(password);
    final digitMatch = hasDigit.hasMatch(password);
    final specialMatch = hasSpecial.hasMatch(password);
    
    print('PasswordUtils: Строчные буквы: $lowercaseMatch');
    print('PasswordUtils: Заглавные буквы: $uppercaseMatch');
    print('PasswordUtils: Цифры: $digitMatch');
    print('PasswordUtils: Специальные символы: $specialMatch');
    
    if (!lowercaseMatch) {
      return 'Пароль должен содержать хотя бы одну строчную букву';
    }
    if (!uppercaseMatch) {
      return 'Пароль должен содержать хотя бы одну заглавную букву';
    }
    if (!digitMatch) {
      return 'Пароль должен содержать хотя бы одну цифру';
    }
    if (!specialMatch) {
      return 'Пароль должен содержать хотя бы один специальный символ';
    }
    return null;
  }
}


