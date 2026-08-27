import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/module_quiz_model.dart';

/// Service powering AI-Generated Module Quizzes with multi-tier fallback (Gemini -> Groq -> NVIDIA -> Seed Bank).
/// Enforces strict module-specific scope constraints, 10 progressive items, and mathematical accuracy.
class ModuleQuizService {
  final http.Client _client;

  ModuleQuizService({http.Client? client}) : _client = client ?? http.Client();

  String get _geminiApiKey {
    try {
      return dotenv.isInitialized ? (dotenv.env['GEMINI_API_KEY'] ?? '') : '';
    } catch (_) {
      return '';
    }
  }

  String get _groqApiKey {
    try {
      return dotenv.isInitialized ? (dotenv.env['GROQ_API_KEY'] ?? '') : '';
    } catch (_) {
      return '';
    }
  }

  String get _nvidiaApiKey {
    try {
      return dotenv.isInitialized ? (dotenv.env['NVIDIA_API_KEY'] ?? '') : '';
    } catch (_) {
      return '';
    }
  }

  /// Builds a dedicated, strict system prompt tailored to the requested module's exact curriculum.
  String _buildSystemPrompt(ModuleContent module) {
    if (module.id == 'module3') {
      return _buildModule3SystemPrompt();
    } else if (module.id == 'module2') {
      return _buildModule2SystemPrompt();
    } else {
      return _buildModule1SystemPrompt();
    }
  }

  String _buildModule1SystemPrompt() {
    return '''
You are Xy, the expert educational AI quiz master in Algebrix.
Create an engaging, 10-item progressive algebra quiz strictly based on Module 1 ("Algebra Foundations").

MODULE 1 SCOPE (ONLY USE THESE 6 LESSONS):
• Variables: Unknown or changing quantities represented by letters (x, y, n, a, b).
• Constants: Fixed standalone numerical values that do not change (e.g. in 9y − 12, the constant is −12; signs belong to the term).
• Coefficients: Numbers multiplying variables (e.g. 7 in 7x, −3 in −3y, implicit 1 in standalone n).
• Terms: Parts of an expression separated by + and − (the sign belongs to the term, e.g. 4x − 3y has terms 4x and −3y).
• Expressions vs Equations: Expressions have NO equals sign (e.g. 5x + 3); Equations MUST have an equals sign (e.g. 5x + 3 = 18).
• Order of Operations (PEMDAS): Numerical arithmetic order of operations (Parentheses, Exponents, Multiplication & Division left-to-right, Addition & Subtraction left-to-right).

STRICT NEGATIVE CONSTRAINTS (FORBIDDEN IN MODULE 1):
❌ DO NOT ask questions about Combining Like Terms (e.g. 3x + 5x = 8x). That belongs to Module 2.
❌ DO NOT ask questions about the Distributive Property (e.g. 2(x + 3)). That belongs to Module 2.
❌ DO NOT ask questions about Properties of Operations (Commutative, Associative, Identity, etc.). That belongs to Module 2.
❌ DO NOT ask questions about evaluating expressions with variable substitution (e.g. If x = 4, find 3x + 2). That belongs to Module 2.
❌ DO NOT ask questions about solving equations for x.

10-QUESTION PROGRESSION BREAKDOWN:
- Questions 1 to 3 (Difficulty: 1, Foundations): Identifying variables, constants (including negative constants like −12 in 9y − 12), and coefficients.
- Questions 4 to 7 (Difficulty: 2, Procedural Foundations): Expressions vs equations, counting terms & signs, standalone variable coefficients, basic 2-step PEMDAS arithmetic (e.g. "Evaluate: 6 + 4 × 3").
- Questions 8 to 10 (Difficulty: 3, Mastery & PEMDAS Traps): Multi-step arithmetic order of operations with parentheses (e.g. "Evaluate: (5 + 3) × 2 − 4", "Evaluate: 18 − 3 × (2 + 4) ÷ 2"), left-to-right rule on equal priority.

MATHEMATICAL RIGOR & EXPLANATION RULES:
1. Every calculation MUST be exact. Verify the math before outputting choices!
2. The correct answer MUST be present in the options list and match correctIndex.
3. NEVER include internal chain-of-thought, reasoning steps, or scratchpad text (e.g. "Wait correction", "None match", "Adjust options") in the explanation or question!
4. When a question asks to evaluate an arithmetic expression, format it with a colon before the math: e.g. "Evaluate: 6 + 4 × 3" or "What is the value of: (2 + 3) × 4".
5. Mix Question Types: "multipleChoice" (3 options) and "trueFalse" (2 options).
6. Zero-Emoji Rule: NEVER include hint emojis in question text or options.

Return ONLY a JSON object with this EXACT structure:
{
  "questions": [
    {
      "id": "m1_q1",
      "subLessonTitle": "Variables",
      "question": "In the algebraic expression 7x + 4, which part represents the variable?",
      "type": "multipleChoice",
      "options": ["7", "x", "4"],
      "correctIndex": 1,
      "explanation": "A variable is a letter that represents an unknown quantity (x).",
      "difficulty": 1
    }
  ]
}
''';
  }

  String _buildModule2SystemPrompt() {
    return '''
You are Xy, the expert educational AI quiz master in Algebrix.
Create an engaging, 10-item progressive algebra quiz strictly based on Module 2 ("Working with Expressions").

MODULE 2 SCOPE (ONLY USE THESE 7 LESSONS):
• Like and Unlike Terms: Identifying matching variable parts and exponents (e.g. 4x and 9x are like terms; 3x and 3y are unlike terms).
• Combining Like Terms: Adding/subtracting coefficients of like terms while keeping unlike terms separate (e.g. 5x + 3x = 8x, 6k + 4 − 2k + 9 = 4k + 13).
• Distributive Property: Multiplying an outside multiplier by each inside term (e.g. 3(x + 4) = 3x + 12, 2(x − 5) = 2x − 10).
• Properties of Operations: Commutative Property (a + b = b + a), Associative Property ((a + b) + c = a + (b + c)), Identity Property of Addition (x + 0 = x), Identity Property of Multiplication (x × 1 = x), Zero Property (x × 0 = 0), non-commutativity of subtraction/division.
• Simplifying Expressions: Distributing and combining like terms in multi-term expressions (e.g. 3(x + 2) + 4x = 7x + 6).
• Evaluating Expressions: Substituting single or two variables into algebraic expressions (e.g. If x = 4, evaluate 3x + 2 = 14; If a = 3 and b = 5, evaluate 2a + 3b = 21).
• Expression Challenge: Multi-step simplification and evaluation challenges.

STRICT NEGATIVE CONSTRAINTS (FORBIDDEN IN MODULE 2):
❌ DO NOT ask basic introductory definitions from Module 1 (e.g. "What is a variable?", "What is a constant?", "What is an equation vs expression?", "What is PEMDAS?").
❌ DO NOT ask questions about solving equations for x (e.g. 2x + 5 = 15, find x).
❌ KEEP ALL QUESTIONS strictly focused on expressions, like terms, distribution, properties, and substitution.

10-QUESTION PROGRESSION BREAKDOWN:
- Questions 1 to 3 (Difficulty: 1, Foundations): Identifying like vs unlike terms, basic 1-step combining of like terms (e.g. "Simplify: 5x + 3x"), Commutative Property.
- Questions 4 to 7 (Difficulty: 2, Procedural Operations): Distributive property expansion (e.g. "Expand: 3(x + 4)", "Expand: 2(x − 5)"), single-variable evaluation (e.g. "If x = 4, evaluate the expression: 3x + 2"), properties counterexamples (subtraction is not commutative).
- Questions 8 to 10 (Difficulty: 3, Multi-Step Mastery & Challenges): Multi-step simplifying with multiple terms (e.g. "Simplify the expression by combining like terms: 6k + 4 − 2k + 9"), distribute then combine (e.g. "Simplify completely: 3(x + 2) + 4x"), two-variable substitution (e.g. "If a = 3 and b = 5, evaluate the expression: 2a + 3b").

MATHEMATICAL RIGOR & EXPLANATION RULES:
1. Every calculation MUST be exact. Verify the math before outputting choices!
2. The correct answer MUST be present in the options list and match correctIndex.
3. NEVER include internal chain-of-thought, reasoning steps, or scratchpad text (e.g. "Wait correction", "None match", "Adjust options") in the explanation or question!
4. When a question asks to simplify, expand, or evaluate an equation/expression, format it with a colon before the math: e.g.
   "Simplify the expression by combining like terms: 6k + 4 − 2k + 9"
   "Expand: 3(x + 4)"
   "If x = 4, evaluate the expression: 3x + 2"
   "Simplify completely: 3(x + 2) + 4x"
5. Mix Question Types: "multipleChoice" (3 options) and "trueFalse" (2 options).
6. Zero-Emoji Rule: NEVER include hint emojis in question text or options.

Return ONLY a JSON object with this EXACT structure:
{
  "questions": [
    {
      "id": "m2_q1",
      "subLessonTitle": "Like and Unlike Terms",
      "question": "Which of the following pairs contains LIKE TERMS?",
      "type": "multipleChoice",
      "options": ["4x and 9x", "3x and 3y", "5x and 5x²"],
      "correctIndex": 0,
      "explanation": "Like terms share the exact same variable and exponent (x).",
      "difficulty": 1
    }
  ]
}
''';
  }

  String _buildModule3SystemPrompt() {
    return '''
You are Xy, the expert educational AI quiz master in Algebrix.
Create an engaging, 10-item progressive algebra quiz strictly based on Module 3 ("Solving Equations").

MODULE 3 SCOPE (ONLY USE THESE 7 LESSONS):
• Understanding Equations: What makes an equation, equality as a physical balance, definition of a solution (testing candidate values).
• Inverse Operations: Addition ↔ Subtraction, Multiplication ↔ Division, performing identical operations on BOTH sides to maintain balance.
• One-Step Equations: Solving addition, subtraction, multiplication, and division equations in one inverse step (e.g. x − 6 = 9 ⇒ x = 15; 5x = 30 ⇒ x = 6).
• Two-Step Equations: Reversing operations in backward order (undoing +/− before ×/÷, e.g. 3x + 4 = 19 ⇒ 3x = 15 ⇒ x = 5).
• Variables on Both Sides: Collecting variable terms on one side and constants on the other (e.g. 5x + 1 = 3x + 9 ⇒ 2x = 8 ⇒ x = 4).
• Equations with Parentheses: Distributive property with equations (e.g. 2(x + 3) = 16 ⇒ 2x + 6 = 16 ⇒ x = 5; 3(x + 1) + x = 15 ⇒ x = 3).
• Checking Solutions: Substituting answers back into the original equation to verify equality (e.g. For 4x − 5 = 19 with x = 6: 4(6) − 5 = 19 ✓).

STRICT NEGATIVE CONSTRAINTS (FORBIDDEN IN MODULE 3):
❌ DO NOT ask questions about Systems of Linear Equations (two variables x and y simultaneously, e.g. x + y = 7).
❌ DO NOT ask questions about Quadratic Equations (e.g. x² − 4 = 0 or quadratic formula).
❌ DO NOT ask questions about Inequalities (<, >, ≤, ≥).
❌ DO NOT ask questions about Fractional coefficients or complex rational expressions.

10-QUESTION PROGRESSION BREAKDOWN:
- Questions 1 to 3 (Difficulty: 1, Foundations): Identifying equations vs expressions, inverse operations pairs, basic one-step equations.
- Questions 4 to 7 (Difficulty: 2, Procedural Operations): One-step multiplication/division, two-step equations, variables on both sides, why both sides must be modified.
- Questions 8 to 10 (Difficulty: 3, Multi-Step Mastery): Distributive property equations with parentheses, multi-step combination equations, solution verification check.

MATHEMATICAL RIGOR & EXPLANATION RULES:
1. Every calculation MUST be exact. Verify the math before outputting choices!
2. The correct answer MUST be present in the options list and match correctIndex.
3. NEVER include internal chain-of-thought, reasoning steps, or scratchpad text in the explanation or question.
4. When asking to solve an equation, state the equation clearly: e.g. "Solve for x: 3x + 4 = 19".
5. Mix Question Types: "multipleChoice" (3 or 4 options) and "trueFalse" (2 options).
6. Zero-Emoji Rule: NEVER include hint emojis in question text or options.

Return ONLY a JSON object with this EXACT structure:
{
  "questions": [
    {
      "id": "m3_q1",
      "subLessonTitle": "Understanding Equations",
      "question": "Which of the following is an equation?",
      "type": "multipleChoice",
      "options": ["3x + 2", "4y − 7", "3x + 2 = 11"],
      "correctIndex": 2,
      "explanation": "An equation must contain an equals sign (=) stating two expressions have the same value.",
      "difficulty": 1
    }
  ]
}
''';
  }

  /// Generates a 10-item progressive module quiz strictly tailored to the specified module's scope.
  Future<ModuleQuiz> generateQuiz({
    required ModuleContent module,
  }) async {
    final systemPrompt = _buildSystemPrompt(module);
    final nonce = DateTime.now().microsecondsSinceEpoch;
    final userPrompt =
        'Generate a fresh, unique 10-question progressive quiz strictly for module ${module.id} (${module.title}). '
        'Randomization seed: $nonce. '
        'Ensure unique numerical values, diverse variable letters (e.g. k, m, p, w, n, a, b, c, x, y, z), '
        'and different problem setups so every generated quiz is brand new and engaging.';

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
        if (parsed.questions.length >= 8) return parsed;
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
        if (parsed.questions.length >= 8) return parsed;
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
        if (parsed.questions.length >= 8) return parsed;
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
              'temperature': 0.7,
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
            'temperature': 0.7,
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
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('NVIDIA status ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  String _sanitizeExplanation(String explanation) {
    var cleaned = explanation.trim();
    // Strip any leaked scratchpad / chain-of-thought tokens
    final stopMarkers = [
      'Wait correction',
      'None match',
      'Adjust options',
      'Scratchpad:',
      'Correction:',
      'wait correction',
    ];
    for (final marker in stopMarkers) {
      final idx = cleaned.toLowerCase().indexOf(marker.toLowerCase());
      if (idx != -1) {
        cleaned = cleaned.substring(0, idx).trim();
      }
    }
    if (cleaned.isEmpty) {
      return 'Apply algebraic rules step-by-step to arrive at the correct answer.';
    }
    return cleaned;
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

    // Sanitize question explanations
    final sanitized = parsed.questions.map((q) {
      return ModuleQuizQuestion(
        id: q.id,
        subLessonTitle: q.subLessonTitle,
        question: q.question,
        type: q.type,
        options: q.options,
        correctIndex: q.correctIndex,
        explanation: _sanitizeExplanation(q.explanation),
        difficulty: q.difficulty,
      );
    }).toList();

    // If AI generated fewer than 10 items, pad with seed bank items to guarantee 10
    if (sanitized.length < 10) {
      final seedQuiz = _generateSeedBankQuiz(module);
      final padded = List<ModuleQuizQuestion>.from(sanitized);
      for (final seedQ in seedQuiz.questions) {
        if (padded.length >= 10) break;
        if (!padded.any((q) => q.question == seedQ.question)) {
          padded.add(seedQ);
        }
      }
      return ModuleQuiz(
        moduleId: module.id,
        moduleTitle: module.title,
        questions: padded.take(10).toList(),
        generatedAt: DateTime.now(),
        providerUsed: provider,
      );
    }

    return ModuleQuiz(
      moduleId: module.id,
      moduleTitle: module.title,
      questions: sanitized.take(10).toList(),
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

  /// High-quality dynamic seed bank for Modules 1, 2, and 3 with 10 progressive items strictly within scope.
  ModuleQuiz _generateSeedBankQuiz(ModuleContent module) {
    final rng = Random();

    if (module.id == 'module3') {
      return _buildModule3SeedQuiz(rng);
    } else if (module.id == 'module2') {
      return _buildModule2SeedQuiz(rng);
    } else {
      return _buildModule1SeedQuiz(rng);
    }
  }

  ModuleQuiz _buildModule1SeedQuiz(Random rng) {
    final vars = ['x', 'y', 'n', 'a', 'b', 'k', 'm', 'w'];
    final v = vars[rng.nextInt(vars.length)];
    final a = rng.nextInt(5) + 3; // 3 to 7
    final b = rng.nextInt(7) + 2; // 2 to 8
    final c = rng.nextInt(6) + 2; // 2 to 7

    final questions = <ModuleQuizQuestion>[
      // Level 1: Foundations (Q1 to Q3)
      ModuleQuizQuestion(
        id: 'm1_q01',
        subLessonTitle: 'Variables',
        question: 'In the algebraic expression $a$v + $b, which part represents the variable?',
        type: QuizQuestionType.multipleChoice,
        options: ['$a', v, '$b'],
        correctIndex: 1,
        explanation: 'A variable is a letter or symbol that represents an unknown quantity ($v).',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm1_q02',
        subLessonTitle: 'Constants',
        question: 'In the expression ${a + 2}$v − $b, what is the constant term?',
        type: QuizQuestionType.multipleChoice,
        options: ['${a + 2}', v, '−$b'],
        correctIndex: 2,
        explanation: 'In ${a + 2}$v − $b, the minus sign belongs to the term that follows, making the constant −$b.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm1_q03',
        subLessonTitle: 'Coefficients',
        question: 'What is the coefficient of a standalone variable like "$v"?',
        type: QuizQuestionType.multipleChoice,
        options: ['0', '1', v],
        correctIndex: 1,
        explanation: 'A standalone variable always has an implicit (invisible) coefficient of 1 (1$v = $v).',
        difficulty: 1,
      ),

      // Level 2: Procedural Foundations (Q4 to Q7)
      ModuleQuizQuestion(
        id: 'm1_q04',
        subLessonTitle: 'Coefficients and Signs',
        question: 'What is the coefficient of the variable in the term: −$a$v',
        type: QuizQuestionType.multipleChoice,
        options: ['$a', '−$a', v],
        correctIndex: 1,
        explanation: 'The sign in front belongs to the coefficient, so the multiplier is −$a.',
        difficulty: 2,
      ),
      const ModuleQuizQuestion(
        id: 'm1_q05',
        subLessonTitle: 'Expressions vs Equations',
        question: 'True or False: The statement "5x + 3 = 18" is an algebraic expression.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 1,
        explanation: 'False! The presence of an equals sign (=) makes it an equation, not an expression.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm1_q06',
        subLessonTitle: 'Terms and Signs',
        question: 'How many terms are in the expression: ${a}x + $b − ${c}y + 2',
        type: QuizQuestionType.multipleChoice,
        options: ['2', '3', '4'],
        correctIndex: 2,
        explanation: 'Addition and subtraction separate the 4 distinct terms: ${a}x, +$b, −${c}y, and +2.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm1_q07',
        subLessonTitle: 'Order of Operations',
        question: 'Evaluate: $a + $b × $c',
        type: QuizQuestionType.multipleChoice,
        options: ['${(a + b) * c}', '${a + (b * c)}', '${(a * c) + b}'],
        correctIndex: 1,
        explanation: 'Multiply first: $b × $c = ${b * c}. Then add: $a + ${b * c} = ${a + (b * c)}.',
        difficulty: 2,
      ),

      // Level 3: Multi-Step Mastery (Q8 to Q10)
      ModuleQuizQuestion(
        id: 'm1_q08',
        subLessonTitle: 'Order of Operations with Parentheses',
        question: 'Evaluate: ($a + $b) × $c − 4',
        type: QuizQuestionType.multipleChoice,
        options: ['${(a + b) * c - 4}', '${(a + b) * c}', '${a + (b * c) - 4}'],
        correctIndex: 0,
        explanation: 'Parentheses first: $a + $b = ${a + b}. Multiply: ${a + b} × $c = ${(a + b) * c}. Finally subtract 4: ${(a + b) * c - 4}.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm1_q09',
        subLessonTitle: 'Advanced Order of Operations',
        question: 'Evaluate: 18 − 3 × (2 + 4) ÷ 2',
        type: QuizQuestionType.multipleChoice,
        options: ['9', '45', '15'],
        correctIndex: 0,
        explanation: 'Parentheses: 2 + 4 = 6. Multiply: 3 × 6 = 18. Divide: 18 ÷ 2 = 9. Subtract: 18 − 9 = 9.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm1_q10',
        subLessonTitle: 'Order of Operations Equal Rank',
        question: 'True or False: Multiplication and Division have equal rank and are solved left to right.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 0,
        explanation: 'True! Multiplication and division share equal priority, so you work from left to right.',
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
    final vars = ['x', 'y', 'k', 'm', 'p', 'w', 'a', 'b'];
    final v = vars[rng.nextInt(vars.length)];
    final c1 = rng.nextInt(5) + 3; // 3 to 7
    final c2 = rng.nextInt(5) + 2; // 2 to 6
    final val = rng.nextInt(4) + 2; // 2 to 5
    final factor = rng.nextInt(3) + 2; // 2 to 4
    final insideConst = rng.nextInt(4) + 2; // 2 to 5

    final questions = <ModuleQuizQuestion>[
      // Level 1: Foundations (Q1 to Q3)
      ModuleQuizQuestion(
        id: 'm2_q01',
        subLessonTitle: 'Like and Unlike Terms',
        question: 'Which of the following pairs contains LIKE TERMS?',
        type: QuizQuestionType.multipleChoice,
        options: ['${c1}$v and ${c1 + 5}$v', '${c1}$v and ${c1}z', '${c1}$v and ${c1}$v²'],
        correctIndex: 0,
        explanation: 'Like terms must have the exact same variable raised to the exact same exponent ($v).',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm2_q02',
        subLessonTitle: 'Combining Like Terms',
        question: 'Simplify: ${c1}$v + ${c2}$v',
        type: QuizQuestionType.multipleChoice,
        options: ['${c1 + c2}$v', '${c1 + c2}$v²', '${c1 * c2}$v'],
        correctIndex: 0,
        explanation: 'Add the coefficients ($c1 + $c2 = ${c1 + c2}) and keep the variable part identical (${c1 + c2}$v).',
        difficulty: 1,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q03',
        subLessonTitle: 'Properties of Operations',
        question: 'Which property is demonstrated by: a + b = b + a',
        type: QuizQuestionType.multipleChoice,
        options: ['Commutative Property', 'Associative Property', 'Distributive Property'],
        correctIndex: 0,
        explanation: 'The Commutative Property allows changing the order of numbers in addition.',
        difficulty: 1,
      ),

      // Level 2: Procedural Operations (Q4 to Q7)
      ModuleQuizQuestion(
        id: 'm2_q04',
        subLessonTitle: 'Distributive Property',
        question: 'Expand: $factor($v + $insideConst)',
        type: QuizQuestionType.multipleChoice,
        options: ['$factor$v + ${factor * insideConst}', '$factor$v + $insideConst', '${factor + insideConst}$v'],
        correctIndex: 0,
        explanation: 'Multiply the outside factor by each inside term: $factor($v) + $factor($insideConst) = $factor$v + ${factor * insideConst}.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm2_q05',
        subLessonTitle: 'Distributive Property with Subtraction',
        question: 'Expand: $factor($v − $insideConst)',
        type: QuizQuestionType.multipleChoice,
        options: ['$factor$v − ${factor * insideConst}', '$factor$v − $insideConst', '$factor$v + ${factor * insideConst}'],
        correctIndex: 0,
        explanation: 'Distribute $factor to both terms: $factor($v) + $factor(−$insideConst) = $factor$v − ${factor * insideConst}.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm2_q06',
        subLessonTitle: 'Evaluating Expressions',
        question: 'If $v = $val, evaluate the expression: ${c1}$v + $c2',
        type: QuizQuestionType.multipleChoice,
        options: ['${(c1 * val) + c2}', '${(c1 * val) + c2 + 4}', '${c1 * (val + c2)}'],
        correctIndex: 0,
        explanation: 'Substitute $val for $v: $c1($val) + $c2 = ${c1 * val} + $c2 = ${(c1 * val) + c2}.',
        difficulty: 2,
      ),
      const ModuleQuizQuestion(
        id: 'm2_q07',
        subLessonTitle: 'Properties of Operations',
        question: 'True or False: Subtraction and Division are commutative operations.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 1,
        explanation: 'False! Changing order changes the result: 10 − 4 ≠ 4 − 10, and 10 ÷ 2 ≠ 2 ÷ 10.',
        difficulty: 2,
      ),

      // Level 3: Multi-Step Mastery (Q8 to Q10)
      ModuleQuizQuestion(
        id: 'm2_q08',
        subLessonTitle: 'Simplifying Expressions',
        question: 'Simplify the expression by combining like terms: ${c1 + 3}$v + $c2 − ${c1}$v + ${c2 + 5}',
        type: QuizQuestionType.multipleChoice,
        options: ['3$v + ${2 * c2 + 5}', '${2 * c1 + 3}$v + ${2 * c2 + 5}', '3$v + 5'],
        correctIndex: 0,
        explanation: 'Group like terms: (${c1 + 3}$v − ${c1}$v) + ($c2 + ${c2 + 5}) = 3$v + ${2 * c2 + 5}.',
        difficulty: 3,
      ),
      ModuleQuizQuestion(
        id: 'm2_q09',
        subLessonTitle: 'Distribute & Combine',
        question: 'Simplify completely: $factor($v + 2) + ${c2}$v',
        type: QuizQuestionType.multipleChoice,
        options: ['${factor + c2}$v + ${factor * 2}', '${factor + c2}$v + 2', '$factor$v + ${factor * 2}'],
        correctIndex: 0,
        explanation: 'Distribute first: $factor$v + ${factor * 2} + ${c2}$v. Combine like terms: ($factor$v + ${c2}$v) + ${factor * 2} = ${factor + c2}$v + ${factor * 2}.',
        difficulty: 3,
      ),
      ModuleQuizQuestion(
        id: 'm2_q10',
        subLessonTitle: 'Multi-Variable Substitution',
        question: 'If a = $val and b = $insideConst, evaluate the expression: 2a + 3b',
        type: QuizQuestionType.multipleChoice,
        options: ['${2 * val + 3 * insideConst}', '${2 * val + insideConst}', '${val + 3 * insideConst}'],
        correctIndex: 0,
        explanation: 'Substitute: 2($val) + 3($insideConst) = ${2 * val} + ${3 * insideConst} = ${2 * val + 3 * insideConst}.',
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

  ModuleQuiz _buildModule3SeedQuiz(Random rng) {
    final vars = ['x', 'y', 'k', 'm', 'w', 'p', 'a', 'n'];
    final v = vars[rng.nextInt(vars.length)];
    final multCoeff = rng.nextInt(5) + 3; // 3 to 7
    final targetX = rng.nextInt(6) + 2; // 2 to 7
    final multTotal = multCoeff * targetX;
    final addConst = rng.nextInt(8) + 3; // 3 to 10
    final subConst = rng.nextInt(7) + 2; // 2 to 8
    final twoStepAns = rng.nextInt(5) + 2; // 2 to 6
    final twoStepA = rng.nextInt(3) + 2; // 2 to 4
    final twoStepB = rng.nextInt(5) + 2; // 2 to 6
    final twoStepTotal = twoStepA * twoStepAns + twoStepB;

    final questions = <ModuleQuizQuestion>[
      // Level 1: Foundations (Q1 to Q3)
      ModuleQuizQuestion(
        id: 'm3_q01',
        subLessonTitle: 'Understanding Equations',
        question: 'Which of the following is an EQUATION?',
        type: QuizQuestionType.multipleChoice,
        options: ['3$v + 2', '4y − 7', '3$v + 2 = 11', '5$v'],
        correctIndex: 2,
        explanation:
            'An equation must contain an equals sign (=) stating that two expressions have equal value.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm3_q02',
        subLessonTitle: 'Inverse Operations',
        question: 'What operation undoes: $v + $addConst',
        type: QuizQuestionType.multipleChoice,
        options: ['+$addConst', '−$addConst', '×$addConst', '÷$addConst'],
        correctIndex: 1,
        explanation:
            'Subtraction is the inverse operation of addition (+$addConst − $addConst = 0).',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm3_q03',
        subLessonTitle: 'One-Step Equations',
        question: 'Solve for $v: $v − $subConst = $addConst',
        type: QuizQuestionType.multipleChoice,
        options: [
          '$v = ${addConst - subConst}',
          '$v = ${addConst + subConst}',
          '$v = ${addConst * subConst}',
          '$v = ${-addConst}',
        ],
        correctIndex: 1,
        explanation: 'Add $subConst to both sides: $v = $addConst + $subConst = ${addConst + subConst}.',
        difficulty: 1,
      ),

      // Level 2: Procedural Operations (Q4 to Q7)
      ModuleQuizQuestion(
        id: 'm3_q04',
        subLessonTitle: 'Multiplication Equations',
        question: 'Solve for $v: ${multCoeff}$v = $multTotal',
        type: QuizQuestionType.multipleChoice,
        options: [
          '$v = ${multTotal - multCoeff}',
          '$v = $targetX',
          '$v = ${multTotal * multCoeff}',
          '$v = ${targetX + 2}',
        ],
        correctIndex: 1,
        explanation: 'Divide both sides by $multCoeff: $multTotal ÷ $multCoeff = $targetX.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm3_q05',
        subLessonTitle: 'Two-Step Equations',
        question: 'Solve for $v: ${twoStepA}$v + $twoStepB = $twoStepTotal',
        type: QuizQuestionType.multipleChoice,
        options: [
          '$v = $twoStepAns',
          '$v = ${twoStepAns + 2}',
          '$v = ${twoStepAns + 3}',
          '$v = ${twoStepTotal + twoStepB}',
        ],
        correctIndex: 0,
        explanation: 'Subtract $twoStepB (${twoStepA}$v = ${twoStepTotal - twoStepB}), then divide by $twoStepA: $v = $twoStepAns.',
        difficulty: 2,
      ),
      const ModuleQuizQuestion(
        id: 'm3_q06',
        subLessonTitle: 'Preserving Equality',
        question:
            'True or False: Performing an operation on only one side of an equation preserves its equality.',
        type: QuizQuestionType.trueFalse,
        options: ['True', 'False'],
        correctIndex: 1,
        explanation:
            'False! You must perform the exact same operation on BOTH sides to keep the equation balanced.',
        difficulty: 2,
      ),
      const ModuleQuizQuestion(
        id: 'm3_q07',
        subLessonTitle: 'Variables on Both Sides',
        question: 'Solve for x: 5x + 1 = 3x + 9',
        type: QuizQuestionType.multipleChoice,
        options: ['x = 2', 'x = 4', 'x = 5', 'x = 8'],
        correctIndex: 1,
        explanation:
            'Subtract 3x (2x + 1 = 9), subtract 1 (2x = 8), divide by 2: x = 4.',
        difficulty: 2,
      ),

      // Level 3: Multi-Step Mastery (Q8 to Q10)
      const ModuleQuizQuestion(
        id: 'm3_q08',
        subLessonTitle: 'Equations with Parentheses',
        question: 'Solve for x: 2(x + 3) = 16',
        type: QuizQuestionType.multipleChoice,
        options: ['x = 5', 'x = 6.5', 'x = 8', 'x = 10'],
        correctIndex: 0,
        explanation:
            'Distribute 2 (2x + 6 = 16), subtract 6 (2x = 10), divide by 2: x = 5.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm3_q09',
        subLessonTitle: 'Mixed Multi-Step Equation',
        question: 'Solve for x: 3(x + 1) + x = 15',
        type: QuizQuestionType.multipleChoice,
        options: ['x = 2', 'x = 3', 'x = 4', 'x = 5'],
        correctIndex: 1,
        explanation:
            'Distribute: 3x + 3 + x = 15 ⇒ 4x + 3 = 15 ⇒ 4x = 12 ⇒ x = 3.',
        difficulty: 3,
      ),
      const ModuleQuizQuestion(
        id: 'm3_q10',
        subLessonTitle: 'Checking Solutions',
        question:
            'You solved 4x − 5 = 19 and got x = 6. Which substitution proves the solution is correct?',
        type: QuizQuestionType.multipleChoice,
        options: [
          '4 + 6 − 5 = 19',
          '4(6) − 5 = 19',
          '4(19) − 5 = 6',
          '6 − 5 = 19',
        ],
        correctIndex: 1,
        explanation:
            'Substitute 6 into 4x − 5: 4(6) − 5 = 24 − 5 = 19, which matches the right side (19 = 19 ✓).',
        difficulty: 3,
      ),
    ];

    return ModuleQuiz(
      moduleId: 'module3',
      moduleTitle: 'Solving Equations',
      questions: questions,
      generatedAt: DateTime.now(),
      providerUsed: 'Algebrix Curated Seed Bank',
    );
  }
}
