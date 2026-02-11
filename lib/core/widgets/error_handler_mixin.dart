import 'package:flutter/material.dart';
import 'package:orders_mobile/core/services/error_handling_service.dart';
import '../theme/app_colors.dart';

/// Global error handler mixin for widgets
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  final ErrorHandlingService _errorService = ErrorHandlingService();

  /// Handle error and show appropriate UI feedback
  void handleError(dynamic error, {
    bool showSnackBar = true,
    VoidCallback? onRetry,
    VoidCallback? onAuthRequired,
  }) {
    final appException = error is AppException 
        ? error 
        : _errorService.handleError(error);

    // Log the error
    _errorService.logError(appException);

    // Check if re-authentication is needed
    if (_errorService.requiresReauth(appException)) {
      if (onAuthRequired != null) {
        onAuthRequired();
      } else {
        _showAuthRequiredDialog();
      }
      return;
    }

    // Show error message
    if (showSnackBar && mounted) {
      _showErrorSnackBar(appException, onRetry: onRetry);
    }
  }

  void _showErrorSnackBar(AppException error, {VoidCallback? onRetry}) {
    final message = _errorService.getUserMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error),
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error),
        behavior: SnackBarBehavior.floating,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: AppColors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.error),
            SizedBox(width: 12),
            Text('Authentication Required'),
          ],
        ),
        content: const Text(
          'Your session has expired. Please login again to continue.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login - implement based on your routing
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  IconData _getErrorIcon(AppException error) {
    if (error is NetworkException) {
      return Icons.wifi_off;
    } else if (error is AuthException) {
      return Icons.lock_outline;
    } else if (error is ValidationException) {
      return Icons.error_outline;
    } else if (error is ServerException) {
      return Icons.cloud_off;
    }
    return Icons.warning;
  }

  Color _getErrorColor(AppException error) {
    if (error is NetworkException) {
      return AppColors.warning;
    } else if (error is AuthException) {
      return AppColors.error;
    } else if (error is ValidationException) {
      return AppColors.warning;
    } else if (error is ServerException) {
      return AppColors.error;
    }
    return AppColors.error;
  }
}

/// Reusable error display widget
class ErrorDisplay extends StatelessWidget {
  final AppException error;
  final VoidCallback? onRetry;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              ErrorHandlingService().getUserMessage(error),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    if (error is NetworkException) {
      return Icons.wifi_off;
    } else if (error is AuthException) {
      return Icons.lock_outline;
    } else if (error is ValidationException) {
      return Icons.error_outline;
    } else if (error is ServerException) {
      return Icons.cloud_off;
    }
    return Icons.warning;
  }

  String _getErrorTitle() {
    if (error is NetworkException) {
      return 'Connection Error';
    } else if (error is AuthException) {
      return 'Authentication Error';
    } else if (error is ValidationException) {
      return 'Validation Error';
    } else if (error is ServerException) {
      return 'Server Error';
    }
    return 'Error';
  }
}