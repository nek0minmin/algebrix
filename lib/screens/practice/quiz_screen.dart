import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';

/// Placeholder screen for Quiz.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.xyHappy,
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            'Quiz',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: AppTextStyles.subtitle1,
          ),
        ],
      ),
    );
  }
}
