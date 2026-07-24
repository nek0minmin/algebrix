import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';

/// Reusable app header widget.
class AppHeader extends StatelessWidget {
  final String? userName;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    this.userName,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                AppAssets.logo,
                width: 36,
                height: 36,
              ),
              const SizedBox(width: 8),
              Text(
                'ALGEBRIX',
                style: AppTextStyles.heading3.copyWith(
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.lightPink,
                child: Text(
                  userName != null && userName!.isNotEmpty
                      ? userName!.substring(0, 1).toUpperCase()
                      : 'U',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColors.pink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
