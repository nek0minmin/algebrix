import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';

/// Password Strength Checklist Widget with a sleek strength progress bar,
/// dynamic badge, and responsive criteria checklist without overflow.
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

  String get strengthText {
    if (metCount == 4) return 'Strong';
    if (metCount >= 2) return 'Medium';
    if (password.isNotEmpty) return 'Weak';
    return 'Not Set';
  }

  Color get strengthColor {
    if (isAllMet) return AppColors.mint;
    if (metCount >= 2) return const Color(0xFFB78103);
    if (password.isNotEmpty) return AppColors.pink;
    return AppColors.subtitle;
  }

  double get progressValue => metCount / 4.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row (Left: Label, Right: Badge)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password Strength',
                style: AppTextStyles.subtitle2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: strengthColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: strengthColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strengthText,
                      style: AppTextStyles.caption.copyWith(
                        color: strengthColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isAllMet ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 14,
                      color: strengthColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Strength Bar (Default Visual Progress Bar)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 5,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            ),
          ),
          const SizedBox(height: 12),

          // 4 Checklist Items (Matching Screenshot 2 without Overflow)
          _buildCheckItem('At least 8 characters long', hasMinLength),
          const SizedBox(height: 6),
          _buildCheckItem('At least 1 number', hasNumber),
          const SizedBox(height: 6),
          _buildCheckItem('At least 1 uppercase letter', hasUppercase),
          const SizedBox(height: 6),
          _buildCheckItem('At least 1 lowercase letter', hasLowercase),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: isMet ? AppColors.mint : AppColors.subtitle.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body2.copyWith(
              color: isMet ? AppColors.text : AppColors.subtitle,
              fontWeight: isMet ? FontWeight.bold : FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}
