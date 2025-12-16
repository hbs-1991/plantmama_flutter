/// Platform-specific implementation for mobile/desktop
/// This file is used when dart:io is available

import 'dart:io' show Platform;

String getLocalBackendUrl(int port, String apiVersion) {
  if (Platform.isAndroid) {
    // Android emulator uses 10.0.2.2 to reach host machine
    return 'http://10.0.2.2:$port$apiVersion';
  } else if (Platform.isIOS) {
    // iOS simulator can use localhost directly
    return 'http://localhost:$port$apiVersion';
  } else {
    // Desktop platforms (Windows, macOS, Linux)
    return 'http://localhost:$port$apiVersion';
  }
}
