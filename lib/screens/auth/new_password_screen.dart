import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/widgets/app_input_field.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/password_strength_checklist.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/screens/auth/login_screen.dart';

/// Step 3 of Password Recovery: Set New Password Screen
/// (Unlocked ONLY after 6-digit OTP is validated in Step 2).
class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Please enter a new password';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least 1 uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least 1 lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least 1 number';
    }
    return null;
  }

  void _handleUpdatePassword() async {
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool isValid = true;

    _passwordError = _validatePassword(password);
    if (_passwordError != null) {
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm your new password';
      isValid = false;
    } else if (confirmPassword != password) {
      _confirmPasswordError = 'Passwords do not match';
      isValid = false;
    }

    if (!isValid) {
      setState(() {});
      return;
    }

    final authProvider = context.read<AuthProvider>();
    // Submitting updates password via client.auth.updateUser and logs out temporary session
    final success = await authProvider.updatePassword(password);

    if (mounted) {
      if (success) {
        _showSuccessDialog();
      } else {
        showAlgebrixSnackBar(
          context,
          message: authProvider.errorMessage ?? 'Failed to update password. Please try again.',
          isError: true,
        );
      }
    }
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutBack.transform(animation.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: animation.value,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              contentPadding: const EdgeInsets.all(28),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.lightMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.mint,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Password Updated! 🎉',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your password has been successfully updated. Please log in with your new password.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle2.copyWith(
                      color: AppColors.subtitle,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Back to Login',
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Algebrix Logo Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: Image.asset(
                      AppAssets.logo,
                      width: 84.0,
                      height: 84.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Set New Password',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your 6-digit OTP code has been verified!\nCreate a new strong password for ${widget.email}.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // New Password Field
                AppInputField(
                  label: 'New Password',
                  hintText: 'Enter new password',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  errorText: _passwordError,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),

                // Live Strength Checklist
                PasswordStrengthChecklist(password: _passwordController.text),
                const SizedBox(height: 16),

                // Confirm New Password Field
                AppInputField(
                  label: 'Confirm New Password',
                  hintText: 'Re-enter new password',
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_reset_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  errorText: _confirmPasswordError,
                  onFieldSubmitted: (_) => _handleUpdatePassword(),
                  onChanged: (_) {
                    if (_confirmPasswordError != null) {
                      setState(() => _confirmPasswordError = null);
                    }
                  },
                ),
                const SizedBox(height: 28),

                PrimaryButton(
                  label: 'Update Password',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleUpdatePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
