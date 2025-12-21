import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ButtonType { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  static const double _kDefaultHeight = 56;
  static const double _kTextDefaultHeight = 48;
  static const double _kBorderRadius = 12;
  static const double _kIconSpacing = 8;
  static const double _kLoaderSize = 24;
  static const double _kLoaderStrokeWidth = 2;
  static const double _kOutlinedBorderWidth = 1.5;

  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? icon;
  final double? height;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height = _kDefaultHeight,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;
    final Widget content = _buildContent();

    switch (type) {
      case ButtonType.primary:
        return _wrapSized(
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kBorderRadius),
              ),
              elevation: 0,
            ),
            child: content,
          ),
        );

      case ButtonType.secondary:
        return _wrapSized(
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.secondary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kBorderRadius),
              ),
              elevation: 0,
            ),
            child: content,
          ),
        );

      case ButtonType.outlined:
        return _wrapSized(
          child: OutlinedButton(
            onPressed: effectiveOnPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(
                color: AppColors.primary,
                width: _kOutlinedBorderWidth,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kBorderRadius),
              ),
            ),
            child: content,
          ),
        );

      case ButtonType.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(width ?? 0, height ?? _kTextDefaultHeight),
          ),
          child: content,
        );
    }
  }

  Widget _wrapSized({required Widget child}) {
    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : width,
      child: child,
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return SizedBox(
        height: _kLoaderSize,
        width: _kLoaderSize,
        child: CircularProgressIndicator(
          strokeWidth: _kLoaderStrokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(_progressColor()),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: _kIconSpacing),
        ],
        Text(text),
      ],
    );
  }

  Color _progressColor() {
    final bool usePrimaryColor =
        type == ButtonType.outlined || type == ButtonType.text;
    return usePrimaryColor ? AppColors.primary : Colors.white;
  }
}
