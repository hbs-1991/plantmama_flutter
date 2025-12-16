/// Stub implementation for web platform
/// This file is used when dart:io is not available (web)

String getLocalBackendUrl(int port, String apiVersion) {
  // This should never be called on web (kIsWeb check happens first)
  // But we provide a fallback just in case
  return 'http://localhost:$port$apiVersion';
}
