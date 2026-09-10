import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:algebrix/core/animations/app_page_route.dart';
import 'package:algebrix/core/constants/app_avatars.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/data/lesson_catalog.dart';
import 'package:algebrix/models/user_model.dart';
import 'package:algebrix/screens/profile/account_settings_screen.dart';
import 'package:algebrix/services/sound_service.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/screens/auth/login_screen.dart';

/// Full Learner Profile Screen displaying lesson progress, audio settings, and
/// account metadata.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// The signed-in email, or null when Supabase is not available.
  ///
  /// `Supabase.instance` asserts when the SDK was never initialised, which is
  /// the case under widget test and on a first launch where init failed. The
  /// screen falls back to a derived address rather than crashing.
  static String? _signedInEmail() {
    try {
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final lessonProvider = context.watch<LessonProvider>();

    final user = authProvider.currentUser ?? UserModel.placeholder();
    final userEmail = _signedInEmail() ??
        '${user.name.toLowerCase().replaceAll(' ', '')}@algebrix.app';

    // Derived from the catalog rather than a hardcoded total, which had drifted
    // to 13 while the app shipped 21 lessons.
    final completedLessons = lessonProvider.completedLessonIds.length;
    final totalLessons = LessonCatalog.totalLessons;
    final lessonsRemaining = (totalLessons - completedLessons).clamp(0, totalLessons);

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
                  _ProfileAvatar(
                    avatarKey: user.avatarUrl,
                    initial:
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
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
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Lesson Progress
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
                      Flexible(
                        child: Text(
                          'Lesson Progress',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subtitle1
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$completedLessons / $totalLessons Lessons',
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
                      value: totalLessons == 0
                          ? 0
                          : (completedLessons / totalLessons).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pink),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lessonsRemaining == 0
                        ? 'Every lesson complete. Nice work!'
                        : '$lessonsRemaining ${lessonsRemaining == 1 ? 'lesson' : 'lessons'} left to go',
                    style: AppTextStyles.caption.copyWith(color: AppColors.subtitle),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sound Effects & Audio Preferences Section
            const _SoundSettingsCard(),

            const SizedBox(height: 20),

            // Account Settings entry point
            Semantics(
              button: true,
              label: 'Account Settings',
              child: BouncyPressable(
                key: const Key('profile-account-settings-row'),
                onTap: () {
                  Navigator.push(
                    context,
                    AppPageRoute(child: const AccountSettingsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.extraLightPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.manage_accounts_rounded,
                          color: AppColors.pink,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Settings',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              'Name, avatar, password, and account',
                              style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.subtitle,
                      ),
                    ],
                  ),
                ),
              ),
            ),

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

/// Circular profile avatar: the learner's chosen Xy preset, or their initial.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.avatarKey, required this.initial});

  final String? avatarKey;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final asset = AppAvatars.assetForKey(avatarKey);

    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        color: AppColors.lightPink,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? Center(
              child: Text(
                initial,
                style: GoogleFonts.nunito(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.pink,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
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
  double _volume = SoundService.soundVolume;

  /// Plays a preview at the new level, but only once the learner stops
  /// dragging — one chime per adjustment, not one per pixel.
  Future<void> _handleVolumeSettled(double value) async {
    await SoundService.setSoundVolume(value);
    SoundService.playTileSelect();
  }

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
              // Expanded, not a bare Row: the label column used to size itself
              // freely and push the switch off the right edge on narrow phones.
              Expanded(
                child: Column(
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                key: const Key('sound-effects-toggle'),
                value: _soundEnabled,
                activeThumbColor: AppColors.mint,
                onChanged: (val) async {
                  setState(() => _soundEnabled = val);
                  await SoundService.setSoundEnabled(val);
                  if (val) SoundService.playClick();
                },
              ),
            ],
          ),

          // ── Volume ───────────────────────────────────────────────────────
          const Divider(height: 26, color: AppColors.divider),
          Row(
            children: [
              Text(
                'Volume',
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _soundEnabled ? AppColors.text : AppColors.subtitle,
                ),
              ),
              const Spacer(),
              Text(
                '${(_volume * 100).round()}%',
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: _soundEnabled ? AppColors.mint : AppColors.subtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.volume_mute_rounded,
                size: 18,
                color: _soundEnabled ? AppColors.subtitle : AppColors.border,
              ),
              Expanded(
                child: Slider(
                  key: const Key('sound-volume-slider'),
                  value: _volume,
                  min: SoundService.minVolume,
                  max: SoundService.maxVolume,
                  divisions: 20,
                  activeColor: AppColors.mint,
                  inactiveColor: AppColors.divider,
                  label: '${(_volume * 100).round()}%',
                  // Disabled rather than hidden while muted, so the control
                  // stays where the learner expects to find it.
                  onChanged: _soundEnabled
                      ? (value) => setState(() => _volume = value)
                      : null,
                  onChangeEnd: _soundEnabled ? _handleVolumeSettled : null,
                ),
              ),
              Icon(
                Icons.volume_up_rounded,
                size: 18,
                color: _soundEnabled ? AppColors.subtitle : AppColors.border,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
