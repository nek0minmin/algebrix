import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/services/sound_service.dart';
import 'package:algebrix/widgets/app_input_field.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/password_strength_checklist.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/xy_mascot.dart';

/// Changes the password of an already signed-in learner.
///
/// Separate from the forgot-password recovery flow: the current password is
/// re-verified here, and the learner stays signed in afterwards.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Mirrors the rules enforced on the sign-up and recovery screens.
  String? _validateNewPassword(String password) {
    if (password.isEmpty) return 'Please enter a new password';
    if (password.length < 8) return 'Password must be at least 8 characters long';
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

  Future<void> _handleSubmit() async {
    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    var currentError = current.isEmpty ? 'Please enter your current password' : null;
    final newError = _validateNewPassword(next);
    String? confirmError;

    if (confirm.isEmpty) {
      confirmError = 'Please confirm your new password';
    } else if (confirm != next) {
      confirmError = 'Passwords do not match';
    }

    if (currentError == null && newError == null && current == next) {
      currentError = 'Your new password must be different from the current one';
    }

    if (currentError != null || newError != null || confirmError != null) {
      setState(() {
        _currentPasswordError = currentError;
        _newPasswordError = newError;
        _confirmPasswordError = confirmError;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.changePassword(
      currentPassword: current,
      newPassword: next,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      SoundService.playComplete();
      showAlgebrixSnackBar(
        context,
        message: 'Password updated. You are still signed in.',
        icon: Icons.lock_rounded,
      );
      Navigator.of(context).pop();
    } else {
      final message =
          authProvider.errorMessage ?? 'Could not update your password.';
      final isCurrentPasswordProblem =
          message.toLowerCase().contains('current password');
      setState(() {
        _currentPasswordError = isCurrentPasswordProblem ? message : null;
      });
      showAlgebrixSnackBar(context, message: message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AlgebrixAppBar(
        title: 'Change Password',
        subtitle: 'You will stay signed in',
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      XyMascot(asset: AppAssets.xyQuestion, size: 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enter your current password first, then choose a new one.',
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  AppInputField(
                    key: const Key('change-password-current-field'),
                    label: 'Current password',
                    controller: _currentPasswordController,
                    hintText: 'Your current password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    errorText: _currentPasswordError,
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 16),

                  AppInputField(
                    key: const Key('change-password-new-field'),
                    label: 'New password',
                    controller: _newPasswordController,
                    hintText: 'Your new password',
                    prefixIcon: Icons.lock_rounded,
                    isPassword: true,
                    errorText: _newPasswordError,
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 10),
                  PasswordStrengthChecklist(
                    password: _newPasswordController.text,
                  ),
                  const SizedBox(height: 12),

                  AppInputField(
                    key: const Key('change-password-confirm-field'),
                    label: 'Confirm new password',
                    controller: _confirmPasswordController,
                    hintText: 'Re-enter your new password',
                    prefixIcon: Icons.lock_reset_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    errorText: _confirmPasswordError,
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 28),

                  PrimaryButton(
                    key: const Key('change-password-submit-button'),
                    label: 'Update Password',
                    icon: Icons.check_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _handleSubmit,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Forgot your current password? Log out and use '
                    '"Forgot Password" on the sign-in screen.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
