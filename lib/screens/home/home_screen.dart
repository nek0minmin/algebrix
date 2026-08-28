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
import 'package:algebrix/screens/notes/note_form_screen.dart';
import 'package:algebrix/screens/notes/note_lesson_options.dart';
import 'package:algebrix/services/ai_tutor_service.dart';
import 'package:algebrix/widgets/ai_feedback_card.dart';
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
                  // 1. Continue Learning
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

                  // 2. Quiz Mastery Status Card
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

                  // 3. Algebria Adventure Shortcut Banner (Prominent Top Card)
                  _AlgebriaDashboardShortcut(
                    landAndLevel: questMapProvider.frontierLandAndLevelLabel,
                    starsEarned: questMapProvider.frontierLandStars,
                    maxStars: 30,
                    onTap: () {
                      Navigator.of(context).push(
                        AppPageRoute(child: const QuestMapScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 4. Xy's Learning Tip (Dynamic rotating tip card)
                  _LearningTipCallout(
                    userSeed: user.id.hashCode ^ user.lastActive.day,
                  ),
                  const SizedBox(height: 24),

                  // 5. Recent Study Notes Section (Single latest note)
                  _RecentNotesDashboardSection(
                    notes: notesProvider.notes,
                    onOpenNote: (note) {
                      notesProvider.selectNote(note.id);
                      Navigator.of(context).push(
                        AppPageRoute(
                          builder: (_) => NoteDetailScreen(note: note),
                        ),
                      );
                    },
                    onCreateNote: () {
                      Navigator.of(context).push(
                        AppPageRoute(
                          builder: (_) => const NoteFormScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
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

class _RecentNotesDashboardSection extends StatelessWidget {
  const _RecentNotesDashboardSection({
    required this.notes,
    required this.onOpenNote,
    required this.onCreateNote,
  });

  final List<StudyNote> notes;
  final ValueChanged<StudyNote> onOpenNote;
  final VoidCallback onCreateNote;

  @override
  Widget build(BuildContext context) {
    final mostRecentNote = notes.isNotEmpty ? notes.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Study Notes',
                style: AppTextStyles.heading3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onCreateNote,
              icon: const Icon(Icons.add_rounded, size: 17, color: AppColors.pink),
              label: Text(
                'New note',
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pink,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                backgroundColor: AppColors.extraLightPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (mostRecentNote == null)
          _EmptyNotesDashboardCard(onCreateNote: onCreateNote)
        else
          _DashboardNoteCard(
            note: mostRecentNote,
            onTap: () => onOpenNote(mostRecentNote),
          ),
      ],
    );
  }
}

class _EmptyNotesDashboardCard extends StatelessWidget {
  const _EmptyNotesDashboardCard({required this.onCreateNote});

  final VoidCallback onCreateNote;

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      shrinkFactor: 0.98,
      onTap: onCreateNote,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.pink.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            XyMascot(
              asset: AppAssets.xyNotes,
              size: 88,
              shadowBlur: 4,
              shadowOpacity: 0.12,
            ),
            const SizedBox(height: 12),
            Text(
              'Write your first note!',
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Explain concepts in your own words & get Xy insights.',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5CA8), Color(0xFFFF4081)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pink.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Create Note',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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

class _DashboardNoteCard extends StatelessWidget {
  const _DashboardNoteCard({
    required this.note,
    required this.onTap,
  });

  final StudyNote note;
  final VoidCallback onTap;

  void _showInsightModal(BuildContext context, AiFeedbackResult feedback) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  XyMascot(
                    asset: AppAssets.xyInsight,
                    size: 34,
                    shadowBlur: 2,
                    shadowOpacity: 0.1,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Xy's Note Insight",
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: AiFeedbackCard(feedback: feedback),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiFeedback = note.aiFeedbackResult;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main card area (tappable to view note details)
          BouncyPressable(
            shrinkFactor: 0.98,
            enableHaptics: true,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, aiFeedback != null ? 6 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: 1.1 Variables (Left) | Updated on ... (Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.extraLightPink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            noteLessonLabel(note.lessonId),
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkPink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Updated ${formatNoteUpdatedAt(note.updatedAt)}',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    note.title,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Content
                  Text(
                    note.displayContent,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Row: Aligned to the right — Pink pill with Xy's mini pic
          if (aiFeedback != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showInsightModal(context, aiFeedback),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.extraLightPink,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.pink.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pink.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          XyMascot(
                            asset: AppAssets.xyInsight,
                            size: 18,
                            shadowBlur: 0,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Xy's Insight",
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkPink,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.visibility_rounded,
                            size: 14,
                            color: AppColors.darkPink,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
  const _LearningTipCallout({this.userSeed = 0});

  final int userSeed;

  static const List<Map<String, String>> _tips = [
    {
      'title': 'The Balance Scale Rule',
      'tip': 'Whatever operation you do to one side of the equals sign, you must always do to the other side to keep equality balanced!',
      'badge': 'Core Concept',
    },
    {
      'title': 'Undo with Inverse Operations',
      'tip': 'Addition undoes subtraction, and multiplication undoes division. Work backwards to isolate your mystery variable!',
      'badge': 'Problem Solving',
    },
    {
      'title': 'Check by Substitution',
      'tip': 'Always plug your solution back into the original equation! If both sides calculate to the same number, you know you are 100% right.',
      'badge': 'Pro Tip',
    },
    {
      'title': 'Like Terms Stick Together',
      'tip': 'You can only combine terms with matching variables and powers (like 3x + 5x = 8x, but 3x + 5 stays separate!).',
      'badge': 'Foundations',
    },
    {
      'title': 'Watch the Signs with Parentheses',
      'tip': 'When distributing a negative number into parentheses, remember that subtracting a negative turns into addition!',
      'badge': 'Caution Zone',
    },
    {
      'title': 'Keep Fractions Clean',
      'tip': 'Got fractions in your equation? Multiply every single term by the common denominator to wipe them out in one move!',
      'badge': 'Speed Tip',
    },
    {
      'title': 'Variables Are Mystery Boxes',
      'tip': 'Letters like x, y, and n are just friendly place-holders waiting for you to discover their hidden numeric value.',
      'badge': 'Mindset',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Rotate based on userSeed and current day of year
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = (userSeed.abs() + dayOfYear) % _tips.length;
    final currentTip = _tips[index];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.pink.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.extraLightPink.withValues(alpha: 0.6),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Section title + Topic Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: Color(0xFFFFB300),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Xy's Learning Tip",
                              style: AppTextStyles.heading3.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        currentTip['badge']!,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Body: Mascot + Quote speech box
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    XyMascot(
                      asset: AppAssets.xyInsight,
                      size: 68,
                      shadowBlur: 4.0,
                      shadowOpacity: 0.18,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTip['title']!,
                              style: GoogleFonts.nunito(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentTip['tip']!,
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
            // Left: Adventure cover artwork thumbnail (Prominent 76x76)
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.pink.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
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
                            horizontal: 10,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.extraLightPink,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'ALGEBRIA QUEST',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
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
                              width: 15,
                              height: 15,
                            ),
                            const SizedBox(width: 3.5),
                            Text(
                              '$starsEarned/$maxStars',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      landAndLevel,
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tap to explore lands & solve puzzles',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right: Clean sleek > arrow icon
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.pink,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
