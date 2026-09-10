import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algebrix/core/constants/app_avatars.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/core/providers/mastery_provider.dart';
import 'package:algebrix/core/providers/quiz_review_provider.dart';
import 'package:algebrix/models/lesson_progress_model.dart';
import 'package:algebrix/screens/profile/profile_screen.dart';
import 'package:algebrix/screens/review/review_hub_screen.dart';
import 'package:algebrix/services/auth_service.dart';
import 'package:algebrix/services/mastery_repository.dart';
import 'package:algebrix/services/progress_repository.dart';
import 'package:algebrix/services/quiz_review_repository.dart';
import 'package:algebrix/services/sound_service.dart';
import 'package:algebrix/widgets/app_header.dart';

class _StubProgressRepository implements ProgressRepository {
  @override
  Future<LearningProfileSnapshot> fetchCurrentProfile() async =>
      const LearningProfileSnapshot(
        userId: 'student_1',
        xp: 120,
        level: 1,
        levelTitle: 'Math Beginner',
        streak: 0,
      );

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
  }) =>
      Future.error(StateError('not used in this test'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapProfile() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService: AuthService()),
        ),
        ChangeNotifierProvider<LessonProvider>(
          create: (_) => LessonProvider(repository: _StubProgressRepository()),
        ),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  group('Audio & Sound card', () {
    testWidgets('lays out without overflow on a narrow phone', (tester) async {
      // 360x640 is the narrowest mainstream Android size; the switch used to
      // run 38px past the right edge here.
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapProfile());
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byKey(const Key('sound-effects-toggle')),
        250,
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'the Audio & Sound row must not overflow at 360px',
      );
    });

    testWidgets('toggling sound updates the service and the label',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await SoundService.setSoundEnabled(true);
      await tester.pumpWidget(wrapProfile());
      await tester.pump();

      final toggle = find.byKey(const Key('sound-effects-toggle'));
      await tester.scrollUntilVisible(toggle, 250);
      await tester.pump();

      expect(find.text('Tactile math pops & chimes enabled'), findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(SoundService.isSoundEnabled, isFalse);
      expect(find.text('Audio muted'), findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(SoundService.isSoundEnabled, isTrue);
    });

    testWidgets('the volume slider is present and disabled while muted',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await SoundService.setSoundEnabled(true);
      await SoundService.setSoundVolume(0.8);

      await tester.pumpWidget(wrapProfile());
      await tester.pump();

      final slider = find.byKey(const Key('sound-volume-slider'));
      await tester.scrollUntilVisible(slider, 250);
      await tester.pump();

      expect(slider, findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(tester.widget<Slider>(slider).onChanged, isNotNull);

      await tester.tap(find.byKey(const Key('sound-effects-toggle')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Slider>(slider).onChanged,
        isNull,
        reason: 'the slider stays visible but inert while muted',
      );

      await SoundService.setSoundEnabled(true);
    });
  });

  group('AppHeader avatar', () {
    testWidgets('falls back to the initial with no avatar chosen',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppHeader(userName: 'Myne')),
        ),
      );
      await tester.pump();

      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('renders the chosen preset avatar instead of the initial',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppHeader(
              userName: 'Myne',
              avatarKey: AppAvatars.options.first.key,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('M'), findsNothing);

      final images = tester.widgetList<Image>(find.byType(Image));
      final assets = images
          .map((image) => image.image)
          .whereType<AssetImage>()
          .map((provider) => provider.assetName);
      expect(assets, contains(AppAvatars.options.first.asset));
    });

    testWidgets('ignores an avatar key this build does not ship',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppHeader(userName: 'Myne', avatarKey: 'xy-from-the-future'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('M'), findsOneWidget);
    });
  });

  group('Review hub tab labels', () {
    testWidgets('show their full word on a narrow screen, with badges',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final quizReview =
          QuizReviewProvider(repository: MemoryQuizReviewRepository());
      final mastery = MasteryProvider(repository: MemoryMasteryRepository());
      quizReview.bindAccount('student_1');
      mastery.bindAccount('student_1');
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      await mastery.recordLessonMiss(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        stepId: 'step4',
        stepIndex: 3,
        question: 'Expand 2(x+3)',
        options: const ['2x+6', '2x+3'],
        correctIndex: 0,
        selectedIndex: 1,
        explanation: '',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<QuizReviewProvider>.value(value: quizReview),
            ChangeNotifierProvider<MasteryProvider>.value(value: mastery),
          ],
          child: const MaterialApp(home: ReviewHubScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Full words, not "Maste..." / "Pr..." — FittedBox scales rather than
      // ellipsising, so the text itself is always complete.
      for (final label in ['Practice', 'Mastery', 'History']) {
        expect(
          find.text(label),
          findsOneWidget,
          reason: '$label must render in full',
        );
      }

      expect(tester.takeException(), isNull);
    });
  });
}
