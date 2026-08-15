import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Structured AI feedback result generated for Xy mascot.
class AiFeedbackResult {
  final String title;
  final String message;
  final List<String> steps;
  final String? whyItWorks;
  final String? keyConcept;
  final String? promptForStudent;
  final List<String> suggestions;
  final bool isCorrect;
  final String providerUsed;

  const AiFeedbackResult({
    required this.title,
    required this.message,
    this.steps = const [],
    this.whyItWorks,
    this.keyConcept,
    this.promptForStudent,
    this.suggestions = const [],
    this.isCorrect = true,
    required this.providerUsed,
  });

  factory AiFeedbackResult.fromJson(Map<String, dynamic> json, String provider) {
    return AiFeedbackResult(
      title: json['title'] as String? ?? '🐙 Xy Insights',
      message: json['message'] as String? ?? 'Great effort in reviewing this problem!',
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
      isCorrect: json['isCorrect'] as bool? ?? true,
      providerUsed: provider,
    );
  }
}

/// Service powering AI-Assisted Study Notes using Groq & NVIDIA APIs.
class AiTutorService {
  final http.Client _client;

  AiTutorService({http.Client? client}) : _client = client ?? http.Client();

  String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  String get _nvidiaApiKey => dotenv.env['NVIDIA_API_KEY'] ?? '';

  /// 📖 Worked Example: Analyzes student solution steps for inverse operations & correctness.
  Future<AiFeedbackResult> checkWorkedExample({
    required String problem,
    required String solution,
  }) async {
    final systemPrompt = '''
You are Xy, the friendly octopus algebra tutor in Algebrix.
A student solved a math problem. Verify their work.
Rule: Be concise. Do NOT include emoji in "title". Wrap ALL math numbers, variables, and expressions in **bold** (e.g. **2x + 5 = 15**, **+5**, **x = 5**).
Provide clear step-by-step bullet points in "steps" (do NOT prefix with "Step 1", just the action).
Return JSON ONLY with exact keys:
{
  "isCorrect": boolean,
  "title": "Looks good!" or "Let's check step by step!",
  "message": "1 short sentence overview",
  "steps": ["Subtract **5** from both sides (**2x = 10**)", "Divide both sides by **2** (**x = 5**)"],
  "whyItWorks": "Inverse operations keep the scale balanced",
  "keyConcept": "The main takeaway rule"
}
''';

    final userPrompt = 'Problem: $problem\nStudent Solution:\n$solution';
    return _callAiWithFallback(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }

  /// 🐛 Mistake Reflection: Identifies misconceptions without giving away answers.
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
You are Xy, the algebra tutor in Algebrix.
The student tried to explain a concept ($topic) in their own words.
Rule: Do NOT include emoji in "title". Evaluate if they grasped the core intuition.
Return JSON ONLY with exact keys:
{
  "isCorrect": boolean,
  "title": "You're on the right track!" or "Almost there!",
  "message": "Friendly constructive feedback on their explanation",
  "keyConcept": "Core rule or intuition"
}
''';

    final userPrompt = 'Topic: $topic\nStudent Explanation: $studentExplanation';
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
    if (lower.length < 10) return false;

    // Explicit off-topic keywords (food, recipes, games, pop culture)
    final offTopicKeywords = [
      'lumpia', 'ice cream', 'recipe', 'pizza', 'burger', 'milk', 'sugar',
      'cook', 'bake', 'ingredient', 'food', 'playstation', 'xbox', 'nintendo',
      'fifa', 'fortnite', 'minecraft', 'movie', 'song', 'music',
      'restaurant', 'hotel', 'car', 'dog', 'cat', 'sleep', 'party',
    ];

    final hasOffTopicKeyword = offTopicKeywords.any((kw) => lower.contains(kw));

    // Math symbols check (=, +, -, *, /, ^, <, >)
    final hasMathSymbols = RegExp(r'[=\+\-\*\/\^<>]').hasMatch(lower);

    // Specific math vocabulary terms
    final mathTerms = [
      'equation', 'variable', 'algebra', 'constant', 'coefficient',
      'term', 'expression', 'subtract', 'divide', 'multiply',
      'linear', 'quadratic', 'slope', 'intercept', 'factor',
      'fraction', 'decimal', 'exponent', 'formula', 'ratio',
      'polynomial', 'binomial', 'trinomial', 'inequality', 'solving',
      'isolate', 'inverse', 'operation',
    ];

    final hasMathTerm = mathTerms.any((term) => lower.contains(term));

    // If it contains explicit off-topic keywords without math terms, it's OFF TOPIC
    if (hasOffTopicKeyword && !hasMathTerm) return true;

    // If it has no math symbols and no math terms, it's OFF TOPIC
    if (!hasMathSymbols && !hasMathTerm) return true;

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
      final json = jsonDecode(_extractJson(text)) as Map<String, dynamic>;
      return AiFeedbackResult.fromJson(json, 'Groq (Llama 3.3 70B)');
    } catch (groqError) {
      debugPrint('Groq API error: $groqError. Falling back to NVIDIA NIM...');
      try {
        final text = await _callNvidia(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          isJsonMode: true,
        );
        final json = jsonDecode(_extractJson(text)) as Map<String, dynamic>;
        return AiFeedbackResult.fromJson(json, 'NVIDIA NIM');
      } catch (nvidiaError) {
        debugPrint('NVIDIA API error: $nvidiaError. Using offline fallback.');
        return const AiFeedbackResult(
          title: 'Xy\'s Learning Nudge',
          message:
              'Keep both sides of your equation balanced like a scale! Whatever operation you perform on the left, apply equally to the right.',
          whyItWorks: 'The Property of Equality maintains balance.',
          keyConcept: 'Inverse operations isolate variables step-by-step.',
          providerUsed: 'Offline Knowledge',
        );
      }
    }
  }

  Future<String> _callGroq({
    required String systemPrompt,
    required String userPrompt,
    bool isJsonMode = true,
  }) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final response = await _client.post(
      url,
      headers: {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.3,
        if (isJsonMode) 'response_format': {'type': 'json_object'},
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Groq status ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  Future<String> _callNvidia({
    required String systemPrompt,
    required String userPrompt,
    bool isJsonMode = true,
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
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('NVIDIA status ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
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
}
