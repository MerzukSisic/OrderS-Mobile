import 'package:flutter/material.dart';
import '../../../routes/app_router.dart';

// Unused — password reset is handled by ForgotPasswordScreen
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, AppRouter.forgotPassword);
    });
    return const SizedBox.shrink();
  }
}
