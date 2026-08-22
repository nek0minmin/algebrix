import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/module_quiz_model.dart';

/// Service powering AI-Generated Module Quizzes with multi-tier fallback (Gemini -> Groq -> NVIDIA -> Seed Bank).
class ModuleQuizService {
  final http.Client _client;

  ModuleQuizService({http.Client? client}) : _client = client ?? http.Client();

  String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  String get _nvidiaApiKey => dotenv.env['NVIDIA_API_KEY'] ?? '';

  /// Generates a 15-item progressive module quiz tailored to the specified module's sub-lessons.
  Future<ModuleQuiz> generateQuiz({
    required ModuleContent module,
  }) async {
    final subLessonsInfo = module.lessons
        .map((l) => '• ${l.title}: ${l.objective}')
        .join('\n');

    final systemPrompt = '''
You are Xy, the expert educational AI quiz master in Algebrix.
Create an engaging, 15-item progressive algebra quiz strictly based on the following module content:
Module: "${module.title}"
Sub-Lessons:
$subLessonsInfo

STRICT PEDAGOGICAL RULES:
1. Generate EXACTLY 15 questions in progressive order:
   - Questions 1 to 5 (Foundations & Definitions, difficulty: 1): Identifying terms, variables, constants, coefficients, and basic terminology.
   - Questions 6 to 10 (Procedural Operations, difficulty: 2): Combining like terms, distributing single multipliers, properties of operations, evaluating single substitutions, PEMDAS operations.
   - Questions 11 to 15 (Multi-Step Mastery & Traps, difficulty: 3): Multi-step distribution followed by combining like terms, multi-variable evaluation, nested order of operations, and conceptual reasoning.
2. Mix Question Types:
   - "multipleChoice": exactly 3 choices in "options" (e.g. ["Choice A", "Choice B", "Choice C"]).
   - "trueFalse": exactly 2 choices in "options" (e.g. ["True", "False"]).
3. Zero-Emoji Rule: NEVER include hint emojis (e.g. ✅, ❌, 💡, 🔍) in the question text or option labels!
4. Dynamic Questions: Use novel numbers/coefficients rather than copying exact examples from the lesson text.
5. Provide a clear, friendly "explanation" for every question explaining WHY the correct choice is right.

Return ONLY a JSON object with this EXACT structure:
{
  "questions": [
    {
      "id": "q1",
      "subLessonTitle": "Variables and Constants",
      "question": "In the expression 5n + 12, which part is the constant?",
      "type": "multipleChoice",
      "options": ["5", "n", "12"],
      "correctIndex": 2,
      "explanation": "12 is a standalone number with a fixed value, making it the constant.",
      "difficulty": 1
    }
  ]
}
''';

    final userPrompt = 'Generate a 15-question progressive quiz for module ${module.id} (${module.title}).';

    // 1. Try Gemini API if key is present
    if (_geminiApiKey.isNotEmpty) {
      try {
        debugPrint('Generating quiz via Google Gemini API...');
        final rawJson = await _callGemini(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
        final parsed = _parseQuizJson(
          rawJson,
          module: module,
          provider: 'Google Gemini AI',
        );
        if (parsed.questions.length >= 10) return parsed;
      } catch (e) {
        debugPrint('Gemini API error: $e. Falling back to Groq...');
      }
    }

    // 2. Try Groq API
    if (_groqApiKey.isNotEmpty) {
      try {
        debugPrint('Generating quiz via Groq Llama 3.3 70B...');
        final rawJson = await _callGroq(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
        final parsed = _parseQuizJson(
          rawJson,
          module: module,
          provider: 'Groq (Llama 3.3 70B)',
        );
        if (parsed.questions.length >= 10) return parsed;
      } catch (e) {
        debugPrint('Groq API error: $e. Falling back to NVIDIA NIM...');
      }
    }

    // 3. Try NVIDIA NIM API
    if (_nvidiaApiKey.isNotEmpty) {
      try {
        debugPrint('Generating quiz via NVIDIA NIM API...');
        final rawJson = await _callNvidia(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
        final parsed = _parseQuizJson(
          rawJson,
          module: module,
          provider: 'NVIDIA NIM',
        );
        if (parsed.questions.length >= 10) return parsed;
      } catch (e) {
        debugPrint('NVIDIA API error: $e. Using offline Seed Bank.');
      }
    }

    // 4. Offline Dynamic Seed Bank Fallback
    debugPrint('Generating quiz via Algebrix Dynamic Seed Bank...');
    return _generateSeedBankQuiz(module);
  }

  Future<String> _callGemini({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final models = [
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-flash-latest',
      'gemini-2.5-pro',
    ];

    Object? lastError;
    for (final model in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
        );

        final response = await _client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': '$systemPrompt\n\n$userPrompt'}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.3,
              'responseMimeType': 'application/json',
            }
          }),
        ).timeout(const Duration(seconds: 14));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['candidates'][0]['content']['parts'][0]['text'] as String;
        } else {
          lastError = Exception('Gemini $model status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('All Gemini models failed.');
  }

  Future<String> _callGroq({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final models = [
      'openai/gpt-oss-120b',
      'openai/gpt-oss-20b',
      'qwen/qwen3.6-27b',
    ];

    Object? lastError;
    for (final model in models) {
      try {
        final response = await _client.post(
          url,
          headers: {
            'Authorization': 'Bearer $_groqApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'temperature': 0.3,
            'response_format': {'type': 'json_object'},
          }),
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'] as String;
        } else {
          lastError = Exception('Groq $model status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('All Groq models failed.');
  }

  Future<String> _callNvidia({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final url = Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions');
    final response = await _client.post(
      url,
      headers: {
        'Authorization': 'Bearer $_nvidiaApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'meta/llama-3.3-70b-instruct',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.3,
      }),
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('NVIDIA status ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  ModuleQuiz _parseQuizJson(
    String raw, {
    required ModuleContent module,
    required String provider,
  }) {
    final cleanJson = _extractJson(raw);
    final decoded = jsonDecode(cleanJson) as Map<String, dynamic>;
    final parsed = ModuleQuiz.fromJson(
      decoded,
      moduleId: module.id,
      moduleTitle: module.title,
      providerUsed: provider,
    );

    // If AI generated fewer than 15 items, pad with seed bank items to guarantee 15
    if (parsed.questions.length < 15) {
      final seedQuiz = _generateSeedBankQuiz(module);
      final padded = List<ModuleQuizQuestion>.from(parsed.questions);
      for (final seedQ in seedQuiz.questions) {
        if (padded.length >= 15) break;
        if (!padded.any((q) => q.question == seedQ.question)) {
          padded.add(seedQ);
        }
      }
      return ModuleQuiz(
        moduleId: module.id,
        moduleTitle: module.title,
        questions: padded.take(15).toList(),
        generatedAt: DateTime.now(),
        providerUsed: provider,
      );
    }

    return ModuleQuiz(
      moduleId: module.id,
      moduleTitle: module.title,
      questions: parsed.questions.take(15).toList(),
      generatedAt: DateTime.now(),
      providerUsed: provider,
    );
  }

  String _extractJson(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) return trimmed;
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return trimmed.substring(start, end + 1);
    }
    return trimmed;
  }

  /// High-quality dynamic seed bank for Module 1 & Module 2 with 15 progressive items.
  ModuleQuiz _generateSeedBankQuiz(ModuleContent module) {
    final rng = Random();

    if (module.id == 'module2') {
      return _buildModule2SeedQuiz(rng);
    } else {
      return _buildModule1SeedQuiz(rng);
    }
  }

  ModuleQuiz _buildModule1SeedQuiz(Random rng) {
    final a = rng.nextInt(5) + 3; // 3 to 7
    final b = rng.nextInt(6) + 2; // 2 to 7
    final c = rng.nextInt(4) + 2; // 2 to 5

    final questions = <ModuleQuizQuestion>[
      // Level 1: Foundations (Q1 to Q5)
      const ModuleQuizQuestion(
        id: 'm1_q01',
        subLessonTitle: 'Variables',
        question: 'In the algebraic expression 7x + 4, which part represents the variable?',
        type: QuizQuestionType.multipleChoice,
        options: ['7', 'x', '4'],
        correctIndex: 1,
        explanation: 'A variable is a letter or symbol that represents an unknown quantity (x).',
        difficulty: 1,
      ),
      const ModuleQuizQuestion(
        id: 'm1_q02',
        subLessonTitle: 'Constants',
        question: 'True or False: A constant value never changes when the variable changes.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 0,
        explanation: 'True! Constants have fixed numerical values that do not depend on any variable.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm1_q03',
        subLessonTitle: 'Coefficients',
        question: 'What is the coefficient of the variable in the term −${a}y?',
        type: QuizQuestionType.multipleChoice,
        options: ['$a', '−$a', 'y'],
        correctIndex: 1,
        explanation: 'The sign in front belongs to the coefficient, so the multiplier is −$a.',
        difficulty: 1,
      ),
      const ModuleQuizQuestion(
        id: 'm1_q04',
        subLessonTitle: 'Coefficients',
        question: 'What is the coefficient of a standalone variable like "n"?',
        type: QuizQuestionType.multipleChoice,
        options: ['0', '1', 'n'],
        correctIndex: 1,
        explanation: 'A standalone variable always has an implicit (invisible) coefficient of 1 (1n = n).',
        difficulty: 1,
      ),
      const ModuleQuizQuestion(
        id: 'm1_q05',
        subLessonTitle: 'Expressions vs Equations',
        question: 'True or False: The statement "5x + 3 = 18" is an algebraic expression.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 1,
        explanation: 'False! The presence of an equals sign (=) makes it an equation, not an expression.',
        difficulty: 1,
      ),

      // Level 2: Procedural (Q6 to Q10)
      const ModuleQuizQuestion(
        id: 'm1_q06',
        subLessonTitle: 'Terms',
        question: 'How many terms are in the expression 4x + 7 − 3y + 2?',
        type: QuizQuestionType.multipleChoice,
        options: ['2', '3', '4'],
        correctIndex: 2,
        explanation: 'Addition and subtraction separate the 4 distinct terms: 4x, +7, −3y, and +2.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm1_q07',
        subLessonTitle: 'Order of Operations',
        question: 'In the calculation $a + $b × $c, which operation must be calculated first?',
        type: QuizQuestionType.multipleChoice,
        options: ['Addition ($a + $b)', 'Multiplication ($b × $c)', 'Any order works'],
        correctIndex: 1,
        explanation: 'According to PEMDAS, multiplication has higher priority than addition.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm1_q08',
        subLessonTitle: 'Order of Operations',
        question: 'Evaluate: 6 + 4 × 3',
        type: QuizQuestionType.multipleChoice,
        options: ['30', '18', '24'],
        correctIndex: 1,
        explanation: 'Multiply first: 4 × 3 = 12. Then add: 6 + 12 = 18.',
        difficulty: 2,
      ),
      const ModuleQuizQuestion(
        id: 'm1_q09',
        subLessonTitle: 'Terms and Signs',
        question: 'True or False: In 8x − 5y, the second term is 5y.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 1,
        explanation: 'False! The minus sign belongs to the term that follows it, making the term −5y.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm1_q10',
        subLessonTitle: 'Order of Operations',
        question: 'What is the value of (2 + 3) × 4?',
        type: QuizQuestionType.multipleChoice,
        options: ['14', '20', '24'],
        correctIndex: 1,
        explanation: 'Parentheses come first: 2 + 3 = 5. Then multiply: 5 × 4 = 20.',
        difficulty: 2,
      ),

      // Level 3: Multi-Step Mastery (Q11 to Q15)
      const ModuleQuizQuestion(
        id: 'm1_q11',
        subLessonTitle: 'Order of Operations',
        question: 'Evaluate: (5 + 3) × 2 − 4',
        type: QuizQuestionType.multipleChoice,
        options: ['12', '16', '8'],
        correctIndex: 0,
        explanation: 'Parentheses first: 5 + 3 = 8. Then multiply: 8 × 2 = 16. Finally subtract: 16 − 4 = 12.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm1_q12',
        subLessonTitle: 'Expressions and Equality',
        question: 'Why does 2 + 3 × 4 equal 14 instead of 20?',
        type: QuizQuestionType.multipleChoice,
        options: [
          'Multiplication precedes addition in PEMDAS',
          'Parentheses were assumed around 2 + 3',
          'Numbers are always evaluated left to right',
        ],
        correctIndex: 0,
        explanation: 'Multiplication has higher precedence than addition, so 3 × 4 = 12 is calculated before adding 2.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm1_q13',
        subLessonTitle: 'Order of Operations',
        question: 'True or False: Multiplication and Division have equal rank and are solved left to right.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 0,
        explanation: 'True! Multiplication and division share equal priority, so you work from left to right.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm1_q14',
        subLessonTitle: 'Advanced Order of Operations',
        question: 'Evaluate: 18 − 3 × (2 + 4) ÷ 2',
        type: QuizQuestionType.multipleChoice,
        options: ['9', '45', '15'],
        correctIndex: 0,
        explanation: 'Parentheses: 2 + 4 = 6. Multiply: 3 × 6 = 18. Divide: 18 ÷ 2 = 9. Subtract: 18 − 9 = 9.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm1_q15',
        subLessonTitle: 'Algebra Foundations Mastery',
        question: 'Which statement is completely TRUE?',
        type: QuizQuestionType.multipleChoice,
        options: [
          'Expressions have no equals sign; terms include their signs',
          'Coefficients change when variables take different values',
          'Equations cannot contain more than two terms',
        ],
        correctIndex: 0,
        explanation: 'Expressions are mathematical phrases without equals signs, and each term includes its preceding sign.',
        difficulty: 3,
      ),
    ];

    return ModuleQuiz(
      moduleId: 'module1',
      moduleTitle: 'Algebra Foundations',
      questions: questions,
      generatedAt: DateTime.now(),
      providerUsed: 'Algebrix Curated Seed Bank',
    );
  }

  ModuleQuiz _buildModule2SeedQuiz(Random rng) {
    final k = rng.nextInt(3) + 2; // 2 to 4
    final m = rng.nextInt(4) + 3; // 3 to 6

    final questions = <ModuleQuizQuestion>[
      // Level 1: Foundations (Q1 to Q5)
      const ModuleQuizQuestion(
        id: 'm2_q01',
        subLessonTitle: 'Like and Unlike Terms',
        question: 'Which of the following pairs contains LIKE TERMS?',
        type: QuizQuestionType.multipleChoice,
        options: ['4x and 9x', '3x and 3y', '5x and 5x²'],
        correctIndex: 0,
        explanation: 'Like terms must have the exact same variable raised to the exact same exponent (x).',
        difficulty: 1,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q02',
        subLessonTitle: 'Like and Unlike Terms',
        question: 'True or False: The terms 4a² and 7a² are like terms.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 0,
        explanation: 'True! Both terms share the exact same variable part: a².',
        difficulty: 1,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q03',
        subLessonTitle: 'Combining Like Terms',
        question: 'Simplify: 5x + 3x',
        type: QuizQuestionType.multipleChoice,
        options: ['8x', '8x²', '15x'],
        correctIndex: 0,
        explanation: 'Add the coefficients (5 + 3 = 8) and keep the variable part identical (8x).',
        difficulty: 1,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q04',
        subLessonTitle: 'Unlike Terms',
        question: 'True or False: 3x + 4y can be simplified to 7xy.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 1,
        explanation: 'False! 3x and 4y are unlike terms (different variables) and cannot be combined.',
        difficulty: 1,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q05',
        subLessonTitle: 'Properties of Operations',
        question: 'Which property is demonstrated by: a + b = b + a?',
        type: QuizQuestionType.multipleChoice,
        options: ['Commutative Property', 'Associative Property', 'Distributive Property'],
        correctIndex: 0,
        explanation: 'The Commutative Property allows changing the order of numbers in addition.',
        difficulty: 1,
      ),

      // Level 2: Procedural (Q6 to Q10)
      ModuleQuizQuestion(
        id: 'm2_q06',
        subLessonTitle: 'Distributive Property',
        question: 'Expand: $k(x + $m)',
        type: QuizQuestionType.multipleChoice,
        options: [
          '${k}x + ${k * m}',
          '${k}x + $m',
          '${k + m}x',
        ],
        correctIndex: 0,
        explanation: 'Multiply the outside factor by each inside term: ($k × x) + ($k × $m) = ${k}x + ${k * m}.',
        difficulty: 2,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q07',
        subLessonTitle: 'Distributive Property with Subtraction',
        question: 'Expand: 2(x − 5)',
        type: QuizQuestionType.multipleChoice,
        options: ['2x − 10', '2x − 5', '2x + 10'],
        correctIndex: 0,
        explanation: 'Distribute 2 to both terms: 2(x) + 2(−5) = 2x − 10.',
        difficulty: 2,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q08',
        subLessonTitle: 'Properties of Operations',
        question: 'True or False: Subtraction and Division are commutative operations.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 1,
        explanation: 'False! Changing order changes the result: 10 − 4 ≠ 4 − 10, and 10 ÷ 2 ≠ 2 ÷ 10.',
        difficulty: 2,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q09',
        subLessonTitle: 'Evaluating Expressions',
        question: 'If x = 4, evaluate the expression: 3x + 2',
        type: QuizQuestionType.multipleChoice,
        options: ['14', '18', '24'],
        correctIndex: 0,
        explanation: 'Substitute 4 for x: 3(4) + 2 = 12 + 2 = 14.',
        difficulty: 2,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q10',
        subLessonTitle: 'Identity Properties',
        question: 'According to the Identity Property of Multiplication, what is x × 1?',
        type: QuizQuestionType.multipleChoice,
        options: ['x', '1', '1x²'],
        correctIndex: 0,
        explanation: 'Multiplying any quantity by 1 preserves its original value (x).',
        difficulty: 2,
      ),

      // Level 3: Multi-Step Mastery (Q11 to Q15)
      const ModuleQuizQuestion(
        id: 'm2_q11',
        subLessonTitle: 'Simplifying Expressions',
        question: 'Simplify completely: 4x + 3 + 2x + 5',
        type: QuizQuestionType.multipleChoice,
        options: ['6x + 8', '14x', '6x + 15'],
        correctIndex: 0,
        explanation: 'Group like terms: (4x + 2x) + (3 + 5) = 6x + 8.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q12',
        subLessonTitle: 'Distribute & Combine',
        question: 'Simplify completely: 3(x + 2) + 4x',
        type: QuizQuestionType.multipleChoice,
        options: ['7x + 6', '7x + 2', '3x + 6'],
        correctIndex: 0,
        explanation: 'Distribute first: 3x + 6 + 4x. Then combine like terms: (3x + 4x) + 6 = 7x + 6.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q13',
        subLessonTitle: 'Multi-Variable Substitution',
        question: 'If a = 3 and b = 5, what is the value of 2a + 3b?',
        type: QuizQuestionType.multipleChoice,
        options: ['21', '16', '30'],
        correctIndex: 0,
        explanation: 'Substitute: 2(3) + 3(5) = 6 + 15 = 21.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q14',
        subLessonTitle: 'Simplification Invariants',
        question: 'True or False: Simplifying 3x + 2x + 4 to 5x + 4 changes the value of the expression.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 1,
        explanation: 'False! Simplifying rewrites an expression in an equivalent, cleaner form without changing its value.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q15',
        subLessonTitle: 'Comprehensive Mastery Challenge',
        question: 'Simplify and evaluate 2(x + 3) + 3x when x = 2:',
        type: QuizQuestionType.multipleChoice,
        options: ['16', '14', '18'],
        correctIndex: 0,
        explanation: 'Simplify: 2x + 6 + 3x = 5x + 6. Substitute x = 2: 5(2) + 6 = 10 + 6 = 16.',
        difficulty: 3,
      ),
    ];

    return ModuleQuiz(
      moduleId: 'module2',
      moduleTitle: 'Working with Expressions',
      questions: questions,
      generatedAt: DateTime.now(),
      providerUsed: 'Algebrix Curated Seed Bank',
    );
  }
}
