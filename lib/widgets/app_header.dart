import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/screens/auth/login_screen.dart';

/// Reusable app header widget with Logout action.
class AppHeader extends StatelessWidget {
  final String? userName;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogoutTap;

  const AppHeader({
    super.key,
    this.userName,
    this.onProfileTap,
    this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
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
              const SizedBox(width: 8),
              // Visible Logout Button for testing auth flow
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.pink, size: 22),
                tooltip: 'Log Out',
                onPressed: () async {
                  if (onLogoutTap != null) {
                    onLogoutTap!();
                  } else {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
