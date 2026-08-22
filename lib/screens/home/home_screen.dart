import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_strings.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/models/user_model.dart';
import 'package:algebrix/models/daily_challenge_model.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';
import 'package:algebrix/widgets/lesson_card.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/secondary_button.dart';
import 'package:algebrix/widgets/daily_challenge_card.dart';
import 'package:algebrix/widgets/progress_card.dart';
import 'package:algebrix/widgets/streak_badge.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/search_bar_widget.dart';
import 'package:algebrix/screens/auth/login_screen.dart';
import 'package:algebrix/screens/lessons/lesson_screen.dart';
import 'package:algebrix/screens/lessons/module_overview_screen.dart';
import 'package:algebrix/screens/practice/balance_scale_screen.dart';
import 'package:algebrix/screens/practice/quiz_screen.dart';
import 'package:algebrix/screens/quiz/module_quiz_screen.dart';
import 'package:algebrix/screens/notes/note_detail_screen.dart';

/// Upgraded Dashboard screen displaying universal search, progress stats,
/// quick practice tools, continue learning, daily challenge, and account actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final lessonProvider = context.watch<LessonProvider>();
    final notesProvider = context.watch<NotesProvider>();

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

    final isSearching = _searchQuery.trim().isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RootPageHeader(
            title: 'Welcome Back!',
            subtitle: 'Ready to solve and level up, ${user.name}?',
            mascotAsset: AppAssets.xyWelcome,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Universal System Search Bar
                SearchBarWidget(
                  onChanged: (q) => setState(() => _searchQuery = q),
                ),
                const SizedBox(height: 16),

                if (isSearching) ...[
                  _UniversalSearchResults(
                    query: _searchQuery,
                    notes: notesProvider.notes,
                    lessons: [...module1.lessons, ...module2.lessons],
                    onOpenLesson: (lesson) => _openLesson(context, lessonProvider, lesson),
                    onOpenNote: (note) {
                      notesProvider.selectNote(note.id);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
                      );
                    },
                  ),
                ] else ...[
                  // Progress & Streak Stats Card
                  if (lessonProvider.isHydrating)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(color: AppColors.pink),
                      ),
                    )
                  else if (profile != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                            height: 80,
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

                  // Quick Action Feature Grid
                  Text('Quick Practice & Features', style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickFeatureCard(
                          title: 'Balance Scale',
                          subtitle: 'Visual Equations',
                          icon: '⚖️',
                          accentColor: AppColors.pink,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BalanceScaleScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickFeatureCard(
                          title: 'Math Quiz',
                          subtitle: 'AI Feedback',
                          icon: '🧠',
                          accentColor: AppColors.purple,
                          onTap: () {
                            final targetModule =
                                lessonProvider.currentModule ?? module1;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ModuleQuizScreen(module: targetModule),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Continue Learning
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

                  // Section 3: Daily Challenge
                  DailyChallengeCard(
                    title: dailyChallenge.title,
                    description: dailyChallenge.description,
                    progress: dailyChallenge.progress,
                    progressText: dailyChallenge.progressDisplay,
                    xpReward: dailyChallenge.xpReward,
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),

                  // Section 4: Learning tip
                  Text("Today's learning tip", style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  _LearningTipCallout(message: AppStrings.tipOfTheDay),

                  const SizedBox(height: 28),

                  // Section 5: Logged in User Card
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

class _QuickFeatureCard extends StatelessWidget {
  const _QuickFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(color: AppColors.subtitle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UniversalSearchResults extends StatelessWidget {
  const _UniversalSearchResults({
    required this.query,
    required this.notes,
    required this.lessons,
    required this.onOpenLesson,
    required this.onOpenNote,
  });

  final String query;
  final List<StudyNote> notes;
  final List<LessonContent> lessons;
  final ValueChanged<LessonContent> onOpenLesson;
  final ValueChanged<StudyNote> onOpenNote;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    // 1. Matching Features
    final featureMatches = <Map<String, dynamic>>[];
    if ('balance scale visualizer equation'.contains(q)) {
      featureMatches.add({
        'title': 'Balance Scale Manipulator',
        'subtitle': 'Interactive equation balancing',
        'icon': '⚖️',
        'action': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BalanceScaleScreen()),
        ),
      });
    }
    if ('math quiz test practice ai tutor'.contains(q)) {
      featureMatches.add({
        'title': 'Math Quiz Mode',
        'subtitle': 'Dynamic questions & AI explanations',
        'icon': '🧠',
        'action': () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QuizScreen()),
        ),
      });
    }

    // 2. Matching Lessons
    final lessonMatches = lessons.where((l) {
      return l.title.toLowerCase().contains(q) ||
          l.objective.toLowerCase().contains(q);
    }).toList();

    // 3. Matching Notes
    final noteMatches = notes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.displayContent.toLowerCase().contains(q);
    }).toList();

    final totalCount = featureMatches.length + lessonMatches.length + noteMatches.length;

    if (totalCount == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.subtitle),
            const SizedBox(height: 12),
            Text(
              'No results for "$query"',
              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching for "scale", "quiz", "algebra", or a note title.',
              style: AppTextStyles.body2.copyWith(color: AppColors.subtitle),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Search Results ($totalCount)', style: AppTextStyles.heading3),
        const SizedBox(height: 12),

        if (featureMatches.isNotEmpty) ...[
          Text('Features & Tools', style: AppTextStyles.subtitle2.copyWith(color: AppColors.subtitle)),
          const SizedBox(height: 6),
          ...featureMatches.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              leading: Text(f['icon'] as String, style: const TextStyle(fontSize: 24)),
              title: Text(f['title'] as String, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(f['subtitle'] as String, style: AppTextStyles.caption),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: f['action'] as VoidCallback,
            ),
          )),
          const SizedBox(height: 12),
        ],

        if (lessonMatches.isNotEmpty) ...[
          Text('Lessons', style: AppTextStyles.subtitle2.copyWith(color: AppColors.subtitle)),
          const SizedBox(height: 6),
          ...lessonMatches.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              leading: const Icon(Icons.menu_book_rounded, color: AppColors.pink),
              title: Text(l.title, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(l.objective, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.play_arrow_rounded, color: AppColors.pink),
              onTap: () => onOpenLesson(l),
            ),
          )),
          const SizedBox(height: 12),
        ],

        if (noteMatches.isNotEmpty) ...[
          Text('Study Notes', style: AppTextStyles.subtitle2.copyWith(color: AppColors.subtitle)),
          const SizedBox(height: 6),
          ...noteMatches.map((n) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              leading: const Icon(Icons.note_alt_outlined, color: AppColors.purple),
              title: Text(n.title, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(n.displayContent, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => onOpenNote(n),
            ),
          )),
        ],
      ],
    );
  }
}

class _LearningTipCallout extends StatelessWidget {
  const _LearningTipCallout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.extraLightPink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tips_and_updates_outlined,
              color: AppColors.darkPink,
              size: 22,
              semanticLabel: 'Learning tip',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
