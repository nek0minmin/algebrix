import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_strings.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/models/user_model.dart';
import 'package:algebrix/models/daily_challenge_model.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/widgets/search_bar_widget.dart';
import 'package:algebrix/widgets/lesson_card.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/secondary_button.dart';
import 'package:algebrix/widgets/daily_challenge_card.dart';
import 'package:algebrix/widgets/xy_dialog.dart';
import 'package:algebrix/widgets/progress_card.dart';
import 'package:algebrix/widgets/streak_badge.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/screens/auth/login_screen.dart';
import 'package:algebrix/screens/lessons/lesson_screen.dart';
import 'package:algebrix/screens/lessons/module_overview_screen.dart';

/// The main dashboard screen displaying greeting, continue learning, daily challenge,
/// and a visible Logout action to test login/registration flows.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final lessonProvider = context.watch<LessonProvider>();

    // Lock dashboard access so unauthenticated users cannot bypass LoginScreen
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      });
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pink),
      );
    }

    final user = authProvider.currentUser ?? UserModel.placeholder();
    final profile = lessonProvider.profile;
    final currentLesson = lessonProvider.latestResumableLesson(module1);
    final currentLessonProgress = currentLesson == null
        ? 0.0
        : lessonProvider.progressFractionForLesson(currentLesson);
    final currentLessonRecord = currentLesson == null
        ? null
        : lessonProvider.progressForLesson(currentLesson.lessonId);
    final dailyChallenge = DailyChallengeModel.placeholder();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RootPageHeader(
            title: 'Home',
            subtitle: 'Your learning dashboard',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.greeting(user.name),
                  style: AppTextStyles.greeting,
                ),
                const SizedBox(height: 4),
                Text(AppStrings.readyToLearn, style: AppTextStyles.subtitle2),
                const SizedBox(height: 20),

                if (lessonProvider.isHydrating)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(color: AppColors.pink),
                    ),
                  )
                else if (lessonProvider.hydrationError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.extraLightPink,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your XP couldn’t be loaded.',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: lessonProvider.retryHydration,
                          child: Text(
                            'Retry',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.pink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else if (profile != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ProgressCard(
                            level: profile.level,
                            progress: (profile.xp % 1000) / 1000,
                            xpText: '${profile.xp} XP total',
                            levelTitle: profile.levelTitle,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 84,
                          color: AppColors.divider,
                        ),
                        Expanded(
                          child: StreakBadge(
                            streakDays: profile.streak,
                            showSubtitle: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Section 2: Search Bar
                SearchBarWidget(onChanged: (val) {}, onSubmitted: (val) {}),
                const SizedBox(height: 24),

                // Section 3: Continue Learning
                Text('Continue Learning', style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                if (currentLesson != null) ...[
                  LessonCard(
                    lessonTitle: currentLesson.title,
                    moduleTitle: currentLesson.moduleTitle,
                    progress: currentLessonProgress,
                    progressText:
                        '${(currentLessonProgress * 100).round()}% complete',
                    onTap: lessonProvider.isBusy
                        ? null
                        : () => _openLesson(
                            context,
                            lessonProvider,
                            currentLesson,
                          ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: currentLessonRecord == null
                        ? 'Start Lesson 1'
                        : lessonProvider.isLessonCompleted(
                            currentLesson.lessonId,
                          )
                        ? 'Review'
                        : 'Continue',
                    isLoading: lessonProvider.isRecording,
                    onPressed: lessonProvider.isBusy
                        ? null
                        : () => _openLesson(
                            context,
                            lessonProvider,
                            currentLesson,
                          ),
                  ),
                ],
                const SizedBox(height: 24),

                // Section 4: Daily Challenge
                DailyChallengeCard(
                  title: dailyChallenge.title,
                  description: dailyChallenge.description,
                  progress: dailyChallenge.progress,
                  progressText: dailyChallenge.progressDisplay,
                  xpReward: dailyChallenge.xpReward,
                  onTap: () {},
                ),
                const SizedBox(height: 24),

                // Section 5: Xy's Tip of the Day
                Text("Today's Tip from Xy", style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                XyDialog(
                  message: AppStrings.tipOfTheDay,
                  xyAsset: AppAssets.xyPointing,
                ),

                const SizedBox(height: 28),

                // Section 6: Visible Logout Action for Testing Auth Flows
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.extraLightPink.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.pink.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_circle_outlined,
                            color: AppColors.pink,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Logged in as ${user.name}',
                              style: AppTextStyles.subtitle2.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SecondaryButton(
                        label: 'Log Out',
                        icon: Icons.logout_rounded,
                        borderColor: AppColors.pink,
                        textColor: AppColors.pink,
                        onPressed: () async {
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLesson(
    BuildContext context,
    LessonProvider lessonProvider,
    LessonContent lesson,
  ) async {
    if (lessonProvider.isBusy) return;
    lessonProvider.startModule(module1);
    final opened = await lessonProvider.startLesson(lesson);
    if (!context.mounted) return;
    if (!opened) {
      final message =
          lessonProvider.errorMessage ?? 'Progress could not be saved.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('$message Try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute(builder: (_) => const ModuleOverviewScreen()),
    );
    navigator.push(MaterialPageRoute(builder: (_) => const LessonScreen()));
  }
}
