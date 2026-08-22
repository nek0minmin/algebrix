import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/module_quiz_model.dart';
import 'package:algebrix/services/module_quiz_service.dart';
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

void main() {
  group('ModuleQuiz Models and Generation', () {
    final quizService = ModuleQuizService();

    test('Module 1 generates exactly 15 progressive items covering sub-lessons', () async {
      final quiz = await quizService.generateQuiz(module: module1);

      expect(quiz.moduleId, 'module1');
      expect(quiz.questions.length, 15);

      for (var i = 0; i < 5; i++) {
        expect(quiz.questions[i].difficulty, 1);
      }
      for (var i = 5; i < 10; i++) {
        expect(quiz.questions[i].difficulty, 2);
      }
      for (var i = 10; i < 15; i++) {
        expect(quiz.questions[i].difficulty, 3);
      }
    });

    test('Module 2 generates exactly 15 progressive items covering sub-lessons', () async {
      final quiz = await quizService.generateQuiz(module: module2);

      expect(quiz.moduleId, 'module2');
      expect(quiz.questions.length, 15);

      for (var i = 0; i < 5; i++) {
        expect(quiz.questions[i].difficulty, 1);
      }
      for (var i = 5; i < 10; i++) {
        expect(quiz.questions[i].difficulty, 2);
      }
      for (var i = 10; i < 15; i++) {
        expect(quiz.questions[i].difficulty, 3);
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
      await tester.pumpWidget(
        MaterialApp(
          home: ModuleQuizScreen(
            module: module1,
            quizService: _StubQuizService(),
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
      expect(find.text('Finish Quiz 🎉'), findsOneWidget);
    });
  });
}
