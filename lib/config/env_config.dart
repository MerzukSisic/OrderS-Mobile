import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _signalRUrl = String.fromEnvironment('SIGNALR_URL');
  static const String _stripeKey =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  static String get baseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5220/api';
    }
    return 'http://localhost:5220/api';
  }

  static String get signalRUrl {
    if (_signalRUrl.isNotEmpty) return _signalRUrl;
    final fromEnv = dotenv.maybeGet('SIGNALR_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5220/hubs/orders';
    }
    return 'http://localhost:5220/hubs/orders';
  }

  static String get stripePublishableKey {
    if (_stripeKey.isNotEmpty) return _stripeKey;
    return dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ?? '';
  }
}
