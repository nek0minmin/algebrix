import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/mastery_provider.dart';
import 'package:algebrix/core/providers/quiz_review_provider.dart';
import 'package:algebrix/screens/review/history_tab.dart';
import 'package:algebrix/screens/review/mastery_tab.dart';
import 'package:algebrix/screens/review/practice_queue_tab.dart';
import 'package:algebrix/widgets/page_headers.dart';

/// Which tab the hub opens on.
///
/// Three, not four: quiz attempts and lesson mistakes both answer "what did I
/// get wrong?", so they share the History tab behind a toggle.
enum ReviewHubTab { practice, mastery, history }

/// Home for everything backward-looking: what to practice now, how well each
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
    final historyCount =
        quizReview.attempts.length + mastery.openLessonMistakes.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AlgebrixAppBar(
        title: 'Review & Mastery',
        subtitle: 'What to practice, and how you are doing',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ReviewTabBar(
              controller: _tabController,
              badges: {
                ReviewHubTab.practice: dueCount,
                ReviewHubTab.history: historyCount,
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  PracticeQueueTab(),
                  MasteryTab(),
                  HistoryTab(),
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
    ReviewHubTab.history: 'History',
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
        // TabBar defaults to 16px of horizontal label padding, which on a
        // ~390pt phone left each of four tabs about 56pt — narrower than
        // "Mastery" renders at w900, so every label ellipsised.
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
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

/// A tab label that always shows its full word.
///
/// Wrapped in a scale-down [FittedBox] rather than left to ellipsise: a tab
/// reading "Maste..." tells the learner nothing, and shrinking a few points is
/// a better trade than losing the word. This keeps all four tabs legible from
/// small phones up, with or without a count badge.
class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.badge});

  final String label;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, maxLines: 1, softWrap: false),
          if (badge > 0) ...[
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
        ],
      ),
    );
  }
}
