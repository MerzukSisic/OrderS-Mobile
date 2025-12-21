import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  // Initialize
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Secure Storage (for sensitive data like tokens)
  Future<void> secureWrite(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> secureRead(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> secureDelete(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> secureClearAll() async {
    await _secureStorage.deleteAll();
  }

  // Regular Storage
  Future<bool> setString(String key, String value) async {
    await init();
    return _prefs!.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<bool> setInt(String key, int value) async {
    await init();
    return _prefs!.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<bool> setBool(String key, bool value) async {
    await init();
    return _prefs!.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  // JSON Storage
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    await init();
    return _prefs!.setString(key, json.encode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final jsonString = _prefs?.getString(key);
    if (jsonString == null) return null;
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  // Clear
  Future<bool> remove(String key) async {
    await init();
    return _prefs!.remove(key);
  }

  Future<bool> clear() async {
    await init();
    return _prefs!.clear();
  }

  // Auth-specific methods
  Future<void> saveAccessToken(String token) async {
    await secureWrite('access_token', token);
  }

  Future<String?> getAccessToken() async {
    return await secureRead('access_token');
  }

  Future<void> saveUserData(String userData) async {
    await setString('user_data', userData);
  }

  Future<String?> getUserData() async {
    return getString('user_data');
  }

  Future<void> clearAll() async {
    await secureClearAll();
    await clear();
  }
}
