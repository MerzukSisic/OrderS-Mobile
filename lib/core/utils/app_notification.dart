import 'package:flutter/material.dart';

import 'top_notification.dart';
import 'user_message.dart';

class AppNotification {
  static void success(BuildContext context, String message) {
    show(context, message);
  }

  static void error(BuildContext context, String message) {
    show(context, message, isError: true);
  }

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    TopNotification.show(
      context,
      message: isError ? UserMessage.friendly(message) : message,
      isError: isError,
    );
  }
}
