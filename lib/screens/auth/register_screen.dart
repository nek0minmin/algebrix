import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// Clean Register Screen featuring Algebrix mascot logo, dynamic password checklist,
/// and registration action leading directly to LoginScreen.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Please enter a password';
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

  void _validateAndRegister() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool isValid = true;

    if (name.isEmpty) {
      _nameError = 'Please enter your name';
      isValid = false;
    }

    if (email.isEmpty) {
      _emailError = 'Please enter your email address';
      isValid = false;
    } else if (!email.contains('@') || !email.contains('.')) {
      _emailError = 'Please enter a valid email address';
      isValid = false;
    }

    _passwordError = _validatePassword(password);
    if (_passwordError != null) {
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
      isValid = false;
    } else if (confirmPassword != password) {
      _confirmPasswordError = 'Passwords do not match';
      isValid = false;
    }

    if (!isValid) {
      setState(() {});
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await authProvider.register(
      name: name,
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      // Log out auto-created session so user lands on Login Screen
      await authProvider.signOut();

      showAlgebrixSnackBar(
        context,
        message: 'Account created successfully! Please log in to continue. 🎉',
        isError: false,
      );

      if (navigator.canPop()) {
        navigator.pop();
      } else {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      showAlgebrixSnackBar(
        context,
        message: authProvider.errorMessage ?? 'Registration failed. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Official Algebrix Logo Asset Image
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
                  const SizedBox(height: 8),
                  Text(
                    'Create an Account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Username Field
                  AppInputField(
                    hintText: 'Username',
                    controller: _nameController,
                    prefixIcon: Icons.person_rounded,
                    textInputAction: TextInputAction.next,
                    errorText: _nameError,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email Address Field
                  AppInputField(
                    hintText: 'Email',
                    controller: _emailController,
                    prefixIcon: Icons.mail_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                    onChanged: (_) {
                      if (_emailError != null) setState(() => _emailError = null);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Create Password Field
                  AppInputField(
                    hintText: 'Create Password',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    errorText: _passwordError,
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 8),

                  // Password Criteria Live Checklist (Matching Pic 3)
                  PasswordStrengthChecklist(password: _passwordController.text),

                  const SizedBox(height: 8),

                  // Confirm Password Field
                  AppInputField(
                    hintText: 'Confirm Password',
                    controller: _confirmPasswordController,
                    prefixIcon: Icons.lock_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    errorText: _confirmPasswordError,
                    onFieldSubmitted: (_) => _validateAndRegister(),
                    onChanged: (_) {
                      if (_confirmPasswordError != null) {
                        setState(() => _confirmPasswordError = null);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Primary Create Account Button
                  PrimaryButton(
                    label: 'Create Account',
                    isLoading: authProvider.isLoading,
                    onPressed: _validateAndRegister,
                  ),

                  const SizedBox(height: 24),

                  // Link back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Log In',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.pink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
