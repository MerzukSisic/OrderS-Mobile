import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // ✅ dart-define overrides (build-time)
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _signalRUrl = String.fromEnvironment('SIGNALR_URL');

  // 🔧 Fallback IP za lokalni development
  static const String _macIpAddress = '192.168.1.101';

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

  static String get stripePublishableKey {
    const fromBuild = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    if (fromBuild.isNotEmpty) return fromBuild;
    return dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ?? '';
  }
}
