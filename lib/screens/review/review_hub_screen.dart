import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/mastery_provider.dart';
import 'package:algebrix/core/providers/quiz_review_provider.dart';
import 'package:algebrix/screens/review/lesson_mistakes_tab.dart';
import 'package:algebrix/screens/review/mastery_tab.dart';
import 'package:algebrix/screens/review/practice_queue_tab.dart';
import 'package:algebrix/screens/review/quiz_attempts_tab.dart';
import 'package:algebrix/widgets/page_headers.dart';

/// Which tab the hub opens on.
enum ReviewHubTab { practice, mastery, quizzes, lessons }

/// Home for everything backward-looking: what to practise now, how well each
/// concept is held, and the raw quiz and lesson mistakes behind both.
class ReviewHubScreen extends StatefulWidget {
  const ReviewHubScreen({super.key, this.initialTab = ReviewHubTab.practice});

  final ReviewHubTab initialTab;

  @override
  State<ReviewHubScreen> createState() => _ReviewHubScreenState();
}

class _ReviewHubScreenState extends State<ReviewHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ReviewHubTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mastery = context.watch<MasteryProvider>();
    final quizReview = context.watch<QuizReviewProvider>();

    final dueCount = mastery.needsReview.length;
    final openMistakeCount = mastery.openLessonMistakes.length;
    final attemptCount = quizReview.attempts.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AlgebrixAppBar(
        title: 'Review & Mastery',
        subtitle: 'What to practise, and how you are doing',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ReviewTabBar(
              controller: _tabController,
              badges: {
                ReviewHubTab.practice: dueCount,
                ReviewHubTab.lessons: openMistakeCount,
                ReviewHubTab.quizzes: attemptCount,
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  PracticeQueueTab(),
                  MasteryTab(),
                  QuizAttemptsTab(),
                  LessonMistakesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTabBar extends StatelessWidget {
  const _ReviewTabBar({required this.controller, required this.badges});

  final TabController controller;
  final Map<ReviewHubTab, int> badges;

  static const Map<ReviewHubTab, String> _labels = {
    ReviewHubTab.practice: 'Practice',
    ReviewHubTab.mastery: 'Mastery',
    ReviewHubTab.quizzes: 'Quizzes',
    ReviewHubTab.lessons: 'Lessons',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: false,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        indicator: BoxDecoration(
          color: AppColors.extraLightPink,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.pink, width: 1.5),
        ),
        labelColor: AppColors.darkPink,
        unselectedLabelColor: AppColors.subtitle,
        labelStyle: GoogleFonts.nunito(
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        tabs: [
          for (final tab in ReviewHubTab.values)
            Tab(
              key: Key('review-tab-${tab.name}'),
              height: 46,
              child: _TabLabel(
                label: _labels[tab]!,
                badge: badges[tab] ?? 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.badge});

  final String label;
  final int badge;

  @override
  Widget build(BuildContext context) {
    if (badge <= 0) {
      return Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.pink,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            badge > 9 ? '9+' : '$badge',
            style: GoogleFonts.nunito(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
