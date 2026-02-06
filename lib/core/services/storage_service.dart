import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();
  
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token'; // ← DODAJ
  static const String _keyUserData = 'user_data';

  // Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  // Refresh Token ← DODAJ OVE METODE
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  // User Data
  Future<String?> getUserData() async {
    return await _storage.read(key: _keyUserData);
  }

  Future<void> saveUserData(String userData) async {
    await _storage.write(key: _keyUserData, value: userData);
  }

  // Clear All
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
