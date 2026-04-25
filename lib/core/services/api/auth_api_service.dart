import 'package:orders_mobile/core/api/api_client.dart';
import 'package:orders_mobile/models/auth/auth_response.dart';
import 'package:orders_mobile/models/auth/user_model.dart';

class AuthApiService {
  final ApiClient _client = ApiClient();

  /// Login
  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    return await _client.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      fromJson: (json) => AuthResponse.fromJson(json),
    );
  }

  /// Register
  Future<ApiResponse<AuthResponse>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    return await _client.post(
      '/auth/register',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
        'phoneNumber': phoneNumber,
      },
      fromJson: (json) => AuthResponse.fromJson(json),
    );
  }

  /// Validate token
  Future<ApiResponse<bool>> validateToken(String token) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/validate',
      data: {'token': token},
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!['isValid'] as bool);
    }

    return ApiResponse.failure(response.error ?? 'Token validation failed');
  }

  /// Refresh token
  Future<ApiResponse<AuthResponse>> refreshToken(String refreshToken) async {
    return await _client.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      fromJson: (json) => AuthResponse.fromJson(json),
    );
  }

  /// Logout
  Future<ApiResponse<void>> logout() async {
    return await _client.post('/auth/logout');
  }

  /// Change password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _client.post(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Get current user
  Future<ApiResponse<UserModel>> getCurrentUser() async {
    return await _client.get(
      '/auth/me',
      fromJson: (json) => UserModel.fromJson(json),
    );
  }

  /// Forgot password
  Future<ApiResponse<void>> forgotPassword(String email) async {
    return await _client.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  /// Reset password
  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    return await _client.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'token': token,
        'newPassword': newPassword,
      },
    );
  }
}