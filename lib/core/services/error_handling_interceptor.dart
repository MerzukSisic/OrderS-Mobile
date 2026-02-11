import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'error_handling_service.dart';

/// Dio interceptor for automatic error handling and logging
class ErrorHandlingInterceptor extends Interceptor {
  final ErrorHandlingService _errorService = ErrorHandlingService();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('🌐 REQUEST: ${options.method} ${options.path}');
    debugPrint('🌐 HEADERS: ${options.headers}');
    if (options.data != null) {
      debugPrint('🌐 DATA: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
    debugPrint('✅ DATA: ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('❌ ERROR: ${err.requestOptions.path}');
    
    // Convert DioException to AppException
    final appException = _errorService.handleDioError(err);
    
    // Log the error
    _errorService.logError(appException);
    
    // Pass the original error to the handler
    // The calling code can catch and handle AppException
    super.onError(err, handler);
  }
}