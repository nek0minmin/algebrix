import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/widgets/app_input_field.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/screens/auth/register_screen.dart';
import 'package:algebrix/screens/auth/forgot_password_screen.dart';
import 'package:algebrix/navigation/main_shell.dart';

/// Clean, Minimalist Login Screen for Algebrix featuring official Algebrix mascot logo,
/// rounded input fields, and email authentication.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool isValid = true;
    if (email.isEmpty) {
      setState(() => _emailError = 'Email address is required');
      isValid = false;
    } else if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'Please enter a valid email address');
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      isValid = false;
    }

    if (!isValid) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(email: email, password: password);

    if (mounted) {
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        showAlgebrixSnackBar(
          context,
          message: authProvider.errorMessage ?? 'Incorrect email or password. Please try again.',
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Official Algebrix Logo Asset Image (Not Summation Icon)
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
                  const SizedBox(height: 10),
                  Text(
                    'ALGEBRIX',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.text, // Bold Black text
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore the Whys',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle2.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Email Input Field (Fully Rounded Pill with Pink Mail Icon)
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

                  // Password Input Field (Fully Rounded Pill with Pink Lock Icon and Visibility Toggle)
                  AppInputField(
                    hintText: 'Password',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    errorText: _passwordError,
                    onFieldSubmitted: (_) => _handleLogin(),
                    onChanged: (_) {
                      if (_passwordError != null) setState(() => _passwordError = null);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Remember Me & Forgot Password Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: authProvider.rememberMe,
                            activeColor: AppColors.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                authProvider.setRememberMe(val);
                              }
                            },
                          ),
                          Text(
                            'Remember Me',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.text,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.pink,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Primary Login CTA Button
                  PrimaryButton(
                    label: 'Log In',
                    isLoading: authProvider.isLoading,
                    onPressed: _handleLogin,
                  ),

                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.pink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
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
