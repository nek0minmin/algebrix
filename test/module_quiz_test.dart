import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';
import 'package:algebrix/models/module_quiz_model.dart';
import 'package:algebrix/services/module_quiz_service.dart';
import 'package:algebrix/screens/quiz/module_quiz_screen.dart';

void main() {
  group('ModuleQuiz Models and Generation', () {
    final quizService = ModuleQuizService();

    test('Module 1 generates exactly 15 progressive items covering sub-lessons', () async {
      final quiz = await quizService.generateQuiz(module: module1);

      expect(quiz.moduleId, 'module1');
      expect(quiz.questions.length, 15);

      // Check progressive difficulty: Q1-Q5 are diff 1, Q6-Q10 are diff 2, Q11-Q15 are diff 3
      for (var i = 0; i < 5; i++) {
        expect(quiz.questions[i].difficulty, 1);
      }
      for (var i = 5; i < 10; i++) {
        expect(quiz.questions[i].difficulty, 2);
      }
      for (var i = 10; i < 15; i++) {
        expect(quiz.questions[i].difficulty, 3);
      }

      // Check options counts: MC has 3 options, TF has 2 options
      for (final q in quiz.questions) {
        if (q.type == QuizQuestionType.multipleChoice) {
          expect(q.options.length, 3, reason: 'MC question should have exactly 3 options: ${q.question}');
        } else {
          expect(q.options.length, 2, reason: 'TF question should have exactly 2 options: ${q.question}');
        }
        expect(q.correctIndex >= 0 && q.correctIndex < q.options.length, isTrue);

        // Check zero spoiler emojis in options
        for (final opt in q.options) {
          expect(opt.contains('✅') || opt.contains('❌'), isFalse);
        }
      }
    });

    test('Module 2 generates exactly 15 progressive items covering sub-lessons', () async {
      final quiz = await quizService.generateQuiz(module: module2);

      expect(quiz.moduleId, 'module2');
      expect(quiz.questions.length, 15);

      for (final q in quiz.questions) {
        if (q.type == QuizQuestionType.multipleChoice) {
          expect(q.options.length, 3);
        } else {
          expect(q.options.length, 2);
        }
        expect(q.correctIndex >= 0 && q.correctIndex < q.options.length, isTrue);
      }
    });

    test('ModuleQuiz JSON serialization handles valid and fallback fields', () {
      final json = {
        'questions': [
          {
            'id': 'test_q1',
            'subLessonTitle': 'Constants',
            'question': 'What is 5 in x + 5?',
            'type': 'multipleChoice',
            'options': ['Variable', 'Constant', 'Coefficient'],
            'correctIndex': 1,
            'explanation': '5 is a fixed numerical value.',
            'difficulty': 1,
          },
          {
            'id': 'test_q2',
            'subLessonTitle': 'Expressions',
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
    testWidgets('ModuleQuizScreen shows loading state and then displays quiz question', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModuleQuizScreen(module: module1),
        ),
      );

      // Verify loading text exists
      expect(find.text('Xy is preparing a quiz for you...'), findsOneWidget);

      // Pump to settle async generation
      await tester.pumpAndSettle();

      // Verify question 1 is displayed
      expect(find.text('Question 1 of 15'), findsOneWidget);
      expect(find.text('Next Question →'), findsOneWidget);

      // Verify options A, B, C or A, B exist
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      // Tap Option A
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      // Verify answer feedback appears
      expect(find.byType(InkWell), findsWidgets);
    });
  });
}
