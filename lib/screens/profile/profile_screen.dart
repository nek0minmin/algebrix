import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/models/user_model.dart';
import 'package:algebrix/services/sound_service.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/streak_badge.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/screens/auth/login_screen.dart';

/// Full Learner Profile Screen displaying user stats, badges, and account metadata.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final lessonProvider = context.watch<LessonProvider>();

    final user = authProvider.currentUser ?? UserModel.placeholder();
    final profile = lessonProvider.profile;
    final userEmail = Supabase.instance.client.auth.currentUser?.email ??
        '${user.name.toLowerCase().replaceAll(' ', '')}@algebrix.app';

    final int totalXp = profile?.xp ?? 0;
    final int level = profile?.level ?? 1;
    final String levelTitle = profile?.levelTitle ?? 'Math Beginner';
    final int streak = profile?.streak ?? 0;
    final double levelProgress = (totalXp % 1000) / 1000.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Learner Profile',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Avatar & Basic Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.lightPink,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: GoogleFonts.nunito(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.pink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.name,
                    style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: AppTextStyles.body2.copyWith(color: AppColors.subtitle),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.pink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.pink.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Level $level • $levelTitle',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.pink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Lesson Progress & Streak Row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lesson Progress',
                        style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${lessonProvider.completedLessonIds.length} / 13 Lessons',
                        style: AppTextStyles.subtitle2.copyWith(
                          color: AppColors.pink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (lessonProvider.completedLessonIds.length / 13.0).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pink),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${13 - lessonProvider.completedLessonIds.length} lessons remaining to complete Foundations',
                    style: AppTextStyles.caption.copyWith(color: AppColors.subtitle),
                  ),
                  const Divider(height: 28, color: AppColors.divider),
                  Row(
                    children: [
                      Expanded(
                        child: StreakBadge(streakDays: streak, showSubtitle: true),
                      ),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.stars_rounded, color: AppColors.purple, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              '${lessonProvider.completedLessonIds.length} Lessons',
                              style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Completed',
                              style: AppTextStyles.caption.copyWith(color: AppColors.subtitle),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Achievement Badges Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earned Badges',
                    style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BadgeItem(icon: '🎯', title: 'First Step', isUnlocked: true),
                      _BadgeItem(icon: '⚡', title: 'Streak Pro', isUnlocked: streak > 0),
                      _BadgeItem(icon: '🧠', title: 'Math Wiz', isUnlocked: totalXp >= 100),
                      _BadgeItem(icon: '👑', title: 'Master', isUnlocked: level >= 5),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sound Effects & Audio Preferences Section
            const _SoundSettingsCard(),

            const SizedBox(height: 28),

            // Logout Button
            PrimaryButton(
              label: 'Log Out',
              icon: Icons.logout_rounded,
              backgroundColor: AppColors.error,
              onPressed: () async {
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
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.icon,
    required this.title,
    required this.isUnlocked,
  });

  final String icon;
  final String title;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isUnlocked ? AppColors.extraLightPink : AppColors.divider.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked ? AppColors.pink : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Opacity(
              opacity: isUnlocked ? 1.0 : 0.4,
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            fontWeight: isUnlocked ? FontWeight.w800 : FontWeight.w500,
            color: isUnlocked ? AppColors.text : AppColors.subtitle,
          ),
        ),
      ],
    );
  }
}

class _SoundSettingsCard extends StatefulWidget {
  const _SoundSettingsCard();

  @override
  State<_SoundSettingsCard> createState() => _SoundSettingsCardState();
}

class _SoundSettingsCardState extends State<_SoundSettingsCard> {
  bool _soundEnabled = SoundService.isSoundEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audio & Sound',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _soundEnabled
                          ? AppColors.lightMint
                          : AppColors.divider.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: _soundEnabled ? AppColors.mint : AppColors.subtitle,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sound Effects',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        _soundEnabled
                            ? 'Tactile math pops & chimes enabled'
                            : 'Audio muted',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: _soundEnabled,
                activeColor: AppColors.mint,
                onChanged: (val) async {
                  await SoundService.setSoundEnabled(val);
                  if (val) {
                    SoundService.playClick();
                  }
                  setState(() {
                    _soundEnabled = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
