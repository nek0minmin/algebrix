import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/ai_notes_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/balance_scale_provider.dart';
import 'core/providers/pairadise_provider.dart';
import 'core/providers/lesson_provider.dart';
import 'core/providers/notes_provider.dart';
import 'core/providers/quest_map_provider.dart';
import 'core/providers/quiz_provider.dart';
import 'core/theme/app_theme.dart';
import 'models/lesson_progress_model.dart';
import 'models/module_quiz_progress_model.dart';
import 'models/quest_map_model.dart';
import 'models/study_note_model.dart';
import 'services/ai_tutor_service.dart';
import 'services/auth_service.dart';
import 'services/notes_repository.dart';
import 'services/progress_repository.dart';
import 'services/quest_repository.dart';
import 'services/quiz_repository.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Environment Variables (.env)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Dotenv loading warning: $e');
  }

  // Lock to portrait mode for optimal learning experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase Cloud Backend Connection
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

  runApp(const AlgebrixApp());
}

class AlgebrixApp extends StatelessWidget {
  const AlgebrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) =>
              AuthProvider(authService: context.read<AuthService>()),
        ),
        Provider<AiTutorService>(create: (_) => AiTutorService()),
        ChangeNotifierProvider<AiNotesProvider>(
          create: (context) => AiNotesProvider(
            aiService: context.read<AiTutorService>(),
          ),
        ),
        Provider<ProgressRepository>(
          create: (_) => _createProgressRepository(),
        ),
        Provider<NotesRepository>(create: (_) => _createNotesRepository()),
        Provider<QuestRepository>(create: (_) => _createQuestRepository()),
        Provider<QuizRepository>(create: (_) => _createQuizRepository()),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          ProgressRepository,
          LessonProvider
        >(
          create: (context) =>
              LessonProvider(repository: context.read<ProgressRepository>()),
          update: (context, authProvider, repository, lessonProvider) {
            final provider =
                lessonProvider ?? LessonProvider(repository: repository);
            provider.bindAccount(authProvider.currentUser?.id);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          NotesRepository,
          NotesProvider
        >(
          create: (context) =>
              NotesProvider(repository: context.read<NotesRepository>()),
          update: (context, authProvider, repository, notesProvider) {
            final provider =
                notesProvider ?? NotesProvider(repository: repository);
            provider.bindAccount(authProvider.currentUser?.id);
            return provider;
          },
        ),
        ChangeNotifierProvider<BalanceScaleProvider>(
          create: (_) => BalanceScaleProvider(),
        ),
        ChangeNotifierProvider<PairadiseProvider>(
          create: (_) => PairadiseProvider(),
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          QuestRepository,
          QuestMapProvider
        >(
          create: (context) => QuestMapProvider(
            repository: context.read<QuestRepository>(),
          ),
          update: (context, authProvider, repository, questMapProvider) {
            final provider =
                questMapProvider ?? QuestMapProvider(repository: repository);
            provider.bindAccount(authProvider.currentUser?.id);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          QuizRepository,
          QuizProvider
        >(
          create: (context) => QuizProvider(
            repository: context.read<QuizRepository>(),
          ),
          update: (context, authProvider, repository, quizProvider) {
            final provider =
                quizProvider ?? QuizProvider(repository: repository);
            provider.bindAccount(authProvider.currentUser?.id);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Algebrix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

ProgressRepository _createProgressRepository() {
  try {
    return SupabaseProgressRepository();
  } catch (_) {
    return const _UnavailableProgressRepository();
  }
}

NotesRepository _createNotesRepository() {
  try {
    return SupabaseNotesRepository();
  } catch (_) {
    return const _UnavailableNotesRepository();
  }
}

QuestRepository _createQuestRepository() {
  try {
    return SupabaseQuestRepository();
  } catch (_) {
    return const _UnavailableQuestRepository();
  }
}

QuizRepository _createQuizRepository() {
  try {
    return SupabaseQuizRepository();
  } catch (_) {
    return const _UnavailableQuizRepository();
  }
}

class _UnavailableQuizRepository implements QuizRepository {
  const _UnavailableQuizRepository();

  @override
  Future<List<ModuleQuizProgress>> fetchAllQuizProgress() => Future.value([]);

  @override
  Future<ModuleQuizProgress?> fetchQuizProgress(String moduleId) =>
      Future.value(null);

  @override
  Future<ModuleQuizProgress> saveQuizResult({
    required String moduleId,
    required int score,
    required int totalQuestions,
  }) {
    final percentage =
        totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;
    return Future.value(
      ModuleQuizProgress(
        userId: 'offline_user',
        moduleId: moduleId,
        highScore: score,
        totalQuestions: totalQuestions,
        bestPercentage: percentage,
        passed: percentage >= 60.0,
        attemptsCount: 1,
        lastScore: score,
        lastPercentage: percentage,
        lastAttemptAt: DateTime.now(),
      ),
    );
  }
}

class _UnavailableProgressRepository implements ProgressRepository {
  const _UnavailableProgressRepository();

  @override
  Future<LearningProfileSnapshot> fetchCurrentProfile() =>
      Future.error(StateError('Supabase progress is unavailable.'));

  @override
  Future<List<LessonProgress>> fetchModuleProgress(String moduleId) =>
      Future.error(StateError('Supabase progress is unavailable.'));

  @override
  Future<RecordLessonStepResult> recordLessonStep({
    required String moduleId,
    required String lessonId,
    required String stepId,
    required int stepIndex,
    bool answerCorrect = false,
    int contentVersion = 1,
  }) => Future.error(StateError('Supabase progress is unavailable.'));
}

class _UnavailableNotesRepository implements NotesRepository {
  const _UnavailableNotesRepository();

  StateError get _error => StateError('Supabase study notes are unavailable.');

  @override
  Future<StudyNote> createNote({
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) => Future<StudyNote>.error(_error);

  @override
  Future<bool> deleteNote(String noteId) => Future<bool>.error(_error);

  @override
  Future<StudyNote?> fetchNoteById(String noteId) =>
      Future<StudyNote?>.error(_error);

  @override
  Future<List<StudyNote>> fetchNotes({String? moduleId, String? lessonId}) =>
      Future<List<StudyNote>>.error(_error);

  @override
  Future<StudyNote> updateNote({
    required String noteId,
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) => Future<StudyNote>.error(_error);
}

class _UnavailableQuestRepository implements QuestRepository {
  const _UnavailableQuestRepository();

  @override
  Future<List<QuestLand>> fetchAllLands() => Future.value([
        const QuestLand(
          id: 'balands',
          name: 'Balands',
          subtitle: 'The Land of Balancing',
          sortOrder: 1,
          totalLevels: 10,
          unlockStarsRequired: 0,
        ),
      ]);

  @override
  Future<List<QuestLevelProgress>> fetchLandProgress(String landId) =>
      Future.value([]);

  @override
  Future<int> fetchTotalStars() => Future.value(0);

  @override
  Future<void> saveLevelResult({
    required String landId,
    required int levelNumber,
    required int starsEarned,
    required int moveCount,
    required bool reasoningPassed,
  }) =>
      Future.value();
}
