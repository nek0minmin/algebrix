import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/providers/quiz_provider.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';
import 'package:algebrix/data/module3_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/module_quiz_model.dart';
import 'package:algebrix/services/module_quiz_service.dart';
import 'package:algebrix/services/quiz_repository.dart';
import 'package:algebrix/screens/quiz/module_quiz_screen.dart';

class _StubQuizService extends ModuleQuizService {
  @override
  Future<ModuleQuiz> generateQuiz({required ModuleContent module}) async {
    return ModuleQuiz(
      moduleId: module.id,
      moduleTitle: module.title,
      questions: const [
        ModuleQuizQuestion(
          id: 'q1',
          subLessonTitle: 'Variables',
          question: 'What is x in 2x + 1?',
          type: QuizQuestionType.multipleChoice,
          options: ['2', 'x', '1'],
          correctIndex: 1,
          explanation: 'x is the variable.',
          difficulty: 1,
        ),
      ],
      generatedAt: DateTime.now(),
      providerUsed: 'Test Stub',
    );
  }
}

class _StubEquationQuizService extends ModuleQuizService {
  @override
  Future<ModuleQuiz> generateQuiz({required ModuleContent module}) async {
    return ModuleQuiz(
      moduleId: module.id,
      moduleTitle: module.title,
      questions: const [
        ModuleQuizQuestion(
          id: 'q1',
          subLessonTitle: 'Combining Like Terms',
          question: 'Simplify the expression by combining like terms: 6k + 4 − 2k + 9',
          type: QuizQuestionType.multipleChoice,
          options: ['4k + 13', '8k + 13', '4k + 5'],
          correctIndex: 0,
          explanation: 'Group like terms: (6k − 2k) + (4 + 9) = 4k + 13.',
          difficulty: 3,
        ),
      ],
      generatedAt: DateTime.now(),
      providerUsed: 'Test Stub',
    );
  }
}

void main() {
  group('ModuleQuiz Models and Generation', () {
    final quizService = ModuleQuizService();

    test('Module 1 generates exactly 10 progressive items strictly within Module 1 scope', () async {
      final quiz = await quizService.generateQuiz(module: module1);

      expect(quiz.moduleId, 'module1');
      expect(quiz.questions.length, 10);

      // Verify difficulty progression (3 Foundations, 4 Procedural, 3 Mastery)
      for (var i = 0; i < 3; i++) {
        expect(quiz.questions[i].difficulty, 1);
      }
      for (var i = 3; i < 7; i++) {
        expect(quiz.questions[i].difficulty, 2);
      }
      for (var i = 7; i < 10; i++) {
        expect(quiz.questions[i].difficulty, 3);
      }

      // Verify negative constant question in Module 1 Seed Bank (Q2)
      final qConstant = quiz.questions.firstWhere(
        (q) => q.subLessonTitle.toLowerCase().contains('constant'),
      );
      expect(qConstant.options[qConstant.correctIndex], startsWith('−'));

      // Verify strict scope: NO distributive property, NO combining like terms, NO substitution
      for (final q in quiz.questions) {
        final lowerQ = q.question.toLowerCase();
        final lowerSub = q.subLessonTitle.toLowerCase();

        expect(lowerQ, isNot(contains('distributive')));
        expect(lowerQ, isNot(contains('combine like terms')));
        expect(lowerQ, isNot(contains('like terms')));
        expect(lowerQ, isNot(contains('commutative')));
        expect(lowerQ, isNot(contains('associative')));
        expect(lowerSub, isNot(contains('distributive')));
        expect(lowerSub, isNot(contains('like terms')));
      }
    });

    test('Module 2 generates exactly 10 progressive items strictly within Module 2 scope', () async {
      final quiz = await quizService.generateQuiz(module: module2);

      expect(quiz.moduleId, 'module2');
      expect(quiz.questions.length, 10);

      for (var i = 0; i < 3; i++) {
        expect(quiz.questions[i].difficulty, 1);
      }
      for (var i = 3; i < 7; i++) {
        expect(quiz.questions[i].difficulty, 2);
      }
      for (var i = 7; i < 10; i++) {
        expect(quiz.questions[i].difficulty, 3);
      }

      // Verify strict scope: all questions must be expressions/like terms/distributive/properties/evaluation
      for (final q in quiz.questions) {
        final lowerQ = q.question.toLowerCase();
        expect(lowerQ, isNot(contains('what is a variable')));
        expect(lowerQ, isNot(contains('what is a constant')));
        expect(lowerQ, isNot(contains('what is an algebraic expression')));
      }
    });

    test('Module 3 generates exactly 10 progressive items strictly within Module 3 scope', () async {
      final quiz = await quizService.generateQuiz(module: module3);

      expect(quiz.moduleId, 'module3');
      expect(quiz.questions.length, 10);

      // Verify difficulty progression (3 Foundations, 4 Procedural, 3 Mastery)
      for (var i = 0; i < 3; i++) {
        expect(quiz.questions[i].difficulty, 1);
      }
      for (var i = 3; i < 7; i++) {
        expect(quiz.questions[i].difficulty, 2);
      }
      for (var i = 7; i < 10; i++) {
        expect(quiz.questions[i].difficulty, 3);
      }

      // Verify strict scope: all questions must be equations / inverse operations / variables on both sides / parentheses / checking
      for (final q in quiz.questions) {
        final lowerQ = q.question.toLowerCase();
        expect(lowerQ, isNot(contains('system of equations')));
        expect(lowerQ, isNot(contains('quadratic formula')));
        expect(lowerQ, isNot(contains('inequality')));
      }
    });

    test('ModuleQuiz JSON serialization handles valid and fallback fields', () {
      final json = {
        'questions': [
          {
            'id': 'q1',
            'subLessonTitle': 'Like Terms',
            'question': 'Simplify 3x + 2x',
            'type': 'multipleChoice',
            'options': ['5x', '5x^2', '6x'],
            'correctIndex': 0,
            'explanation': 'Add coefficients 3 and 2.',
            'difficulty': 1,
          },
          {
            'id': 'q2',
            'subLessonTitle': 'Equations',
            'question': 'Is 2x = 4 an expression?',
            'type': 'trueFalse',
            'options': ['True', 'False'],
            'correctIndex': 1,
            'explanation': 'It is an equation because it has an equals sign.',
            'difficulty': 1,
          }
        ]
      };

      final quiz = ModuleQuiz.fromJson(
        json,
        moduleId: 'module1',
        moduleTitle: 'Algebra Foundations',
        providerUsed: 'Test Provider',
      );

      expect(quiz.questions.length, 2);
      expect(quiz.questions[0].type, QuizQuestionType.multipleChoice);
      expect(quiz.questions[0].options.length, 3);
      expect(quiz.questions[1].type, QuizQuestionType.trueFalse);
      expect(quiz.questions[1].options.length, 2);
    });
  });

  group('ModuleQuizScreen Widget Tests', () {
    testWidgets('ModuleQuizScreen shows loading state, question, option selection, and explanation', (tester) async {
      final quizProvider = QuizProvider(repository: MemoryQuizRepository());

      await tester.pumpWidget(
        ChangeNotifierProvider<QuizProvider>.value(
          value: quizProvider,
          child: MaterialApp(
            home: ModuleQuizScreen(
              module: module1,
              quizService: _StubQuizService(),
            ),
          ),
        ),
      );

      // Verify loading text exists
      expect(find.text('Xy is preparing a quiz for you...'), findsOneWidget);

      // Pump to settle async generation
      await tester.pumpAndSettle();

      // Verify question is displayed
      expect(find.text('Question 1 of 1'), findsOneWidget);
      expect(find.text('MULTIPLE CHOICE'), findsOneWidget);
      expect(find.text('Confirm Answer'), findsOneWidget);

      // Verify options 2, x, 1 exist
      expect(find.text('2'), findsOneWidget);
      expect(find.text('x'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Tap Option '2' (selects it)
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      // Tap 'Confirm Answer'
      await tester.tap(find.text('Confirm Answer'));
      await tester.pumpAndSettle();

      // Verify explanation appears right below mascot
      expect(find.text('x is the variable.'), findsOneWidget);
      expect(find.text('Finish Quiz'), findsOneWidget);
    });

    testWidgets('ModuleQuizScreen renders equation in single-line responsive block when prompt has a colon', (tester) async {
      final quizProvider = QuizProvider(repository: MemoryQuizRepository());

      await tester.pumpWidget(
        ChangeNotifierProvider<QuizProvider>.value(
          value: quizProvider,
          child: MaterialApp(
            home: ModuleQuizScreen(
              module: module2,
              quizService: _StubEquationQuizService(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Prompt part is separated cleanly
      expect(find.text('Simplify the expression by combining like terms:'), findsOneWidget);

      // Math equation is in dedicated single-line block
      expect(find.text('6k + 4 − 2k + 9'), findsOneWidget);
      expect(find.byType(FittedBox), findsWidgets);
    });

    testWidgets('ModuleQuizScreen renders long sub-lesson title on narrow screens without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final quizProvider = QuizProvider(repository: MemoryQuizRepository());

      await tester.pumpWidget(
        ChangeNotifierProvider<QuizProvider>.value(
          value: quizProvider,
          child: MaterialApp(
            home: ModuleQuizScreen(
              module: module1,
              quizService: _StubLongTitleQuizService(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Question 1 of 1'), findsOneWidget);
    });
  });
}

class _StubLongTitleQuizService extends ModuleQuizService {
  @override
  Future<ModuleQuiz> generateQuiz({required ModuleContent module}) async {
    return ModuleQuiz(
      moduleId: module.id,
      moduleTitle: module.title,
      generatedAt: DateTime.now(),
      providerUsed: 'Test Stub',
      questions: const [
        ModuleQuizQuestion(
          id: 'q-long-1',
          subLessonTitle: 'Order of Operations with Parentheses and Exponents (PEMDAS)',
          question: 'Evaluate: 7 + 3 * 5',
          options: ['22', '35', '10'],
          correctIndex: 0,
          explanation: 'Multiplication first: 3 * 5 = 15, then 7 + 15 = 22.',
          difficulty: 1,
          type: QuizQuestionType.multipleChoice,
        ),
      ],
    );
  }
}
