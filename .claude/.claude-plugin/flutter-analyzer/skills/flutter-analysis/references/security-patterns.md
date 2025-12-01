# Flutter Security Patterns

Comprehensive catalog of security vulnerabilities and remediation in Flutter/Dart applications.

## Secrets and API Keys

### Hardcoded Credentials

**Vulnerability**: API keys, passwords, or tokens embedded directly in source code.

**Detection Patterns**:
```dart
// Look for these patterns
const apiKey = "...";
final String secret = "...";
'Authorization': 'Bearer hardcoded-token'
FirebaseOptions(apiKey: "AIza...")
```

**Remediation**:
```dart
// Option 1: Compile-time environment variables
const apiKey = String.fromEnvironment('API_KEY');

// Option 2: Secure storage at runtime
final storage = FlutterSecureStorage();
final apiKey = await storage.read(key: 'api_key');

// Option 3: Backend proxy (best for mobile)
// Never expose keys to client - route through your backend
```

### Firebase Configuration Exposure

**Vulnerability**: Firebase config in version control.

**Detection**:
- Check for `google-services.json` or `GoogleService-Info.plist` in lib/
- Look for `FirebaseOptions` with hardcoded values

**Remediation**:
- Use `--dart-define` for Firebase config
- Add config files to `.gitignore`
- Use Firebase App Check for additional protection

## Insecure Data Storage

### SharedPreferences for Sensitive Data

**Vulnerability**: Storing tokens, passwords, or PII in SharedPreferences (unencrypted).

**Detection**:
```dart
SharedPreferences.getInstance().then((prefs) {
  prefs.setString('auth_token', token);  // DANGEROUS
  prefs.setString('user_password', pw);   // CRITICAL
});
```

**Remediation**:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

await storage.write(key: 'auth_token', value: token);
```

### SQLite Without Encryption

**Vulnerability**: Unencrypted local database with sensitive data.

**Detection**:
```dart
openDatabase('app.db');  // Unencrypted
```

**Remediation**:
```dart
// Use sqlcipher_flutter_libs for encryption
import 'package:sqflite_sqlcipher/sqflite.dart';

final db = await openDatabase(
  'app.db',
  password: encryptionKey,
);
```

## Network Security

### HTTP Without TLS

**Vulnerability**: Transmitting data over unencrypted HTTP.

**Detection**:
```dart
http.get(Uri.parse('http://...'));
Dio()..options.baseUrl = 'http://...';
```

**Remediation**:
- Always use HTTPS
- On Android, configure `network_security_config.xml`
- On iOS, ensure proper ATS configuration

### Disabled Certificate Validation

**Vulnerability**: Accepting any SSL certificate, enabling MITM attacks.

**Detection**:
```dart
HttpClient()
  ..badCertificateCallback = (cert, host, port) => true;

// Or in Dio
(dio.httpClientAdapter as DefaultHttpClientAdapter)
  .onHttpClientCreate = (client) {
    client.badCertificateCallback = (_, __, ___) => true;
  };
```

**Remediation**:
```dart
// Use certificate pinning
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

final isValid = await HttpCertificatePinning.check(
  serverURL: 'https://api.example.com',
  sha: SHA.SHA256,
  allowedSHAFingerprints: ['...'],
);
```

### Missing Certificate Pinning

**Vulnerability**: No protection against compromised CAs.

**Remediation**:
```dart
// Using Dio with certificate pinning
class CertificatePinningInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Verify certificate fingerprint
  }
}
```

## Input Validation

### SQL Injection

**Vulnerability**: Unsanitized user input in database queries.

**Detection**:
```dart
db.rawQuery("SELECT * FROM users WHERE name = '$userInput'");
```

**Remediation**:
```dart
db.query('users', where: 'name = ?', whereArgs: [userInput]);
```

### Path Traversal

**Vulnerability**: User-controlled file paths without validation.

**Detection**:
```dart
File('${appDir}/${userInput}').readAsString();
```

**Remediation**:
```dart
final sanitized = path.basename(userInput);
final file = File(path.join(appDir, sanitized));

// Verify resolved path is within allowed directory
if (!file.path.startsWith(appDir)) {
  throw SecurityException('Path traversal detected');
}
```

### WebView JavaScript Injection

**Vulnerability**: Executing untrusted JavaScript in WebViews.

**Detection**:
```dart
WebView(
  javascriptMode: JavascriptMode.unrestricted,
  onWebViewCreated: (controller) {
    controller.evaluateJavascript(userInput);  // DANGEROUS
  },
);
```

**Remediation**:
- Sanitize all JavaScript input
- Use `javascriptChannels` for controlled communication
- Consider `flutter_inappwebview` with CSP headers

## Authentication & Authorization

### Insecure Token Storage

**Vulnerability**: Storing auth tokens in accessible locations.

**Best Practices**:
```dart
// Use biometric protection
final storage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.when_unlocked_this_device_only,
  ),
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);
```

### Missing Session Timeout

**Vulnerability**: Sessions that never expire.

**Remediation**:
```dart
class AuthService {
  static const sessionTimeout = Duration(hours: 24);

  Future<void> checkSession() async {
    final lastActivity = await _storage.read(key: 'last_activity');
    if (DateTime.now().difference(lastActivity) > sessionTimeout) {
      await logout();
    }
  }
}
```

### Weak Password Validation

**Vulnerability**: Accepting weak passwords.

**Remediation**:
```dart
bool isPasswordStrong(String password) {
  return password.length >= 12 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password) &&
      RegExp(r'[!@#$%^&*]').hasMatch(password);
}
```

## Platform Channel Security

### Unvalidated Platform Channel Data

**Vulnerability**: Trusting data from native code without validation.

**Detection**:
```dart
final result = await platform.invokeMethod('getData');
// Using result directly without validation
```

**Remediation**:
```dart
final result = await platform.invokeMethod('getData');

// Validate type and content
if (result is! Map<String, dynamic>) {
  throw SecurityException('Invalid data format');
}

final validated = MyData.fromJson(result);
```

## Logging and Debugging

### Sensitive Data in Logs

**Vulnerability**: Logging passwords, tokens, or PII.

**Detection**:
```dart
print('User logged in with password: $password');
debugPrint('Token: $authToken');
log('Credit card: ${card.number}');
```

**Remediation**:
```dart
// Use a production-safe logger
class SecureLogger {
  void log(String message, {bool sensitive = false}) {
    if (kReleaseMode && sensitive) return;
    // Log redacted version
  }
}
```

### Debug Mode in Production

**Vulnerability**: Debug flags left enabled.

**Detection**:
```dart
assert(() { debugPaintSizeEnabled = true; return true; }());
// Or
const isDebug = true;  // Hardcoded debug flag
```

**Remediation**:
```dart
// Use kReleaseMode/kDebugMode from foundation
if (kDebugMode) {
  debugPaintSizeEnabled = true;
}
```

## Checklist

Use this checklist when reviewing Flutter code security:

- [ ] No hardcoded API keys or secrets
- [ ] Sensitive data uses flutter_secure_storage
- [ ] All HTTP calls use HTTPS
- [ ] Certificate pinning implemented for sensitive APIs
- [ ] Input validation for all user data
- [ ] SQL queries use parameterized statements
- [ ] WebViews sanitize JavaScript
- [ ] Auth tokens stored securely with timeout
- [ ] No sensitive data in logs
- [ ] Debug code removed in production builds
- [ ] Platform channels validate all data
- [ ] Firebase security rules reviewed
