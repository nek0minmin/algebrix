import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Shows an Algebrix branded notification SnackBar featuring Nunito font & Xy styling.
void showAlgebrixSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
  IconData? icon,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      elevation: 4,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFFF0F0) : AppColors.extraLightPink,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isError ? AppColors.error : AppColors.pink,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isError ? AppColors.error : AppColors.pink)
                  .withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                color: isError ? AppColors.error : AppColors.pink,
                size: 24,
              )
            else
              Image.asset(
                isError ? AppAssets.xyExplaining : AppAssets.xyDefault,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body2.copyWith(
                  color: isError ? AppColors.error : AppColors.darkPink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
