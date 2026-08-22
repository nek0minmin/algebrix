import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/screens/auth/login_screen.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';

import 'package:algebrix/screens/profile/profile_screen.dart';

enum ProfileMenuOption { profile, settings, help, logout }

/// Reusable app header widget with profile menu popup & Logout confirmation dialog.
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

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.extraLightPink,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    AppAssets.xyWave,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Log out of Algebrix?',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out? You can log back in anytime.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.pink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Log out',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      if (onLogoutTap != null) {
        onLogoutTap!();
      } else {
        await authProvider.logout();
        if (context.mounted) {
          showAlgebrixSnackBar(
            context,
            message: 'Logged out successfully.',
            icon: Icons.check_circle_rounded,
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  void _handleMenuSelection(BuildContext context, ProfileMenuOption option) {
    switch (option) {
      case ProfileMenuOption.profile:
        if (onProfileTap != null) {
          onProfileTap!();
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
        break;
      case ProfileMenuOption.settings:
        showAlgebrixSnackBar(
          context,
          message: 'App settings coming soon!',
          icon: Icons.settings_rounded,
        );
        break;
      case ProfileMenuOption.help:
        showAlgebrixSnackBar(
          context,
          message: 'Need help? Ask Xy inside Study Notes!',
          icon: Icons.help_outline_rounded,
        );
        break;
      case ProfileMenuOption.logout:
        _showLogoutConfirmation(context);
        break;
    }
  }

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
              const SizedBox(width: 10),
              Text(
                'ALGEBRIX',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          PopupMenuButton<ProfileMenuOption>(
            key: const Key('profile-avatar-menu'),
            onSelected: (option) => _handleMenuSelection(context, option),
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            color: Colors.white,
            elevation: 6,
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ProfileMenuOption.profile,
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: AppColors.pink, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Profile',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ProfileMenuOption.settings,
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, color: AppColors.purple, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ProfileMenuOption.help,
                child: Row(
                  children: [
                    const Icon(Icons.help_outline_rounded, color: AppColors.mint, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Help',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: ProfileMenuOption.logout,
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
