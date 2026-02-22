import 'package:flutter/foundation.dart';

class EnvConfig {
  // ✅ dart-define overrides (build-time)
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _signalRUrl = String.fromEnvironment('SIGNALR_URL');

  // 🔧 Fallback IP za lokalni development
  static const String _macIpAddress = '10.101.20.141';

  static String get baseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;

    // Android emulator koristi 10.0.2.2, iOS simulator localhost
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5220/api';
    }
    return 'http://$_macIpAddress:5220/api';
  }

  static String get signalRUrl {
    if (_signalRUrl.isNotEmpty) return _signalRUrl;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5220/hubs/orders';
    }
    return 'http://$_macIpAddress:5220/hubs/orders';
  }

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51QdZsNId2FRgVkuiAMWlpLmNHw4e4igDSx3DihjKQr4m2sz5DxNGJLFJPb48SIdPvHXeKl9IxvOV4IUvsrDjCywk00jLLh7syZ',
  );
}
