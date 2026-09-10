import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/mastery_provider.dart';
import 'package:algebrix/core/providers/quiz_review_provider.dart';
import 'package:algebrix/screens/review/lesson_mistakes_tab.dart';
import 'package:algebrix/screens/review/quiz_attempts_tab.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// Which record the History tab is showing.
enum HistorySource { quizzes, lessons }

/// The raw record behind everything else on this page: what the learner
/// actually answered, in quizzes and in lessons.
///
/// Quizzes and lesson mistakes used to be separate tabs, which read as four
/// competing sections. They answer the same question — "what did I get
/// wrong?" — so they sit behind one toggle instead.
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  HistorySource _source = HistorySource.quizzes;

  @override
  Widget build(BuildContext context) {
    final quizCount = context.watch<QuizReviewProvider>().attempts.length;
    final lessonCount =
        context.watch<MasteryProvider>().openLessonMistakes.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: _SourceChip(
                  itemKey: const Key('history-source-quizzes'),
                  label: 'Quiz attempts',
                  count: quizCount,
                  isActive: _source == HistorySource.quizzes,
                  onTap: () =>
                      setState(() => _source = HistorySource.quizzes),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SourceChip(
                  itemKey: const Key('history-source-lessons'),
                  label: 'Lesson mistakes',
                  count: lessonCount,
                  isActive: _source == HistorySource.lessons,
                  onTap: () => setState(() => _source = HistorySource.lessons),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _source == HistorySource.quizzes
              ? const QuizAttemptsTab()
              : const LessonMistakesTab(),
        ),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.itemKey,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final Key itemKey;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: '$label, $count',
      child: BouncyPressable(
        key: itemKey,
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.extraLightPink : AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isActive ? AppColors.pink : AppColors.border,
              width: isActive ? 2 : 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                    color:
                        isActive ? AppColors.darkPink : AppColors.subtitle,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.pink : AppColors.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isActive ? Colors.white : AppColors.subtitle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
