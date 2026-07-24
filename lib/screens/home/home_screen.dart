import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_strings.dart';
import 'package:algebrix/models/user_model.dart';
import 'package:algebrix/models/lesson_model.dart';
import 'package:algebrix/models/daily_challenge_model.dart';
import 'package:algebrix/widgets/search_bar_widget.dart';
import 'package:algebrix/widgets/lesson_card.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/daily_challenge_card.dart';
import 'package:algebrix/widgets/xy_dialog.dart';

/// The main dashboard screen displaying greeting, continue learning, and daily challenge.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserModel.placeholder();
    final currentLesson = LessonModel.currentLesson(LessonModel.placeholderLessons());
    final dailyChallenge = DailyChallengeModel.placeholder();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Greeting + Xy
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
                  width: 100,
                  height: 100,
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
