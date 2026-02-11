import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/error_handling_interceptor.dart';
import '../services/error_handling_service.dart'; // ✅ ADD THIS

/// API Response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;
  final int? statusCode;

  ApiResponse({
    this.data,
    this.error,
    required this.success,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {int? statusCode}) {
    return ApiResponse(
      data: data,
      success: true,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.failure(String error, {int? statusCode}) {
    return ApiResponse(
      error: error,
      success: false,
      statusCode: statusCode,
    );
  }
}

/// Base API Client
class ApiClient {
  late final Dio _dio;
  String? _token;

  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  static String _getBaseUrl() {
    if (kDebugMode) {
      // Android emulator
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:5220/api';
      }
      // iOS simulator
      return 'http://localhost:5220/api';
    }
    // Production
    return 'https://your-production-url.com/api';
  }

  void _setupInterceptors() {
    // ✅ ADD ERROR HANDLING INTERCEPTOR FIRST
    _dio.interceptors.add(ErrorHandlingInterceptor());

    // Then add auth/logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }

          debugPrint('🔵 REQUEST[${options.method}] => ${options.uri}');
          debugPrint('📤 Data: ${options.data}');
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('🟢 RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
          debugPrint('📥 Data: ${response.data}');
          
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('🔴 ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}');
          debugPrint('❌ Message: ${error.message}');
          debugPrint('❌ Response: ${error.response?.data}');
          
          return handler.next(error);
        },
      ),
    );
  }

  /// Set authentication token
  void setToken(String? token) {
    _token = token;
    debugPrint('🔑 Token set: ${token != null ? "Yes" : "No"}');
  }

  /// Clear authentication token
  void clearToken() {
    _token = null;
    debugPrint('🔓 Token cleared');
  }

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = fromJson != null ? fromJson(response.data) : response.data as T;
        return ApiResponse.success(data, statusCode: response.statusCode);
      }

      return ApiResponse.failure(
        'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = fromJson != null ? fromJson(response.data) : response.data as T;
        return ApiResponse.success(responseData, statusCode: response.statusCode);
      }

      return ApiResponse.failure(
        'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.statusCode == 204 || response.data == null) {
          return ApiResponse.success(null as T, statusCode: response.statusCode);
        }
        final responseData = fromJson != null ? fromJson(response.data) : response.data as T;
        return ApiResponse.success(responseData, statusCode: response.statusCode);
      }

      return ApiResponse.failure(
        'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }

  /// DELETE request
  Future<ApiResponse<void>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null, statusCode: response.statusCode);
      }

      return ApiResponse.failure(
        'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }

  /// Handle Dio errors
  ApiResponse<T> _handleDioError<T>(DioException error) {
    // ✅ Use ErrorHandlingService to extract proper message
    final errorHandlingService = ErrorHandlingService();
    final appException = errorHandlingService.handleDioError(error);
    final userMessage = errorHandlingService.getUserMessage(appException);

    return ApiResponse.failure(
      userMessage,
      statusCode: error.response?.statusCode,
    );
  }

  /// Get Dio instance (for custom usage)
  Dio get dio => _dio;
}