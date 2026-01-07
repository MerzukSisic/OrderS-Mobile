import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/auth_response.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../core/constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthProvider(this._apiService, this._storageService);

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isWaiter => _user?.isWaiter ?? false;
  bool get isBartender => _user?.isBartender ?? false;

  // Initialize - Check if user is already logged in
  Future<void> init() async {
    try {
      final userData = await _storageService.getUserData();
      if (userData != null) {
        final json = jsonDecode(userData);
        _user = UserModel.fromJson(json);
        
        // DODAJ: Load token u ApiService cache
        final token = await _storageService.getAccessToken();
        if (token != null) {
          await _apiService.saveToken(token);
        }
        
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post(
        ApiConstants.login,
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response != null) {
        final authResponse = AuthResponse.fromJson(response);

        // Save token to StorageService
        await _storageService.saveAccessToken(authResponse.accessToken);
        
        // DODAJ: Save token to ApiService cache
        await _apiService.saveToken(authResponse.accessToken);

        // Create user model
        _user = UserModel(
          id: authResponse.userId,
          fullName: authResponse.fullName,
          email: authResponse.email,
          role: authResponse.role,
          isActive: true,
          createdAt: DateTime.now(),
        );

        // Save user data
        await _storageService.saveUserData(jsonEncode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } on UnauthorizedException {
      _error = 'Invalid email or password';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post(
        ApiConstants.register,
        body: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'role': 'Waiter',
        },
      );

      if (response != null) {
        final authResponse = AuthResponse.fromJson(response);

        // Save token to StorageService
        await _storageService.saveAccessToken(authResponse.accessToken);
        
        // DODAJ: Save token to ApiService cache
        await _apiService.saveToken(authResponse.accessToken);

        _user = UserModel(
          id: authResponse.userId,
          fullName: authResponse.fullName,
          email: authResponse.email,
          role: authResponse.role,
          phoneNumber: phoneNumber,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await _storageService.saveUserData(jsonEncode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _user = null;
    await _apiService.clearToken();
    await _storageService.clearAll();
    notifyListeners();
  }

  // Check Authentication
  Future<bool> checkAuth() async {
    try {
      await init();
      return _user != null;
    } catch (e) {
      return false;
    }
  }

  // Clear Error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}