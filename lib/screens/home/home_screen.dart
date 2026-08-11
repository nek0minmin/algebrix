import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_strings.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/models/user_model.dart';
import 'package:algebrix/models/lesson_model.dart';
import 'package:algebrix/models/daily_challenge_model.dart';
import 'package:algebrix/widgets/search_bar_widget.dart';
import 'package:algebrix/widgets/lesson_card.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/secondary_button.dart';
import 'package:algebrix/widgets/daily_challenge_card.dart';
import 'package:algebrix/widgets/xy_dialog.dart';
import 'package:algebrix/screens/auth/login_screen.dart';

/// The main dashboard screen displaying greeting, continue learning, daily challenge,
/// and a visible Logout action to test login/registration flows.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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
    final currentLesson = LessonModel.currentLesson(LessonModel.placeholderLessons());
    final dailyChallenge = DailyChallengeModel.placeholder();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Greeting + Xy + Quick Logout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.greeting(user.name),
                        style: AppTextStyles.greeting,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.readyToLearn,
                        style: AppTextStyles.subtitle2,
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  AppAssets.xyWave,
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 2: Search Bar
            SearchBarWidget(
              onChanged: (val) {},
              onSubmitted: (val) {},
            ),
            const SizedBox(height: 24),

            // Section 3: Continue Learning
            Text(
              'Continue Learning',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 12),
            if (currentLesson != null) ...[
              LessonCard(
                lessonTitle: currentLesson.title,
                moduleTitle: currentLesson.moduleTitle,
                progress: currentLesson.progress,
                progressText: currentLesson.progressPercent,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Continue',
                onPressed: () {},
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
            Text(
              "Today's Tip from Xy",
              style: AppTextStyles.heading3,
            ),
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
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
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
    );
  }
}
