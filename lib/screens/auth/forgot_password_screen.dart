import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/widgets/app_input_field.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/primary_button.dart';

/// Clean Password Reset Link Screen.
///
/// Sends a direct password reset link email to the user.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  String? _emailError;
  bool _isSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    setState(() => _emailError = null);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address');
      return;
    } else if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'Please enter a valid email address');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(email: email);

    if (mounted) {
      if (success) {
        setState(() {
          _isSubmitted = true;
        });
      } else {
        showAlgebrixSnackBar(
          context,
          message: authProvider.errorMessage ?? 'Failed to send reset link. Please try again.',
          isError: true,
        );
      }
    }
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
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Algebrix Mascot Logo Asset
                  Center(
                    child: Image.asset(
                      AppAssets.logo,
                      width: 84.0,
                      height: 84.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reset Password',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSubmitted
                        ? 'We sent a password reset link to your email.'
                        : "Enter your registered email address and we'll send you a link to reset your password.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_isSubmitted) ...[
                    // Success Feedback Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.lightMint,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.mint, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.mark_email_read_rounded,
                            color: AppColors.mint,
                            size: 56,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Reset Link Sent! 🎉',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We have sent password reset instructions to ${_emailController.text.trim()}.\n\nPlease check your email inbox.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Back to Login',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ] else ...[
                    // Email Input Field
                    AppInputField(
                      label: 'Email Address',
                      hintText: 'student@algebrix.org',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      errorText: _emailError,
                      onFieldSubmitted: (_) => _sendResetLink(),
                      onChanged: (val) {
                        if (_emailError != null) setState(() => _emailError = null);
                      },
                    ),
                    const SizedBox(height: 28),

                    // Primary Button
                    PrimaryButton(
                      label: 'Send Reset Link',
                      isLoading: authProvider.isLoading,
                      onPressed: _sendResetLink,
                    ),

                    const SizedBox(height: 28),

                    // Back to Login Link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: AppColors.pink,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Back to Login',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.pink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
