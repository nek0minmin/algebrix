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
import 'package:algebrix/screens/home/home_screen.dart';
import 'package:algebrix/services/auth_service.dart';
import 'package:algebrix/services/notes_repository.dart';
import 'package:algebrix/services/progress_repository.dart';
import 'package:algebrix/services/quest_repository.dart';
import 'package:algebrix/services/quiz_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthService extends AuthService {
  final UserModel _user;
  _FakeAuthService(this._user);

  @override
  UserModel? get currentUser => _user;

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
  List<StudyNote> notes = [];

  @override
  Future<StudyNote> createNote({
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    final note = StudyNote(
      id: 'note-${notes.length + 1}',
      userId: 'user_1',
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notes.add(note);
    return note;
  }

  @override
  Future<bool> deleteNote(String noteId) async {
    notes.removeWhere((n) => n.id == noteId);
    return true;
  }

  @override
  Future<StudyNote?> fetchNoteById(String noteId) async =>
      notes.where((n) => n.id == noteId).firstOrNull;

  @override
  Future<List<StudyNote>> fetchNotes({String? moduleId, String? lessonId}) async =>
      List.from(notes);

  @override
  Future<StudyNote> updateNote({
    required String noteId,
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    final index = notes.indexWhere((n) => n.id == noteId);
    final updated = StudyNote(
      id: noteId,
      userId: 'user_1',
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (index >= 0) notes[index] = updated;
    return updated;
  }
}

class _FakeQuestRepository implements QuestRepository {
  final List<QuestLand> _lands = [
    const QuestLand(
      id: 'balands',
      name: 'Balands',
      subtitle: 'The Land of Balancing',
      sortOrder: 1,
      totalLevels: 10,
      unlockStarsRequired: 0,
    ),
    const QuestLand(
      id: 'pairadise',
      name: 'Pairadise',
      subtitle: 'The Land of Pairs',
      sortOrder: 2,
      totalLevels: 10,
      unlockStarsRequired: 25,
    ),
  ];

  final Map<String, Map<int, QuestLevelProgress>> _progressByLand = {
    'balands': {},
    'pairadise': {},
  };

  @override
  Future<List<QuestLand>> fetchAllLands() async => _lands;

  @override
  Future<List<QuestLevelProgress>> fetchLandProgress(String landId) async {
    return _progressByLand[landId]?.values.toList() ?? [];
  }

  @override
  Future<int> fetchTotalStars() async {
    int sum = 0;
    for (final landProgress in _progressByLand.values) {
      for (final p in landProgress.values) {
        sum += p.starsEarned;
      }
    }
    return sum;
  }

  @override
  Future<void> saveLevelResult({
    required String landId,
    required int levelNumber,
    required int starsEarned,
    required int moveCount,
    required bool reasoningPassed,
  }) async {
    final landMap = _progressByLand.putIfAbsent(landId, () => {});
    landMap[levelNumber] = QuestLevelProgress(
      userId: 'user_1',
      landId: landId,
      levelNumber: levelNumber,
      starsEarned: starsEarned,
      bestMoves: moveCount,
      reasoningPassed: reasoningPassed,
      completedAt: DateTime.now(),
    );
  }
}
 
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeScreen Dashboard Tests', () {
    testWidgets('Dashboard displays Algebria frontier, removes Quick Features, and shows Empty Notes state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeUser = UserModel(
        id: 'test-u',
        name: 'Min',
        lastActive: DateTime.now(),
      );
      final authProvider = AuthProvider(authService: _FakeAuthService(fakeUser));
      final lessonProvider = LessonProvider(repository: _FakeProgressRepository());
      final fakeNotesRepo = _FakeNotesRepository();
      final notesProvider = NotesProvider(repository: fakeNotesRepo);
      final fakeQuestRepo = _FakeQuestRepository();
      final questProvider = QuestMapProvider(repository: fakeQuestRepo);
      final quizProvider = QuizProvider(repository: MemoryQuizRepository());

      await questProvider.loadQuestMap();

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

      // 1. Algebria Quest Frontier is shown (Balands I for fresh user)
      expect(find.text('ALGEBRIA QUEST'), findsOneWidget);
      expect(find.text('Balands I'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsWidgets);

      // 2. Quick Practice & Features section is REMOVED
      expect(find.text('Quick Practice & Features'), findsNothing);
      expect(find.text('Visual Equations'), findsNothing);

      // 3. Recent Study Notes section is visible with empty state
      expect(find.text('Recent Study Notes'), findsOneWidget);
      expect(find.text('New note'), findsOneWidget);
      expect(find.text('Write your first note!'), findsOneWidget);
      expect(find.text('Create Note'), findsOneWidget);
    });

    testWidgets('Dashboard displays up to 3 recent notes with content and Xy insight button', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeUser = UserModel(
        id: 'test-u',
        name: 'Min',
        lastActive: DateTime.now(),
      );
      final authProvider = AuthProvider(authService: _FakeAuthService(fakeUser));
      final lessonProvider = LessonProvider(repository: _FakeProgressRepository());
      final fakeNotesRepo = _FakeNotesRepository();

      // Seed notes (one with AI insight)
      fakeNotesRepo.notes = [
        StudyNote(
          id: 'note-1',
          userId: 'test-u',
          moduleId: 'module1',
          lessonId: '1.1',
          title: 'What is a variable?',
          content: 'A variable is a placeholder for a number we do not know yet.',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          aiFeedbackTitle: 'Great Job!',
          aiFeedbackMessage: 'Your definition of a variable is clear and spot-on!',
          aiFeedbackWhyItWorks: 'Understanding variables builds the foundation for solving equations.',
        ),
        StudyNote(
          id: 'note-2',
          userId: 'test-u',
          moduleId: 'module2',
          lessonId: '2.1',
          title: 'Inverse operations',
          content: 'Addition undoes subtraction and multiplication undoes division.',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final notesProvider = NotesProvider(repository: fakeNotesRepo);
      notesProvider.bindAccount('test-u');
      await notesProvider.loadNotes();

      final fakeQuestRepo = _FakeQuestRepository();
      final questProvider = QuestMapProvider(repository: fakeQuestRepo);
      await questProvider.loadQuestMap();

      for (int i = 1; i <= 10; i++) {
        await questProvider.submitLevelResult(
          landId: 'balands',
          levelNumber: i,
          moveCount: 1,
          optimalMoves: 1,
          reasoningPassed: true,
        );
      }
      for (int i = 1; i <= 4; i++) {
        await questProvider.submitLevelResult(
          landId: 'pairadise',
          levelNumber: i,
          moveCount: 1,
          optimalMoves: 1,
          reasoningPassed: true,
        );
      }

      await questProvider.switchLand('balands'); // activeLand is balands, frontier is Pairadise V

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

      // Frontier shows Pairadise V even though activeLand is balands!
      expect(find.text('Pairadise V'), findsOneWidget);

      // Verify Note cards render title and content
      expect(find.text('What is a variable?'), findsOneWidget);
      expect(
        find.text('A variable is a placeholder for a number we do not know yet.'),
        findsOneWidget,
      );
      expect(find.text('Inverse operations'), findsOneWidget);

      // Note 1 has AI feedback -> shows "Xy's Saved Insight"
      expect(find.text("Xy's Saved Insight"), findsOneWidget);

      // Tap "Xy's Saved Insight" -> opens insight modal bottom sheet
      await tester.tap(find.text("Xy's Saved Insight"));
      await tester.pumpAndSettle();

      expect(find.text("Xy's Note Insight"), findsOneWidget);
      expect(find.text('Great Job!'), findsOneWidget);
    });
  });
}
