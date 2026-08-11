import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/screens/auth/login_screen.dart';
import 'package:algebrix/screens/auth/new_password_screen.dart';

/// 6-Digit OTP Verification Screen featuring:
/// - 6 individual PIN input boxes with smooth focus auto-traversal, paste, and backspace support
/// - 2-minute (120-second) resend countdown timer with responsive resend trigger
/// - Step 2 of Password Recovery: Navigates to [NewPasswordScreen] ONLY after 6-digit OTP is validated!
class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final bool isPasswordReset;
  final VoidCallback? onVerified;
  final String? title;
  final String? subtitle;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
    this.onVerified,
    this.title,
    this.subtitle,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  static const int _codeLength = 6;
  static const int _initialTimerSeconds = 120; // 2 minutes

  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  Timer? _timer;
  int _remainingSeconds = _initialTimerSeconds;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });

    _startCountdownTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _initialTimerSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _resendCode() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    for (var c in _controllers) {
      c.clear();
    }

    final authProvider = context.read<AuthProvider>();
    bool success = false;

    try {
      if (widget.isPasswordReset) {
        success = await authProvider.resetPassword(email: widget.email);
      } else {
        success = await authProvider.resendOTP(email: widget.email);
      }
    } catch (_) {
      success = false;
    }

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    // Reset timer and focus field
    _focusNodes[0].requestFocus();
    _startCountdownTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Verification OTP code re-sent to ${widget.email}'
              : (authProvider.errorMessage ?? 'Verification code re-sent! Please check your inbox.'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: success ? AppColors.mint : AppColors.pink,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _onPinChanged(int index, String value) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < _codeLength; i++) {
        if (i < digits.length) {
          _controllers[i].text = digits[i];
        }
      }
      if (digits.length >= _codeLength) {
        _focusNodes[_codeLength - 1].unfocus();
        _verifyCode();
      } else {
        _focusNodes[digits.length].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    }
  }

  void _onPinKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  String get _currentPin => _controllers.map((c) => c.text).join();

  void _verifyCode() async {
    final pin = _currentPin;
    if (pin.length < _codeLength) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits of the OTP code.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();

    if (widget.isPasswordReset) {
      final success = await authProvider.verifyOTP(
        email: widget.email,
        token: pin,
        type: OtpType.recovery,
      );

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => NewPasswordScreen(email: widget.email),
          ),
        );
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ??
              'Invalid or expired 6-digit OTP code. Please try again.';
        });
      }
    } else {
      final success = await authProvider.verifyOTP(
        email: widget.email,
        token: pin,
        type: OtpType.signup,
      );

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      if (success) {
        if (widget.onVerified != null) {
          widget.onVerified!();
        } else {
          _showSuccessPopup();
        }
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ??
              'Invalid or expired 6-digit OTP code. Please try again.';
        });
      }
    }
  }

  void _showSuccessPopup() {
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
                    'Verification Successful!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your email has been verified. You can now log in to start learning!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle2.copyWith(
                      color: AppColors.subtitle,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Continue to Login',
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
    final isLoading = _isVerifying || authProvider.isLoading;

    final defaultTitle = widget.isPasswordReset ? 'Password Recovery' : 'Verify OTP';
    final defaultSubtitle = widget.isPasswordReset
        ? 'Enter the 6-digit recovery OTP code sent to '
        : 'Enter the 6-digit code sent to ';

    return Scaffold(
      backgroundColor: AppColors.background,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Algebrix Logo Branding Header
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.extraLightPink,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.pink.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Image.asset(
                      AppAssets.logo,
                      width: 72,
                      height: 72,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  widget.title ?? defaultTitle,
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text.rich(
                    TextSpan(
                      text: widget.subtitle ?? defaultSubtitle,
                      style: AppTextStyles.subtitle2.copyWith(
                        color: AppColors.subtitle,
                      ),
                      children: [
                        TextSpan(
                          text: widget.email,
                          style: AppTextStyles.subtitle2.copyWith(
                            color: AppColors.pink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 36),

                // 6 OTP Pin Boxes Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_codeLength, (index) {
                    final isFocused = _focusNodes[index].hasFocus;
                    final isFilled = _controllers[index].text.isNotEmpty;

                    return KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onPinKey(index, event),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isFocused
                              ? AppColors.extraLightPink
                              : (isFilled
                                  ? Colors.white
                                  : AppColors.extraLightPink.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _errorMessage != null
                                ? AppColors.error
                                : (isFocused
                                    ? AppColors.pink
                                    : (isFilled
                                        ? AppColors.pink.withValues(alpha: 0.5)
                                        : AppColors.border)),
                            width: isFocused || _errorMessage != null ? 2.0 : 1.2,
                          ),
                          boxShadow: isFocused
                              ? [
                                  BoxShadow(
                                    color: AppColors.pink.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) => _onPinChanged(index, val),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 36),

                // Verify Button
                PrimaryButton(
                  label: 'Verify Code',
                  isLoading: isLoading,
                  onPressed: _verifyCode,
                ),

                const SizedBox(height: 24),

                // Resend OTP Action Button Bar
                Center(
                  child: Column(
                    children: [
                      if (_remainingSeconds > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.extraLightPink.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 18,
                                color: AppColors.pink,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Resend Code in ',
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _formatTime(_remainingSeconds),
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.pink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Interactive Resend Button
                      GestureDetector(
                        onTap: _resendCode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.pink.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isResending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.pink,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                      color: AppColors.pink,
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                _isResending ? 'Sending Code...' : 'Resend Code Now',
                                style: AppTextStyles.subtitle2.copyWith(
                                  color: AppColors.pink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
