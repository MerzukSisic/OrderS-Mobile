import 'package:flutter/foundation.dart';
import 'package:orders_mobile/core/api/api_client.dart';
import 'package:orders_mobile/core/services/api/auth_api_service.dart';
import 'package:orders_mobile/core/services/api/api_service.dart'; // ✅ DODANO
import 'package:orders_mobile/models/auth/auth_response.dart';
import 'package:orders_mobile/models/auth/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final AuthApiService _apiService = AuthApiService();
  final ApiClient _apiClient = ApiClient();

  // State
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?.role == 'Admin';
  bool get isWaiter => _currentUser?.role == 'Waiter';
  bool get isBartender => _currentUser?.role == 'Bartender';

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  /// Initialize - Load saved credentials
  Future<void> initialize() async {
    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      final savedUserJson = prefs.getString(_userKey);

      if (savedToken != null && savedUserJson != null) {
        _token = savedToken;
        _apiClient.setToken(savedToken);
        
        // ✅ DODANO - Sync token to ApiService (http) as well
        await ApiService().saveToken(savedToken);

        // Verify token is still valid
        final response = await _apiService.validateToken(savedToken);
        
        if (response.success && response.data == true) {
          // Token valid, get current user
          final userResponse = await _apiService.getCurrentUser();
          if (userResponse.success && userResponse.data != null) {
            _currentUser = userResponse.data;
            _isAuthenticated = true;
          } else {
            // Token invalid, clear
            await _clearCredentials();
          }
        } else {
          await _clearCredentials();
        }
      }
    } catch (e) {
      debugPrint('❌ Auth initialization error: $e');
      await _clearCredentials();
    } finally {
      _setLoading(false);
    }
  }

  /// Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        await _handleAuthSuccess(response.data!);
        return true;
      } else {
        _setError(response.error ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        phoneNumber: phoneNumber,
      );

      if (response.success && response.data != null) {
        await _handleAuthSuccess(response.data!);
        return true;
      } else {
        _setError(response.error ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('❌ Logout error: $e');
    } finally {
      await _clearCredentials();
      _setLoading(false);
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (response.success) {
        return true;
      } else {
        _setError(response.error ?? 'Password change failed');
        return false;
      }
    } catch (e) {
      _setError('Password change error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    if (!_isAuthenticated) return;

    try {
      final response = await _apiService.getCurrentUser();
      if (response.success && response.data != null) {
        _currentUser = response.data;
        
        // Save updated user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, response.data!.toJson().toString());
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Refresh user error: $e');
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.forgotPassword(email);
      
      if (response.success) {
        return true;
      } else {
        _setError(response.error ?? 'Password reset request failed');
        return false;
      }
    } catch (e) {
      _setError('Password reset error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );

      if (response.success) {
        return true;
      } else {
        _setError(response.error ?? 'Password reset failed');
        return false;
      }
    } catch (e) {
      _setError('Password reset error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== PRIVATE HELPERS ==========

  Future<void> _handleAuthSuccess(AuthResponse authResponse) async {
    _token = authResponse.accessToken;
    _currentUser = UserModel(
      id: authResponse.userId,
      fullName: authResponse.fullName,
      email: authResponse.email,
      role: authResponse.role,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _isAuthenticated = true;

    // Set token in API client (Dio)
    _apiClient.setToken(_token);
    
    // ✅ DODANO - Set token in ApiService (http) as well
    await ApiService().saveToken(_token!);

    // Save to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_userKey, _currentUser!.toJson().toString());

    notifyListeners();
  }

  Future<void> _clearCredentials() async {
    _token = null;
    _currentUser = null;
    _isAuthenticated = false;
    _apiClient.clearToken();
    
    // ✅ DODANO - Clear token in ApiService (http)
    await ApiService().clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('❌ Auth Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}