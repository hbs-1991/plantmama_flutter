import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  
  static String get mapsApiKey {
    if (isWeb) {
      return 'AIzaSyD6PWDQetH3iDxlX9zv17smFeBokBKjT8o'; // Веб API ключ
    } else {
      return 'AIzaSyADXACW1i54PdylRbWeJaNijggl2lqf3po'; // Android API ключ
    }
  }
  
  static bool get shouldUseGoogleMaps {
    // В веб-версии используем Google Maps, в мобильной - простую версию
    return isWeb;
  }
} 