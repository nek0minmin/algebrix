import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Structured AI feedback result generated for Xy mascot.
class AiFeedbackResult {
  final String title;
  final String message;
  final String? whyItWorks;
  final String? keyConcept;
  final String? promptForStudent;
  final List<String> suggestions;
  final bool isCorrect;
  final String providerUsed;

  const AiFeedbackResult({
    required this.title,
    required this.message,
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
Rule: Be encouraging. Identify inverse operations used.
Return JSON ONLY with exact keys:
{
  "isCorrect": boolean,
  "title": "🐙 Looks good!" or "🐙 Let's check step by step!",
  "message": "Friendly explanation of what they did right or where they tripped",
  "whyItWorks": "Why the balance scale property / inverse operation works",
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
Rule: Do NOT just give the answer. Pinpoint the misconception (e.g. dividing before undoing addition).
Guide them to see what to undo first, then prompt them to reflect.
Return JSON ONLY with exact keys:
{
  "isCorrect": false,
  "title": "🐙 Let's look at what happened!",
  "message": "Clear explanation of the order of operations / balance rule they missed",
  "keyConcept": "We undo operations from the outside in (PEMDAS in reverse)",
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
The student asked a conceptual question about algebra (e.g., "Why subtract 5 from both sides?").
Type of guidance requested: $hintType.
Rule: Use the balance scale analogy. Never give a dry textbook dump. Keep it conversational.
Return JSON ONLY with exact keys:
{
  "title": "🐙 Think about it like a balance scale!",
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
Evaluate if they grasped the core intuition.
Return JSON ONLY with exact keys:
{
  "isCorrect": boolean,
  "title": "🐙 You're on the right track!" or "🐙 Almost there!",
  "message": "Friendly constructive feedback on their explanation",
  "keyConcept": "Core rule or intuition"
}
''';

    final userPrompt = 'Topic: $topic\nStudent Explanation: $studentExplanation';
    return _callAiWithFallback(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }

  /// ✨ Improve My Understanding: Refines a messy note without overwriting original.
  Future<String> improveUnderstanding({required String rawNote}) async {
    final systemPrompt = '''
You are Xy, an educational math assistant.
Transform the student's rough study note into a clear, beautifully formatted, bulleted study note summary.
Keep it student-friendly and concise.
Return ONLY the refined markdown study note text. Do not wrap in JSON.
''';

    try {
      final response = await _callGroq(
        systemPrompt: systemPrompt,
        userPrompt: rawNote,
        isJsonMode: false,
      );
      return response;
    } catch (_) {
      try {
        final response = await _callNvidia(
          systemPrompt: systemPrompt,
          userPrompt: rawNote,
          isJsonMode: false,
        );
        return response;
      } catch (e) {
        return 'To solve equations, isolate the variable step-by-step using inverse operations on both sides of the balance scale.';
      }
    }
  }

  /// Core HTTP executor with Groq -> NVIDIA fallback.
  Future<AiFeedbackResult> _callAiWithFallback({
    required String systemPrompt,
    required String userPrompt,
  }) async {
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
          title: '🐙 Xy\'s Learning Nudge',
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
