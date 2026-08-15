import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/lesson_provider.dart';
import 'core/providers/notes_provider.dart';
import 'core/theme/app_theme.dart';
import 'models/lesson_progress_model.dart';
import 'models/study_note_model.dart';
import 'services/auth_service.dart';
import 'services/notes_repository.dart';
import 'services/progress_repository.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        Provider<ProgressRepository>(
          create: (_) => _createProgressRepository(),
        ),
        Provider<NotesRepository>(create: (_) => _createNotesRepository()),
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
