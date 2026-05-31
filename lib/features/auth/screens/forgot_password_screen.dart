import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/utils/validators.dart';
import '../../../routes/app_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _showPasswordHelp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _showPasswordHelp = true);
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().resetPassword(
          email: _emailController.text.trim(),
          newPassword: _newPasswordController.text,
        );

    if (!mounted) return;

    if (success) {
      AppNotification.success(context, 'Password changed. Please log in.');
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
    } else {
      final error = context.read<AuthProvider>().error ?? 'Password reset failed';
      AppNotification.error(context, error);
    }
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Password must contain at least one uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Password must contain at least one lowercase letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Password must contain at least one number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: _showPasswordHelp
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Reset Your Password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email and a new password.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                onChanged: (_) {
                  if (_showPasswordHelp) setState(() {});
                },
                validator: _validatePassword,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _PasswordRequirements(
                  password: _newPasswordController.text,
                  visible: _showPasswordHelp || _newPasswordController.text.isNotEmpty,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) =>
                    v != _newPasswordController.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (context, auth, _) => ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Reset Password', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  final String password;
  final bool visible;

  const _PasswordRequirements({required this.password, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final items = [
      ('At least 8 characters', password.length >= 8),
      ('At least one uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
      ('At least one lowercase letter', RegExp(r'[a-z]').hasMatch(password)),
      ('At least one number', RegExp(r'\d').hasMatch(password)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final ok = item.$2;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: ok ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.$1,
                  style: TextStyle(
                    color: ok ? AppColors.success : AppColors.error.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
