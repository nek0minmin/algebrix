import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Data model representing structured educational feedback from Xy AI tutor.
class AiFeedbackResult {
  final String title;
  final String message;
  final List<String> steps;
  final String? whyItWorks;
  final String? keyConcept;
  final String? promptForStudent;
  final List<String> suggestions;
  final String providerUsed;
  final bool isCorrect;

  const AiFeedbackResult({
    required this.title,
    required this.message,
    this.steps = const [],
    this.whyItWorks,
    this.keyConcept,
    this.promptForStudent,
    this.suggestions = const [],
    required this.providerUsed,
    this.isCorrect = true,
  });

  factory AiFeedbackResult.fromJson(
    Map<String, dynamic> json, {
    required String provider,
  }) {
    return AiFeedbackResult(
      title: json['title'] as String? ?? 'Learning Insight',
      message: json['message'] as String? ?? 'Keep exploring and practicing math!',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      whyItWorks: json['whyItWorks'] as String?,
      keyConcept: json['keyConcept'] as String?,
      promptForStudent: json['promptForStudent'] as String?,
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      providerUsed: provider,
      isCorrect: json['isCorrect'] as bool? ?? true,
    );
  }
}

/// Service handling intelligent LLM tutoring with Groq -> NVIDIA NIM multi-tier fallback.
class AiTutorService {
  final http.Client _client;

  AiTutorService({http.Client? client}) : _client = client ?? http.Client();

  String get _groqApiKey {
    try {
      return dotenv.isInitialized ? (dotenv.env['GROQ_API_KEY'] ?? '') : '';
    } catch (_) {
      return '';
    }
  }

  String get _nvidiaApiKey {
    try {
      return dotenv.isInitialized
          ? (dotenv.env['NVIDIA_NIM_API_KEY'] ??
              dotenv.env['NVIDIA_API_KEY'] ??
              '')
          : '';
    } catch (_) {
      return '';
    }
  }

  /// 📝 Worked Example Verification: Validates student's self-written step-by-step solutions.
  Future<AiFeedbackResult> checkWorkedExample({
    required String problem,
    required String solution,
  }) async {
    final systemPrompt = '''
You are Xy, the supportive octopus tutor in Algebrix.
The student submitted a worked example for an algebra problem: $problem.

CRITICAL TOPIC RELEVANCE RULES:
1. Algebrix is strictly an ALGEBRA learning app.
2. If the submission is off-topic (e.g. food recipes, personal preferences like "I like watermelons", gaming, non-math text), you MUST return:
{
  "isCorrect": false,
  "title": "Let's focus on Algebra!",
  "message": "Xy is your dedicated algebra tutor! Please share an algebra equation or worked step to get insights.",
  "keyConcept": "Algebrix Topic Boundary"
}
3. For algebra worked examples, verify the mathematical steps. Wrap ALL numbers, variables, and math operations in **bold** (e.g. **+4**, **3x**, **16**, **x = 4**).
4. Do NOT include emoji in "title". Provide 2-3 clear step-by-step bullet points in "steps" (do NOT prefix with "Step 1", just the action).

Return JSON ONLY with exact keys:
{
  "isCorrect": boolean,
  "title": "Looks good!" or "Let's check step by step!" or "Let's focus on Algebra!",
  "message": "Friendly summary feedback",
  "steps": ["Step 1 description", "Step 2 description"],
  "whyItWorks": "Mathematical intuition or rule (e.g. Inverse operations isolate the variable)",
  "keyConcept": "Concept name (e.g. Subtraction Property of Equality)"
}
''';

    final userPrompt = 'Algebra Problem: $problem\nStudent Solution Steps: $solution';
    return _callAiWithFallback(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }

  /// 🔍 Mistake Diagnosis: Pinpoints mathematical misconceptions constructively.
  Future<AiFeedbackResult> diagnoseMistake({
    required String problem,
    required String incorrectAnswer,
  }) async {
    final systemPrompt = '''
You are Xy, the supportive octopus tutor in Algebrix.
The student made a mistake in solving an equation.
Rule: Do NOT include emoji in "title". Do NOT dump long paragraphs. Wrap ALL numbers, variables, and math operations in **bold** (e.g. **+4**, **3x**, **16**, **3**).
Provide 2-3 clear step-by-step bullet points in "steps" (do NOT prefix with "Step 1", just the action).
Return JSON ONLY with exact keys:
{
  "isCorrect": false,
  "title": "Let's check step by step!",
  "message": "You tried to divide by **3** first, but **+4** is still attached to **3x**.",
  "steps": ["Undo **+4** first: **3x + 4 - 4 = 16 - 4** → **3x = 12**", "Divide both sides by **3**: **x = 4**"],
  "whyItWorks": "Undo operations from the outside in (PEMDAS in reverse)",
  "promptForStudent": "💡 What did you learn from this step?"
}
''';

    final userPrompt = 'Problem: $problem\nStudent Answer/Step: $incorrectAnswer';
    return _callAiWithFallback(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }

  /// ❓ Socratic Question Hint: Provides scale balance analogies and interactive chips.
  Future<AiFeedbackResult> getSocraticHint({
    required String question,
    String hintType = 'hint',
  }) async {
    final systemPrompt = '''
You are Xy, the friendly octopus algebra tutor in Algebrix.
The student asked a conceptual question about algebra.
Type of guidance requested: $hintType.
Rule: Use the balance scale analogy. Do NOT include emoji in "title". Keep it conversational.
Return JSON ONLY with exact keys:
{
  "title": "Think about it like a balance scale!",
  "message": "Socratic explanation or hint using a balance scale analogy",
  "keyConcept": "Property of Equality concept",
  "suggestions": ["💡 Give me a hint", "📖 Explain it", "⚖️ Show visually", "🧩 Give an example"]
}
''';

    return _callAiWithFallback(
      systemPrompt: systemPrompt,
      userPrompt: 'Student Question: $question',
    );
  }

  /// 💡 Explain Why: Evaluates student's own explanation in their own words.
  Future<AiFeedbackResult> evaluateExplanation({
    required String topic,
    required String studentExplanation,
  }) async {
    final systemPrompt = '''
You are Xy, the expert algebra tutor in Algebrix.
The student is writing a study note explaining an ALGEBRA concept ($topic).

CRITICAL TOPIC RELEVANCE RULES:
1. Algebrix is strictly an ALGEBRA learning app.
2. If the student's text is off-topic (e.g. personal preferences like "I like watermelons and strawberries" or "I hate watermelons", food, games, everyday dictionary meanings of words like "like"), you MUST return:
{
  "isCorrect": false,
  "title": "Let's focus on Algebra!",
  "message": "Xy is your dedicated algebra tutor! This note doesn't seem to be about algebra or mathematics. Try writing about algebra concepts like **like terms**, **variables**, **equations**, or **inverse operations**!",
  "keyConcept": "Algebrix Topic Boundary"
}
3. If the student is explaining an ALGEBRA concept (e.g. like terms, variables, equations, constants, PEMDAS, properties of operations, distributive property), evaluate whether they grasped the mathematical intuition and return constructive feedback.
4. Wrap all numbers, variables, and mathematical terms in **bold**.
5. Do NOT include emoji in "title".

Return JSON ONLY with exact keys:
{
  "isCorrect": boolean,
  "title": "You're on the right track!" or "Almost there!" or "Let's focus on Algebra!",
  "message": "Friendly constructive feedback on their algebra explanation",
  "keyConcept": "Core algebraic rule or intuition"
}
''';

    final userPrompt = 'Algebra Topic: $topic\nStudent Note/Explanation: $studentExplanation';
    return _callAiWithFallback(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }

  /// ✨ Improve My Understanding: Refines a messy note into clean first-person study note.
  Future<String> improveUnderstanding({required String rawNote}) async {
    final systemPrompt = '''
You are Xy, an educational algebra assistant in Algebrix.
The student wrote a rough study note. Transform it into a clean, beautifully formatted study note.

CRITICAL RULES:
1. Write ONLY in FIRST PERSON ("What I learned:", "My steps:"). NEVER talk about "the student" in 3rd person!
2. Wrap key math numbers, variables, and expressions in **bold** (e.g. **2x + 5 = 15**, **x = 5**).
3. Do NOT wrap output in markdown codeblocks (no ```markdown).
4. Format clearly with bullet points.
''';

    try {
      final response = await _callGroq(
        systemPrompt: systemPrompt,
        userPrompt: rawNote,
        isJsonMode: false,
      );
      return _cleanMarkdownResponse(response);
    } catch (_) {
      try {
        final response = await _callNvidia(
          systemPrompt: systemPrompt,
          userPrompt: rawNote,
          isJsonMode: false,
        );
        return _cleanMarkdownResponse(response);
      } catch (e) {
        return 'What I Learned:\n• To solve equations, I isolate the variable step-by-step using inverse operations.\n• Whatever I do to one side of the balance scale, I apply to the other side.';
      }
    }
  }

  String _cleanMarkdownResponse(String raw) {
    var text = raw.trim();
    if (text.startsWith('```markdown')) {
      text = text.substring(11);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  bool isOffTopicText(String userPrompt) {
    final lower = userPrompt.toLowerCase().trim();
    if (lower.length < 5) return false;

    // Explicit non-educational / non-math keywords (food recipes, fruits, dining, entertainment)
    final offTopicKeywords = [
      'lumpia', 'ice cream', 'recipe', 'pizza', 'burger', 'milk', 'sugar',
      'cook', 'bake', 'baking', 'ingredient', 'ingredients', 'watermelon', 'watermelons',
      'strawberry', 'strawberries', 'fruit', 'fruits', 'apple', 'apples', 'banana',
      'bananas', 'mango', 'mangoes', 'delicious', 'tasty', 'snack', 'food', 'meat',
      'pork', 'chicken', 'beef', 'dinner', 'lunch', 'breakfast', 'playstation', 'xbox',
      'nintendo', 'fifa', 'fortnite', 'minecraft', 'roblox', 'tiktok', 'movie', 'song',
      'music', 'restaurant', 'hotel', 'anime', 'party', 'girlfriend', 'boyfriend',
    ];

    final hasOffTopicKeyword = offTopicKeywords.any((kw) => lower.contains(kw));

    // True mathematical operators and structural syntax (=, +, -, *, /, ^, <, >, (, ), [, ], {, }, ×, ÷, ±, √, π, %, or explicit numbers in expressions)
    final hasMathSymbols = RegExp(r'[=\+\-\*\/\^<>×÷±√π%]').hasMatch(lower) ||
        RegExp(r'\d+\s*[a-z]|[a-z]\s*[=\+\-\*\/]\s*\d+|\d+\s*[=\+\-\*\/]\s*\d+').hasMatch(lower);

    // Unambiguous, domain-specific algebra multi-word phrases and technical terminology
    final unambiguousMathTerms = [
      'like terms', 'unlike terms', 'combining like terms', 'combine like terms',
      'distributive property', 'order of operations', 'pemdas', 'inverse operation',
      'inverse operations', 'isolate the variable', 'isolate x', 'isolate y',
      'algebra', 'algebraic', 'coefficient', 'polynomial', 'binomial', 'trinomial',
      'monomial', 'quadratic', 'linear equation', 'system of equations',
      'constant term', 'solve for x', 'solve for y', 'balance scale',
      'commutative property', 'associative property', 'identity property',
      'properties of operations', 'variable', 'variables', 'equation', 'equations',
      'expression', 'expressions', 'inequality', 'inequalities', 'substitution',
    ];

    final hasUnambiguousMath = unambiguousMathTerms.any((term) => lower.contains(term));

    // If it contains explicit off-topic terms and lacks unambiguous math terms or symbols:
    if (hasOffTopicKeyword && !hasUnambiguousMath && !hasMathSymbols) {
      return true;
    }

    // Check if the prompt has ANY math terms or math symbols
    if (hasUnambiguousMath || hasMathSymbols) {
      return false;
    }

    // Single contextual math words (matched with word boundaries to avoid false substring triggers)
    final singleMathWords = [
      'math', 'algebra', 'equation', 'expression', 'variable', 'coefficient',
      'constant', 'term', 'terms', 'exponent', 'fraction', 'decimal', 'isolate',
      'substitute', 'simplify', 'evaluate', 'distribute', 'pemdas', 'solve',
    ];
    final hasSingleMathWord = singleMathWords.any((w) => RegExp(r'\b' + w + r'\b').hasMatch(lower));

    if (hasSingleMathWord) {
      return false;
    }

    // If it has off-topic keywords, flag it
    if (hasOffTopicKeyword) return true;

    return false;
  }

  /// Core HTTP executor with Groq -> NVIDIA fallback.
  Future<AiFeedbackResult> _callAiWithFallback({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (isOffTopicText(userPrompt)) {
      return const AiFeedbackResult(
        title: 'Let\'s focus on Algebra!',
        message: 'Xy is your dedicated algebra tutor! This note doesn\'t seem to be about math or equations.',
        steps: ['Try writing about an algebra concept like **variables**, **equations**, or **solving for x**!'],
        whyItWorks: 'Xy provides step-by-step insights when you share math concepts or worked examples.',
        keyConcept: 'Algebrix Topic Boundary',
        providerUsed: 'Algebrix Topic Guard',
        isCorrect: false,
      );
    }

    try {
      final text = await _callGroq(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        isJsonMode: true,
      );
      final json = _extractAndDecodeJson(text);
      return AiFeedbackResult.fromJson(json, provider: 'Groq (Llama 3.3 70B)');
    } catch (e) {
      debugPrint('Groq API error: $e. Falling back to NVIDIA NIM...');
      try {
        final text = await _callNvidia(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          isJsonMode: true,
        );
        final json = _extractAndDecodeJson(text);
        return AiFeedbackResult.fromJson(json, provider: 'NVIDIA NIM');
      } catch (e2) {
        debugPrint('NVIDIA API error: $e2. Using offline fallback.');
        return _getOfflineFallback(userPrompt);
      }
    }
  }

  Future<String> _callGroq({
    required String systemPrompt,
    required String userPrompt,
    required bool isJsonMode,
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
        final bodyMap = <String, dynamic>{
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.3,
        };

        if (isJsonMode) {
          bodyMap['response_format'] = {'type': 'json_object'};
        }

        final response = await _client.post(
          url,
          headers: {
            'Authorization': 'Bearer $_groqApiKey',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode(bodyMap),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          return decoded['choices'][0]['message']['content'] as String;
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
    required bool isJsonMode,
  }) async {
    final url = Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions');
    final bodyMap = <String, dynamic>{
      'model': 'meta/llama-3.3-70b-instruct',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.3,
    };

    if (isJsonMode) {
      bodyMap['response_format'] = {'type': 'json_object'};
    }

    final response = await _client.post(
      url,
      headers: {
        'Authorization': 'Bearer $_nvidiaApiKey',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(bodyMap),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('NVIDIA status ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return decoded['choices'][0]['message']['content'] as String;
  }

  Map<String, dynamic> _extractAndDecodeJson(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  AiFeedbackResult _getOfflineFallback(String userPrompt) {
    final lower = userPrompt.toLowerCase();

    if (lower.contains('+') || lower.contains('-') || lower.contains('=')) {
      return const AiFeedbackResult(
        title: 'Step Check Insight',
        message: 'Remember that inverse operations keep both sides equal.',
        steps: [
          'Undo addition or subtraction first to isolate variable terms.',
          'Undo multiplication or division to solve for the unknown variable.',
        ],
        whyItWorks: 'Maintaining equality on both sides preserves the balance.',
        keyConcept: 'Properties of Equality',
        providerUsed: 'Offline Knowledge',
        isCorrect: true,
      );
    }

    return const AiFeedbackResult(
      title: 'Learning Nudge',
      message: 'Great note! Review the lesson rules and practice with similar equations.',
      whyItWorks: 'Writing explanations in your own words builds lasting memory.',
      keyConcept: 'Algebra Foundations',
      providerUsed: 'Offline Knowledge',
      isCorrect: true,
    );
  }
}
