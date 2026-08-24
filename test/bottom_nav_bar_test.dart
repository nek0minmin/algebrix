import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/core/providers/quiz_provider.dart';
import 'package:algebrix/models/lesson_progress_model.dart';
import 'package:algebrix/models/quest_map_model.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/models/user_model.dart';
import 'package:algebrix/navigation/main_shell.dart';
import 'package:algebrix/services/auth_service.dart';
import 'package:algebrix/services/notes_repository.dart';
import 'package:algebrix/services/progress_repository.dart';
import 'package:algebrix/services/quest_repository.dart';
import 'package:algebrix/services/quiz_repository.dart';
import 'package:algebrix/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeAuthService extends AuthService {
  final UserModel _user;
  _FakeAuthService(this._user);

  @override
  UserModel? getCurrentUser() => _user;

  @override
  bool get isAuthenticated => true;
}

class _FakeProgressRepository implements ProgressRepository {
  @override
  Future<LearningProfileSnapshot> fetchCurrentProfile() async {
    return const LearningProfileSnapshot(
      userId: 'user_1',
      xp: 150,
      level: 2,
      levelTitle: 'Math Explorer',
      streak: 3,
    );
  }

  @override
  Future<List<LessonProgress>> fetchModuleProgress(String moduleId) async => [];

  @override
  Future<RecordLessonStepResult> recordLessonStep({
    required String moduleId,
    required String lessonId,
    required String stepId,
    required int stepIndex,
    bool answerCorrect = false,
    int contentVersion = 1,
  }) async {
    return RecordLessonStepResult(
      xpAwarded: 10,
      stepXpAwarded: 10,
      completionXpAwarded: 0,
      totalXp: 100,
      level: 1,
      levelTitle: 'Math Beginner',
      completionRequirementsMet: false,
      progress: LessonProgress(
        userId: 'user_1',
        moduleId: moduleId,
        lessonId: lessonId,
        contentVersion: contentVersion,
        lastStepId: stepId,
        lastStepIndex: stepIndex,
        status: LessonProgressStatus.inProgress,
        startedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class _FakeNotesRepository implements NotesRepository {
  @override
  Future<StudyNote> createNote({
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    return StudyNote(
      id: 'note-1',
      userId: 'user_1',
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<bool> deleteNote(String noteId) async => true;

  @override
  Future<StudyNote?> fetchNoteById(String noteId) async => null;

  @override
  Future<List<StudyNote>> fetchNotes({String? moduleId, String? lessonId}) async => [];

  @override
  Future<StudyNote> updateNote({
    required String noteId,
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    return StudyNote(
      id: noteId,
      userId: 'user_1',
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class _FakeQuestRepository implements QuestRepository {
  @override
  Future<List<QuestLand>> fetchAllLands() async => [
    const QuestLand(
      id: 'balands',
      name: 'Balands',
      subtitle: 'The Land of Balancing',
      sortOrder: 1,
      totalLevels: 10,
      unlockStarsRequired: 0,
    ),
  ];

  @override
  Future<List<QuestLevelProgress>> fetchLandProgress(String landId) async => [];

  @override
  Future<int> fetchTotalStars() async => 0;

  @override
  Future<void> saveLevelResult({
    required String landId,
    required int levelNumber,
    required int starsEarned,
    required int moveCount,
    required bool reasoningPassed,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bottom navigation exposes the four requested destinations', (
    tester,
  ) async {
    var selectedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            onTap: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Lessons'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Quiz'), findsNothing);

    await tester.tap(find.text('Practice'));
    expect(selectedIndex, 2);

    await tester.tap(find.text('Notes'));
    expect(selectedIndex, 3);
  });

  testWidgets('MainShell navigation switches tabs seamlessly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeUser = UserModel(
      id: 'test-u',
      name: 'Alex',
      lastActive: DateTime.now(),
    );
    final authProvider = AuthProvider(authService: _FakeAuthService(fakeUser));
    final lessonProvider = LessonProvider(repository: _FakeProgressRepository());
    final notesProvider = NotesProvider(repository: _FakeNotesRepository());
    final questProvider = QuestMapProvider(repository: _FakeQuestRepository());
    final quizProvider = QuizProvider(repository: MemoryQuizRepository());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<LessonProvider>.value(value: lessonProvider),
          ChangeNotifierProvider<NotesProvider>.value(value: notesProvider),
          ChangeNotifierProvider<QuestMapProvider>.value(value: questProvider),
          ChangeNotifierProvider<QuizProvider>.value(value: quizProvider),
        ],
        child: const MaterialApp(
          home: MainShell(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial Home destination
    expect(find.text('Welcome Back!'), findsOneWidget);

    // Switch to Practice
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.text('Practice Arena'), findsOneWidget);

    // Switch to Notes
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Keep your algebra ideas close.'), findsOneWidget);
  });
}
