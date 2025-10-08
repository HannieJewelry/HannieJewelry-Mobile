import 'package:flutter/foundation.dart';

/// Application configuration class
/// Contains global configurations
class AppConfig {
  /// API Base URL
  static String get apiBaseUrl {
    if (kDebugMode) {
      // Real backend URL
      return 'https://nguyenhauweb.software';
    } else {
      // Production URL
      return 'https://nguyenhauweb.software';
    }
  }

  /// Timeout duration for API calls (ms)
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;
  
  /// Image configuration
  static const String placeholderImage = 'assets/images/placeholder.png';
}


