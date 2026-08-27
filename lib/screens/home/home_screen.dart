import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_strings.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/core/providers/quiz_provider.dart';
import 'package:algebrix/models/user_model.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';
import 'package:algebrix/data/module3_content.dart';
import 'package:algebrix/widgets/lesson_card.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/xy_mascot.dart';
import 'package:algebrix/screens/auth/login_screen.dart';
import 'package:algebrix/screens/lessons/lesson_screen.dart';
import 'package:algebrix/screens/lessons/module_overview_screen.dart';
import 'package:algebrix/screens/quiz/quiz_hub_screen.dart';
import 'package:algebrix/screens/quiz/module_quiz_screen.dart';
import 'package:algebrix/screens/practice/quiz_screen.dart';
import 'package:algebrix/screens/notes/note_detail_screen.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/screens/practice/quest_map_screen.dart';
import 'package:algebrix/screens/practice/balance_scale_screen.dart';
import 'package:algebrix/core/animations/app_page_route.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

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
    final quizProvider = context.watch<QuizProvider>();
    final questMapProvider = context.watch<QuestMapProvider>();

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

    // Determine latest unlocked module and active resumable lesson
    final allModules = [module1, module2, module3];
    final unlockedModules = allModules
        .where((m) => quizProvider.isModuleUnlocked(m.id))
        .toList();

    LessonContent? activeLesson;
    ModuleContent activeModule =
        unlockedModules.isNotEmpty ? unlockedModules.last : module1;

    for (final mod in unlockedModules.reversed) {
      for (final l in mod.lessons) {
        if (!lessonProvider.isLessonCompleted(l.lessonId)) {
          activeLesson = l;
          activeModule = mod;
          break;
        }
      }
      if (activeLesson != null) break;
    }

    activeLesson ??= activeModule.lessons.last;

    final currentLessonProgress =
        lessonProvider.progressFractionForLesson(activeLesson);
    final currentLessonRecord =
        lessonProvider.progressForLesson(activeLesson.lessonId);

    // Quiz Mastery calculation
    final passedQuizzesCount = ['module1', 'module2', 'module3']
        .where((id) => quizProvider.isModuleQuizPassed(id))
        .length;

    String nextQuizTitle = 'Module 1 Quiz';
    bool isNextQuizReady = quizProvider.isQuizUnlocked('module1', lessonProvider);
    ModuleContent nextQuizModule = module1;

    if (!quizProvider.isModuleQuizPassed('module1')) {
      nextQuizTitle = 'Module 1 Quiz (Foundations)';
      isNextQuizReady = quizProvider.isQuizUnlocked('module1', lessonProvider);
      nextQuizModule = module1;
    } else if (!quizProvider.isModuleQuizPassed('module2')) {
      nextQuizTitle = 'Module 2 Quiz (Expressions)';
      isNextQuizReady = quizProvider.isQuizUnlocked('module2', lessonProvider);
      nextQuizModule = module2;
    } else if (!quizProvider.isModuleQuizPassed('module3')) {
      nextQuizTitle = 'Module 3 Quiz (Equations)';
      isNextQuizReady = quizProvider.isQuizUnlocked('module3', lessonProvider);
      nextQuizModule = module3;
    } else {
      nextQuizTitle = 'All Quizzes Mastered';
      isNextQuizReady = true;
      nextQuizModule = module3;
    }

    final isSearching = _searchQuery.trim().isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RootPageHeader(
            title: 'Welcome Back!',
            subtitle: 'Ready to solve and level up, ${user.name}?',
            searchPlaceholder: 'Search lessons or topics',
            onSearchChanged: (q) => setState(() => _searchQuery = q),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSearching) ...[
                  _UniversalSearchResults(
                    query: _searchQuery,
                    notes: notesProvider.notes,
                    lessons: [
                      ...module1.lessons,
                      ...module2.lessons,
                      ...module3.lessons,
                    ],
                    onOpenLesson: (lesson) =>
                        _openLesson(context, lessonProvider, lesson),
                    onOpenNote: (note) {
                      notesProvider.selectNote(note.id);
                      Navigator.of(context).push(
                        AppPageRoute(
                          builder: (_) => NoteDetailScreen(note: note),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // 1. Algebria Adventure Shortcut Banner (Prominent Top Card)
                  _AlgebriaDashboardShortcut(
                    landAndLevel: questMapProvider.currentLandAndLevelLabel,
                    starsEarned: questMapProvider.activeLandStars,
                    maxStars: 30,
                    onTap: () {
                      Navigator.of(context).push(
                        AppPageRoute(child: const QuestMapScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Quick Action Feature Grid
                  Text(
                    'Quick Practice & Features',
                    style: AppTextStyles.heading3,
                  ),
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
                              AppPageRoute(
                                child: const BalanceScaleScreen(),
                              ),
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
                            Navigator.of(context).push(
                              AppPageRoute(
                                child: const QuizHubScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Continue Learning
                  Text('Continue Learning', style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  LessonCard(
                    lessonTitle: activeLesson.title,
                    moduleTitle: activeLesson.moduleTitle,
                    progress: currentLessonProgress,
                    progressText:
                        '${(currentLessonProgress * 100).round()}% complete',
                    onTap: lessonProvider.isBusy
                        ? null
                        : () => _openLesson(
                              context,
                              lessonProvider,
                              activeLesson!,
                            ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: currentLessonRecord == null
                        ? 'Start Lesson'
                        : lessonProvider.isLessonCompleted(
                            activeLesson.lessonId,
                          )
                        ? 'Review Lesson'
                        : 'Continue Lesson',
                    isLoading: lessonProvider.isRecording,
                    onPressed: lessonProvider.isBusy
                        ? null
                        : () => _openLesson(
                              context,
                              lessonProvider,
                              activeLesson!,
                            ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Quiz Mastery Status Card
                  _QuizMasteryDashboardCard(
                    passedCount: passedQuizzesCount,
                    totalQuizzes: 3,
                    nextQuizTitle: nextQuizTitle,
                    isNextQuizReady: isNextQuizReady,
                    onTap: () {
                      if (isNextQuizReady &&
                          !quizProvider.isModuleQuizPassed(nextQuizModule.id)) {
                        Navigator.of(context).push(
                          AppPageRoute(
                            child: ModuleQuizScreen(module: nextQuizModule),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          AppPageRoute(
                            child: const QuizHubScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // 5. Xy's Learning Tip
                  Text("Xy's Learning Tip", style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  _LearningTipCallout(message: AppStrings.tipOfTheDay),

                  const SizedBox(height: 24),
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
    final parentModule = module1.lessons.any((l) => l.lessonId == lesson.lessonId)
        ? module1
        : (module2.lessons.any((l) => l.lessonId == lesson.lessonId)
            ? module2
            : module3);
    lessonProvider.startModule(parentModule);
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
      AppPageRoute(child: const ModuleOverviewScreen()),
    );
    navigator.push(AppPageRoute(child: const LessonScreen()));
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
    return BouncyPressable(
      shrinkFactor: 0.95,
      enableHaptics: true,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
          MaterialPageRoute(builder: (_) => QuizScreen()),
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

class _QuizMasteryDashboardCard extends StatelessWidget {
  const _QuizMasteryDashboardCard({
    required this.passedCount,
    required this.totalQuizzes,
    required this.nextQuizTitle,
    required this.isNextQuizReady,
    required this.onTap,
  });

  final int passedCount;
  final int totalQuizzes;
  final String nextQuizTitle;
  final bool isNextQuizReady;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (passedCount / totalQuizzes).clamp(0.0, 1.0);
    final isAllPassed = passedCount >= totalQuizzes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🧠', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz Mastery Status',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAllPassed
                          ? 'All $totalQuizzes Quizzes Mastered! 🎉'
                          : '$passedCount of $totalQuizzes Quizzes Passed (${(percent * 100).round()}%)',
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.lightPurple,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  isAllPassed
                      ? 'Review your past scores or retake quizzes to practice.'
                      : (isNextQuizReady
                          ? '$nextQuizTitle is ready to test your knowledge!'
                          : 'Complete lessons to unlock $nextQuizTitle.'),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  backgroundColor: isNextQuizReady || isAllPassed
                      ? AppColors.lightPurple
                      : AppColors.border.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isAllPassed
                      ? 'Quiz Hub'
                      : (isNextQuizReady ? 'Take Quiz' : 'View Quizzes'),
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          XyMascot(
            asset: AppAssets.xyInsight,
            size: 46,
            shadowBlur: 3.0,
            shadowOpacity: 0.15,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlgebriaDashboardShortcut extends StatelessWidget {
  const _AlgebriaDashboardShortcut({
    required this.landAndLevel,
    required this.starsEarned,
    required this.maxStars,
    required this.onTap,
  });

  final String landAndLevel;
  final int starsEarned;
  final int maxStars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      shrinkFactor: 0.97,
      enableHaptics: true,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.extraLightPink.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.pink.withValues(alpha: 0.4),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Adventure cover artwork thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.pink.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                AppAssets.algebria,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),

            // Center: Location & Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.extraLightPink,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'ALGEBRIA QUEST',
                            style: GoogleFonts.nunito(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.pink,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              AppAssets.star,
                              width: 14,
                              height: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$starsEarned/$maxStars',
                              style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      landAndLevel,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to explore lands & solve puzzles',
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Right: Play CTA icon pill
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF69B4), Color(0xFFFF4081)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pink.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
