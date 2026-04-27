import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.placeholder,
  });

  static String? normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static Uint8List? bytesFromDataUrl(String value) {
    final normalized = normalize(value);
    if (normalized == null) return null;

    final commaIndex = normalized.indexOf(',');
    final payload = normalized.startsWith('data:image/') && commaIndex != -1
        ? normalized.substring(commaIndex + 1)
        : normalized;

    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalize(imageUrl);
    final fallback = placeholder ??
        const Icon(
          Icons.restaurant,
          color: AppColors.textDisabled,
          size: 34,
        );

    Widget child;
    final bytes = normalized == null ? null : bytesFromDataUrl(normalized);
    if (bytes != null) {
      child = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (normalized != null) {
      child = Image.network(
        normalized,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      child = fallback;
    }

    child = SizedBox(
      width: width,
      height: height,
      child: child,
    );

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}
