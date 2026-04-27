import 'package:flutter/material.dart';
import 'package:orders_mobile/core/services/error_handling_service.dart';
import 'package:orders_mobile/core/utils/app_notification.dart';
import '../theme/app_colors.dart';

/// Global error handler mixin for widgets
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  final ErrorHandlingService _errorService = ErrorHandlingService();

  /// Handle error and show appropriate UI feedback
  void handleError(
    dynamic error, {
    bool showSnackBar = true,
    VoidCallback? onRetry,
    VoidCallback? onAuthRequired,
  }) {
    final appException =
        error is AppException ? error : _errorService.handleError(error);

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

    AppNotification.error(context, message);
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
      return 'Connection issue';
    } else if (error is AuthException) {
      return 'Please sign in again';
    } else if (error is ValidationException) {
      return 'Please check your input';
    } else if (error is ServerException) {
      return 'Service unavailable';
    }
    return 'Something went wrong';
  }
}
