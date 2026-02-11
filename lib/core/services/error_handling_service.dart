import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Custom exception types for better error handling
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class AuthException extends AppException {
  AuthException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class ValidationException extends AppException {
  final Map<String, List<String>>? errors;
  
  ValidationException(String message, {this.errors, String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class ServerException extends AppException {
  ServerException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Error handling middleware service
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  /// Handle Dio errors and convert to app-specific exceptions
  AppException handleDioError(DioException error) {
    debugPrint('🔴 DIO ERROR: ${error.type}');
    debugPrint('🔴 MESSAGE: ${error.message}');
    debugPrint('🔴 RESPONSE: ${error.response?.data}');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          'No internet connection. Please check your network.',
          code: 'NO_CONNECTION',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return NetworkException(
          'Request cancelled',
          code: 'CANCELLED',
          originalError: error,
        );

      default:
        return NetworkException(
          'Network error occurred. Please try again.',
          code: 'UNKNOWN',
          originalError: error,
        );
    }
  }

  /// Handle HTTP response errors
  AppException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    debugPrint('🔴 STATUS CODE: $statusCode');
    debugPrint('🔴 RESPONSE DATA: $data');

    // Extract error message from response
    String message = 'An error occurred';
    
    if (data is Map<String, dynamic>) {
      // ✅ PARSE ASP.NET ERROR FORMAT
      // Format: { errors: { "error": ["message"], "field": ["error1", "error2"] } }
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map<String, dynamic>;
        final errorMessages = <String, List<String>>{};
        
        errors.forEach((key, value) {
          if (value is List) {
            errorMessages[key] = value.map((e) => e.toString()).toList();
          }
        });

        // ✅ Extract first error message as main message
        if (errorMessages.isNotEmpty) {
          final firstKey = errorMessages.keys.first;
          final firstError = errorMessages[firstKey]?.first;
          message = firstError ?? message;
        }

        // If it's a validation error with field-specific errors, return ValidationException
        if (errorMessages.length > 1 || !errorMessages.containsKey('error')) {
          return ValidationException(
            message,
            errors: errorMessages,
            code: 'VALIDATION_ERROR',
            originalError: error,
          );
        }
      }
      
      // Try common error message keys if errors didn't have it
      if (message == 'An error occurred') {
        message = data['message'] ?? 
                  data['error'] ?? 
                  data['title'] ??
                  data['detail'] ??
                  message;
      }
    } else if (data is String) {
      message = data;
    }

    switch (statusCode) {
      case 400:
        return ValidationException(
          message.isEmpty ? 'Invalid request data' : message,
          code: 'BAD_REQUEST',
          originalError: error,
        );

      case 401:
        return AuthException(
          message.isEmpty ? 'Unauthorized. Please login again.' : message, // ✅ Use extracted message!
          code: 'UNAUTHORIZED',
          originalError: error,
        );

      case 403:
        return AuthException(
          message.isEmpty ? 'Access forbidden. You don\'t have permission.' : message, // ✅ Use extracted message!
          code: 'FORBIDDEN',
          originalError: error,
        );

      case 404:
        return NetworkException(
          message.isEmpty ? 'Resource not found' : message, // ✅ Use extracted message!
          code: 'NOT_FOUND',
          originalError: error,
        );

      case 409:
        return ValidationException(
          message.isEmpty ? 'Conflict occurred' : message,
          code: 'CONFLICT',
          originalError: error,
        );

      case 422:
        return ValidationException(
          message.isEmpty ? 'Validation failed' : message,
          code: 'UNPROCESSABLE_ENTITY',
          originalError: error,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message.isEmpty ? 'Server error. Please try again later.' : message, // ✅ Use extracted message!
          code: 'SERVER_ERROR',
          originalError: error,
        );

      default:
        return ServerException(
          message.isEmpty ? 'An error occurred' : message,
          code: 'UNKNOWN_ERROR',
          originalError: error,
        );
    }
  }

  /// Handle generic errors
  AppException handleError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('🔴 GENERIC ERROR: $error');
    if (stackTrace != null) {
      debugPrint('🔴 STACK TRACE: $stackTrace');
    }

    if (error is DioException) {
      return handleDioError(error);
    }

    if (error is AppException) {
      return error;
    }

    // Handle other common exceptions
    if (error is FormatException) {
      return ValidationException(
        'Invalid data format',
        code: 'FORMAT_ERROR',
        originalError: error,
      );
    }

    if (error is TypeError) {
      return AppException(
        'Data type error',
        code: 'TYPE_ERROR',
        originalError: error,
      );
    }

    // Generic error
    return AppException(
      error.toString(),
      code: 'UNKNOWN',
      originalError: error,
    );
  }

  /// Get user-friendly error message
  String getUserMessage(AppException error) {
    if (error is ValidationException && error.errors != null) {
      // Combine all validation errors
      final messages = <String>[];
      error.errors!.forEach((field, errors) {
        messages.addAll(errors);
      });
      return messages.join('\n');
    }

    return error.message;
  }

  /// Check if error requires re-authentication
  bool requiresReauth(AppException error) {
    return error is AuthException && 
           (error.code == 'UNAUTHORIZED' || error.code == 'FORBIDDEN');
  }

  /// Log error (extend this to send to analytics/crash reporting)
  void logError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('📊 LOGGING ERROR: $error');
    if (stackTrace != null) {
      debugPrint('📊 STACK TRACE: $stackTrace');
    }

    // TODO: Send to analytics service (Firebase, Sentry, etc.)
    // Example:
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}