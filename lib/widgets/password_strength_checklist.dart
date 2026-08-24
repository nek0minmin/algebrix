import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';

/// Clean Password Criteria Checklist matching Figma UI Pic 3.
/// Directly displays the 4 requirements with pink outline circles / checkmarks.
class PasswordStrengthChecklist extends StatelessWidget {
  final String password;

  const PasswordStrengthChecklist({
    super.key,
    required this.password,
  });

  bool get hasMinLength => password.length >= 8;
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(password);
  bool get hasUppercase => RegExp(r'[A-Z]').hasMatch(password);
  bool get hasLowercase => RegExp(r'[a-z]').hasMatch(password);

  int get metCount {
    int count = 0;
    if (hasMinLength) count++;
    if (hasNumber) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    return count;
  }

  bool get isAllMet => metCount == 4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCheckItem('At least eight characters long', hasMinLength),
          const SizedBox(height: 7),
          _buildCheckItem('At least one number', hasNumber),
          const SizedBox(height: 7),
          _buildCheckItem('At least one uppercase letter', hasUppercase),
          const SizedBox(height: 7),
          _buildCheckItem('At least one lowercase letter', hasLowercase),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isMet) {
    const unmetColor = Color(0xFFE86060); // Soft coral-pink matching Pic 3

    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 19,
          color: isMet ? AppColors.mint : unmetColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isMet ? const Color(0xFF0F7263) : unmetColor,
            ),
          ),
        ),
      ],
    );
  }
}
