class InputSanitizer {
  static final RegExp _controlChars = RegExp(r"[\x00-\x08\x0B\x0C\x0E-\x1F]",
      unicode: false);
  static final RegExp _zeroWidth = RegExp(r"[\u200B-\u200D\uFEFF]");
  static final RegExp _htmlTags = RegExp(r"<[^>]*>");

  static String _trimAndLimit(String value, int maxLength) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return trimmed.substring(0, maxLength);
  }

  static String sanitizeString(String? input,
      {int maxLength = 255, bool allowNewlines = false}) {
    if (input == null) return '';
    String result = input;
    // Remove control and zero-width characters
    result = result.replaceAll(_controlChars, '');
    result = result.replaceAll(_zeroWidth, '');
    // Strip HTML tags
    result = result.replaceAll(_htmlTags, '');
    // Normalize whitespace
    if (allowNewlines) {
      result = result.replaceAll(RegExp(r"[\t\r]"), ' ');
      result = result.replaceAll(RegExp(r"[ ]{2,}"), ' ');
    } else {
      result = result.replaceAll(RegExp(r"\s+"), ' ');
    }
    return _trimAndLimit(result, maxLength);
  }

  static String sanitizeName(String? input, {int maxLength = 120}) {
    final base = sanitizeString(input, maxLength: maxLength);
    // Keep letters, digits, space, dash, apostrophe - simplified regex
    final cleaned = base.replaceAll(RegExp(r"[^a-zA-Zа-яА-Я0-9 \'\-]"), '');
    return _trimAndLimit(cleaned, maxLength);
  }

  static String sanitizeUsername(String? input, {int maxLength = 150}) {
    if (input == null) return '';
    String result = input.trim();
    result = result.replaceAll(_controlChars, '');
    result = result.replaceAll(_zeroWidth, '');
    result = result.replaceAll(RegExp(r"[^A-Za-z0-9._\-]"), '');
    return _trimAndLimit(result, maxLength);
  }

  static String sanitizeEmail(String? input, {int maxLength = 254}) {
    if (input == null) return '';
    String result = input.trim().toLowerCase();
    result = result.replaceAll(_controlChars, '');
    result = result.replaceAll(_zeroWidth, '');
    result = result.replaceAll(RegExp(r"\s+"), '');
    // Remove any character not allowed in RFC 5322 local-part and domain (simplified)
    result = result.replaceAll(RegExp(r"[^a-z0-9!#\$%&'*+/=?^_`{|}~@.\\-]"), '');
    return _trimAndLimit(result, maxLength);
  }

  static String sanitizePhone(String? input, {int maxLength = 32}) {
    if (input == null) return '';
    String digits = input.replaceAll(RegExp(r"[^0-9+]"), '');
    // Allow only one leading plus
    if (digits.contains('+')) {
      digits = '+' + digits.replaceAll('+', '');
    }
    return _trimAndLimit(digits, maxLength);
  }

  static String sanitizePostalCode(String? input, {int maxLength = 20}) {
    if (input == null) return '';
    String result = input.trim();
    result = result.replaceAll(RegExp(r"[^A-Za-z0-9\- ]"), '');
    result = result.replaceAll(RegExp(r"[ ]{2,}"), ' ');
    return _trimAndLimit(result, maxLength);
  }

  static String sanitizeAddressLine(String? input, {int maxLength = 200}) {
    final base = sanitizeString(input, maxLength: maxLength);
    // Allow common address punctuation - simplified regex
    final cleaned = base.replaceAll(RegExp(r"[^a-zA-Zа-яА-Я0-9 ,.\'\-/]"), '');
    return _trimAndLimit(cleaned, maxLength);
  }

  static String sanitizeAddressLabel(String? input, {int maxLength = 40}) {
    final value = (input ?? '').trim().toLowerCase();
    if (value == 'home' || value == 'work') return value;
    final cleaned = sanitizeName(input, maxLength: maxLength);
    return cleaned.isEmpty ? 'home' : cleaned;
  }

  static String sanitizePassword(String? input, {int maxLength = 256}) {
    if (input == null) return '';
    // Only trim and remove control characters; do not change content
    String result = input.replaceAll(_controlChars, '').replaceAll(_zeroWidth, '');
    return _trimAndLimit(result, maxLength);
  }

  static String sanitizeQuery(String? input, {int maxLength = 100}) {
    if (input == null) return '';
    String result = sanitizeString(input, maxLength: maxLength);
    result = result.replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9 _\-.,]'), '');
    return _trimAndLimit(result, maxLength);
  }

  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> input) {
    final Map<String, dynamic> out = {};
    input.forEach((key, value) {
      if (value is String) {
        out[key] = sanitizeString(value);
      } else if (value is Map<String, dynamic>) {
        out[key] = sanitizeMap(value);
      } else if (value is List) {
        out[key] = value.map((e) => e is String ? sanitizeString(e) : e).toList();
      } else {
        out[key] = value;
      }
    });
    return out;
  }
}


