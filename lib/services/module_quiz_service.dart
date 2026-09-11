import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/module_quiz_model.dart';
import 'package:algebrix/services/ai_gateway.dart';

/// Service powering AI-Generated Module Quizzes, with the offline Seed Bank as
/// the fallback whenever the AI proxy cannot answer.
///
/// The Gemini -> Groq -> NVIDIA chain used to run here with keys read from the
/// bundled `.env`. It now runs inside the `ai-proxy` Edge Function, so no
/// provider key ships with the app.
///
/// Enforces strict module-specific scope constraints, 10 progressive items, and
/// mathematical accuracy.
class ModuleQuizService {
  final AiGateway _gateway;

  ModuleQuizService({http.Client? client, AiGateway? gateway})
      : _gateway = gateway ?? AiGateway(client: client);

  /// Builds a dedicated, strict system prompt tailored to the requested module's exact curriculum.
  String _buildSystemPrompt(ModuleContent module) {
    if (module.id == 'module6') {
      return _buildModule6SystemPrompt();
    } else if (module.id == 'module5') {
      return _buildModule5SystemPrompt();
    } else if (module.id == 'module4') {
      return _buildModule4SystemPrompt();
    } else if (module.id == 'module3') {
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
❌ DO NOT ask questions about Inequalities (<, >, ≤, ≥) — those belong to Module 4.
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

  String _buildModule4SystemPrompt() {
    return '''
You are Xy, the expert educational AI quiz master in Algebrix.
Create an engaging, 10-item progressive algebra quiz strictly based on Module 4 ("Inequalities").

MODULE 4 SCOPE (ONLY USE THESE 5 LESSONS):
• Understanding Inequalities: The symbols <, >, ≤, ≥; an inequality describes a RANGE of values, not one answer; ≤ and ≥ include the boundary value while < and > exclude it.
• One-Step Inequalities: Solving with a single inverse operation (e.g. x + 3 < 8 ⇒ x < 5; x − 2 ≤ 6 ⇒ x ≤ 8; 3x < 12 ⇒ x < 4; x ÷ 4 ≥ 3 ⇒ x ≥ 12).
• The Negative Number Rule: Multiplying or dividing BOTH sides by a negative reverses the inequality (e.g. −2x < 8 ⇒ x > −4). Adding or subtracting NEVER reverses it, because negatives reverse the order of values on a number line.
• Two-Step Inequalities: Undoing operations in reverse order, reversing the sign only at a negative multiply or divide (e.g. 2x + 3 < 11 ⇒ x < 4; −2x + 3 ≤ 11 ⇒ x ≥ −4).
• Graphing Inequalities: Boundary value; open circle for < and >, closed circle for ≤ and ≥; shading right for greater and left for less; reading a graph back into an inequality.

STRICT NEGATIVE CONSTRAINTS (FORBIDDEN IN MODULE 4):
❌ DO NOT ask questions about Compound inequalities (e.g. 2 < x < 7, "and"/"or" inequalities).
❌ DO NOT ask questions about Absolute value inequalities (e.g. |x| < 3).
❌ DO NOT ask questions about Two-variable inequalities or systems (e.g. y > 2x + 1).
❌ DO NOT ask questions about Coordinate-plane graphing. Number lines ONLY.
❌ DO NOT ask questions about Quadratic or rational inequalities.

10-QUESTION PROGRESSION BREAKDOWN:
- Questions 1 to 3 (Difficulty: 1, Foundations): Reading the four symbols, deciding whether a value belongs to a solution set, boundary inclusion with ≤ / ≥ versus < / >.
- Questions 4 to 7 (Difficulty: 2, Procedural Operations): One-step inequalities, choosing the correct inverse operation, deciding whether an operation reverses the sign, a single negative multiply or divide.
- Questions 8 to 10 (Difficulty: 3, Multi-Step Mastery): Two-step inequalities with a negative coefficient, translating a described number-line graph into an inequality, spotting the mistake when a solver forgot to reverse the sign.

MATHEMATICAL RIGOR & EXPLANATION RULES:
1. Every calculation MUST be exact. Verify the math before outputting choices!
2. The correct answer MUST be present in the options list and match correctIndex.
3. NEVER include internal chain-of-thought, reasoning steps, or scratchpad text in the explanation or question.
4. When asking to solve an inequality, state it clearly: e.g. "Solve for x: 2x + 3 < 11".
5. Describe graphs in WORDS, never ASCII art: e.g. "a closed circle at 4 with shading to the right".
6. Distractors must be pedagogically meaningful — especially the answer a learner gets when they forget to reverse the sign.
7. Mix Question Types: "multipleChoice" (3 or 4 options) and "trueFalse" (2 options).
8. Zero-Emoji Rule: NEVER include hint emojis in question text or options.

Return ONLY a JSON object with this EXACT structure:
{
  "questions": [
    {
      "id": "m4_q1",
      "subLessonTitle": "Understanding Inequalities",
      "question": "Which value does NOT belong to the solution of x < 6?",
      "type": "multipleChoice",
      "options": ["2", "5", "6"],
      "correctIndex": 2,
      "explanation": "Substituting 6 gives 6 < 6, which is false, so 6 is excluded.",
      "difficulty": 1
    }
  ]
}
''';
  }

  String _buildModule5SystemPrompt() {
    return '''
You are Xy, the expert educational AI quiz master in Algebrix.
Create an engaging, 10-item progressive algebra quiz strictly based on Module 5 ("Linear Relationships").

MODULE 5 SCOPE (ONLY USE THESE 6 LESSONS):
• Exploring the Coordinate Plane: x-axis and y-axis, the origin (0, 0), ordered pairs written (x, y) where x comes first, plotting and naming points, the four quadrants.
• Discovering Slope: Slope as rise over run, the rate of change between two points, positive slope rising left-to-right, negative slope falling, zero slope for a horizontal line.
• Understanding Linear Relationships: A relationship is linear when y changes by the same amount for each equal step in x; recognising linear versus non-linear tables and descriptions.
• Building Linear Equations: The form y = mx + b, where m is the rate of change and b is the starting value; turning a word situation or a table into an equation.
• Graphing Linear Equations: Plotting the y-intercept first, then using the slope to step to the next point, and drawing the line through them.
• Reading Linear Graphs: Interpreting slope as a rate in context ("10 questions per hour") and the y-intercept as a starting amount; reading what a specific point means.

STRICT NEGATIVE CONSTRAINTS (FORBIDDEN IN MODULE 5):
❌ DO NOT ask questions about systems of equations or solving two equations at once.
❌ DO NOT ask questions about point-slope form or standard form (Ax + By = C).
❌ DO NOT ask questions about parallel or perpendicular slope relationships.
❌ DO NOT ask questions about linear inequalities or shaded regions of the plane.
❌ DO NOT ask questions about quadratic, exponential, or absolute value graphs.
❌ DO NOT ask questions about distance or midpoint formulas.

10-QUESTION PROGRESSION BREAKDOWN:
- Questions 1 to 3 (Difficulty: 1, Foundations): Reading ordered pairs, identifying the origin and the axes, naming which coordinate moves horizontally, recognising that (2, 4) and (4, 2) are different points.
- Questions 4 to 7 (Difficulty: 2, Procedural Operations): Computing slope from rise and run or from a table, identifying m and b in y = mx + b, turning a short word situation into an equation.
- Questions 8 to 10 (Difficulty: 3, Multi-Step Mastery): Evaluating a linear equation at a given x, finding the y-intercept from an equation, interpreting what a specific point means in a real context.

MATHEMATICAL RIGOR & EXPLANATION RULES:
1. Every calculation MUST be exact. Verify the math before outputting choices!
2. The correct answer MUST be present in the options list and match correctIndex.
3. NEVER include internal chain-of-thought, reasoning steps, or scratchpad text in the explanation or question.
4. Describe graphs in WORDS, never ASCII art: e.g. "a line passing through (0, 3) that rises 2 units for every 1 unit right".
5. Write ordered pairs as (x, y) with a comma and a space.
6. Distractors must be pedagogically meaningful — especially swapping x and y, or confusing the slope with the y-intercept.
7. Mix Question Types: "multipleChoice" (3 or 4 options) and "trueFalse" (2 options).
8. Zero-Emoji Rule: NEVER include hint emojis in question text or options.

Return ONLY a JSON object with this EXACT structure:
{
  "questions": [
    {
      "id": "m5_q1",
      "subLessonTitle": "Exploring the Coordinate Plane",
      "question": "In the point (3, 5), which number tells you how far to move right?",
      "type": "multipleChoice",
      "options": ["3", "5", "8"],
      "correctIndex": 0,
      "explanation": "The first number of an ordered pair is the x-coordinate, which moves horizontally.",
      "difficulty": 1
    }
  ]
}
''';
  }

  String _buildModule6SystemPrompt() {
    return '''
You are Xy, the expert educational AI quiz master in Algebrix.
Create an engaging, 10-item progressive algebra quiz strictly based on Module 6 ("Polynomials").

MODULE 6 SCOPE (ONLY USE THESE 5 LESSONS):
• Meet the Polynomials: Terms separated by + and − with the sign belonging to the term after it; coefficient, variable, exponent and constant; monomial, binomial and trinomial; degree as the highest exponent; like terms need the same variable AND the same exponent.
• Adding Polynomials: Dropping brackets and combining like terms only (e.g. (3x² + 2x + 1) + (2x² + 5x + 4) = 5x² + 7x + 5). Unlike terms stay side by side.
• Subtracting Polynomials: Distributing the −1 across every term in the second group before combining, so signs already negative flip to positive (e.g. (5x + 4) − (2x − 3) = 3x + 7).
• Multiplying Polynomials: Every term of the first group multiplying every term of the second, shown as a rectangle area model; FOIL only as a nickname for those same four products (e.g. (x + 2)(x + 3) = x² + 5x + 6).
• Factoring Polynomials: Pulling out the greatest common factor (e.g. 6x + 9 = 3(2x + 3), 4x² + 6x = 2x(2x + 3)) and factoring a simple trinomial by finding two numbers that multiply to the constant and add to the middle coefficient.

STRICT NEGATIVE CONSTRAINTS (FORBIDDEN IN MODULE 6):
❌ DO NOT ask questions about polynomial division (long or synthetic).
❌ DO NOT ask questions about solving quadratic equations, the quadratic formula, or roots and zeros.
❌ DO NOT ask questions about factoring when the leading coefficient is not 1 (e.g. 2x² + 7x + 3).
❌ DO NOT ask questions about special products by name (difference of squares, perfect square trinomials).
❌ DO NOT ask questions about polynomials in more than one variable beyond simple like-term comparison.
❌ DO NOT ask questions about negative or fractional exponents, or about graphing polynomials.

10-QUESTION PROGRESSION BREAKDOWN:
- Questions 1 to 3 (Difficulty: 1, Foundations): Counting terms, naming monomial/binomial/trinomial, identifying a coefficient or constant, reading the degree, deciding whether two terms are like terms.
- Questions 4 to 7 (Difficulty: 2, Procedural Operations): Adding two polynomials, subtracting with a sign flip, spotting the error when a learner forgets to distribute the negative.
- Questions 8 to 10 (Difficulty: 3, Multi-Step Mastery): Multiplying two binomials, factoring out a greatest common factor, factoring a simple trinomial with a leading coefficient of 1.

MATHEMATICAL RIGOR & EXPLANATION RULES:
1. Every calculation MUST be exact. Expand and re-check every product before outputting choices!
2. The correct answer MUST be present in the options list and match correctIndex.
3. NEVER include internal chain-of-thought, reasoning steps, or scratchpad text in the explanation or question.
4. Write exponents with superscript characters: x², x³. Never write x^2.
5. Always write polynomials in descending order of degree.
6. Distractors must be pedagogically meaningful — especially adding exponents when combining like terms, or missing the sign flip in a subtraction.
7. Mix Question Types: "multipleChoice" (3 or 4 options) and "trueFalse" (2 options).
8. Zero-Emoji Rule: NEVER include hint emojis in question text or options.

Return ONLY a JSON object with this EXACT structure:
{
  "questions": [
    {
      "id": "m6_q1",
      "subLessonTitle": "Meet the Polynomials",
      "question": "How many terms does 4x² + 3x − 7 have?",
      "type": "multipleChoice",
      "options": ["2", "3", "4"],
      "correctIndex": 1,
      "explanation": "Terms are separated by + and −, so the three terms are 4x², 3x and −7.",
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

    // The provider chain lives in the Edge Function now; from here it is one
    // call that either answers or does not. Every failure — no session, quota
    // spent, providers down — lands on the same offline seed bank the app has
    // always fallen back to, so a learner still gets a full 10 questions.
    if (_gateway.isAvailable) {
      try {
        debugPrint('Generating quiz via the Algebrix AI proxy...');
        final completion = await _gateway.complete(
          task: 'quiz',
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
        final parsed = _parseQuizJson(
          completion.text,
          module: module,
          provider: completion.provider,
        );
        if (parsed.questions.length >= 8) return parsed;
        debugPrint('Proxy returned too few questions. Using the seed bank.');
      } on AiGatewayException catch (e) {
        debugPrint('AI proxy unavailable (${e.failure.name}): ${e.message}');
      } catch (e) {
        debugPrint('Quiz generation failed: $e');
      }
    }

    debugPrint('Generating quiz via the Algebrix Dynamic Seed Bank...');
    return _generateSeedBankQuiz(module);
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

  /// High-quality dynamic seed bank for Modules 1-6 with 10 progressive items strictly within scope.
  ModuleQuiz _generateSeedBankQuiz(ModuleContent module) {
    final rng = Random();

    if (module.id == 'module6') {
      return _buildModule6SeedQuiz(rng);
    } else if (module.id == 'module5') {
      return _buildModule5SeedQuiz(rng);
    } else if (module.id == 'module4') {
      return _buildModule4SeedQuiz(rng);
    } else if (module.id == 'module3') {
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

  ModuleQuiz _buildModule4SeedQuiz(Random rng) {
    // Randomised within a narrow, verified range so repeat attempts differ
    // without ever producing an unsolvable or off-scope item.
    final a = 2 + rng.nextInt(4); // 2..5
    final b = 3 + rng.nextInt(5); // 3..7
    final sum = a + b;

    final questions = <ModuleQuizQuestion>[
      ModuleQuizQuestion(
        id: 'm4_seed_1',
        subLessonTitle: 'Understanding Inequalities',
        question: 'Which symbol means "greater than or equal to"?',
        type: QuizQuestionType.multipleChoice,
        options: const ['<', '≥', '≤'],
        correctIndex: 1,
        explanation:
            'The ≥ symbol combines "greater than" with the equal line underneath, so the boundary value counts too.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm4_seed_2',
        subLessonTitle: 'Understanding Inequalities',
        question: 'Does the value 6 belong to the solution of x < 6?',
        type: QuizQuestionType.trueFalse,
        options: const ['True', 'False'],
        correctIndex: 1,
        explanation:
            'Substituting gives 6 < 6, which is false. A plain < excludes the boundary value.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm4_seed_3',
        subLessonTitle: 'Understanding Inequalities',
        question: 'Which value belongs to the solution of x ≥ 4?',
        type: QuizQuestionType.multipleChoice,
        options: const ['1', '3', '4'],
        correctIndex: 2,
        explanation:
            'Because the symbol is ≥, the boundary 4 is included: 4 ≥ 4 is true.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm4_seed_4',
        subLessonTitle: 'One-Step Inequalities',
        question: 'Solve for x: x + $a < $sum',
        type: QuizQuestionType.multipleChoice,
        options: ['x < $b', 'x > $b', 'x < $sum'],
        correctIndex: 0,
        explanation:
            'Subtract $a from both sides: x + $a − $a < $sum − $a, so x < $b.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm4_seed_5',
        subLessonTitle: 'One-Step Inequalities',
        question: 'To solve x − 7 > 4, what should you do to both sides?',
        type: QuizQuestionType.multipleChoice,
        options: const ['Add 7', 'Subtract 7', 'Divide by 7'],
        correctIndex: 0,
        explanation:
            'x is having 7 subtracted, so add 7 to both sides: x − 7 + 7 > 4 + 7, giving x > 11.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm4_seed_6',
        subLessonTitle: 'The Negative Number Rule',
        question:
            'Does subtracting 5 from both sides of an inequality reverse the sign?',
        type: QuizQuestionType.trueFalse,
        options: const ['True', 'False'],
        correctIndex: 1,
        explanation:
            'Only multiplying or dividing both sides by a negative reverses the sign. Adding and subtracting never do.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm4_seed_7',
        subLessonTitle: 'The Negative Number Rule',
        question: 'Solve for x: −2x < 8',
        type: QuizQuestionType.multipleChoice,
        options: const ['x < −4', 'x > −4', 'x > 4'],
        correctIndex: 1,
        explanation:
            'Divide both sides by −2. Because the divisor is negative, < reverses to >, giving x > −4.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm4_seed_8',
        subLessonTitle: 'Two-Step Inequalities',
        question: 'Solve for x: 2x + 3 < 11',
        type: QuizQuestionType.multipleChoice,
        options: const ['x < 4', 'x > 4', 'x < 7'],
        correctIndex: 0,
        explanation:
            'Subtract 3 to get 2x < 8, then divide by 2 to get x < 4. Dividing by a positive keeps the sign.',
        difficulty: 3,
      ),
      ModuleQuizQuestion(
        id: 'm4_seed_9',
        subLessonTitle: 'Graphing Inequalities',
        question:
            'A number line shows a closed circle at −1 with shading to the right. Which inequality is it?',
        type: QuizQuestionType.multipleChoice,
        options: const ['x > −1', 'x ≥ −1', 'x ≤ −1'],
        correctIndex: 1,
        explanation:
            'A closed circle includes the boundary, and shading to the right means greater, so x ≥ −1.',
        difficulty: 3,
      ),
      ModuleQuizQuestion(
        id: 'm4_seed_10',
        subLessonTitle: 'The Negative Number Rule',
        question:
            'A learner solves −4x > 20 and writes x > −5. What went wrong?',
        type: QuizQuestionType.multipleChoice,
        options: const [
          'They divided by a negative but did not reverse the sign',
          'They should have added 4 instead',
          'Nothing, the answer is correct',
        ],
        correctIndex: 0,
        explanation:
            'Dividing both sides by −4 reverses > into <, so the correct solution is x < −5.',
        difficulty: 3,
      ),
    ];

    return ModuleQuiz(
      moduleId: 'module4',
      moduleTitle: 'Inequalities',
      questions: questions,
      generatedAt: DateTime.now(),
      providerUsed: 'Algebrix Curated Seed Bank',
    );
  }

  ModuleQuiz _buildModule5SeedQuiz(Random rng) {
    // Randomised within a narrow, verified range so repeat attempts differ
    // without ever producing an unsolvable or off-scope item.
    final m = 2 + rng.nextInt(4); // 2..5
    final b = 1 + rng.nextInt(6); // 1..6
    final yAtTwo = m * 2 + b;

    final questions = <ModuleQuizQuestion>[
      ModuleQuizQuestion(
        id: 'm5_seed_1',
        subLessonTitle: 'Exploring the Coordinate Plane',
        question:
            'In the point (3, 5), which number tells you how far to move right?',
        type: QuizQuestionType.multipleChoice,
        options: const ['3', '5', '8'],
        correctIndex: 0,
        explanation:
            'The first number of an ordered pair is the x-coordinate, and x moves horizontally.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm5_seed_2',
        subLessonTitle: 'Exploring the Coordinate Plane',
        question: 'What is the point (0, 0) called?',
        type: QuizQuestionType.multipleChoice,
        options: const ['The origin', 'The slope', 'The y-intercept'],
        correctIndex: 0,
        explanation:
            'The origin is where the x-axis and y-axis cross, at zero across and zero up.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm5_seed_3',
        subLessonTitle: 'Exploring the Coordinate Plane',
        question: 'Are (2, 4) and (4, 2) the same point?',
        type: QuizQuestionType.trueFalse,
        options: const ['True', 'False'],
        correctIndex: 1,
        explanation:
            'Order matters. (2, 4) is 2 right and 4 up, while (4, 2) is 4 right and 2 up.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm5_seed_4',
        subLessonTitle: 'Discovering Slope',
        question:
            'A line rises 6 units for every 3 units it runs to the right. What is its slope?',
        type: QuizQuestionType.multipleChoice,
        options: const ['2', '3', '18'],
        correctIndex: 0,
        explanation: 'Slope is rise over run, so 6 ÷ 3 = 2.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm5_seed_5',
        subLessonTitle: 'Discovering Slope',
        question: 'A line falls as you move to the right. Its slope is:',
        type: QuizQuestionType.multipleChoice,
        options: const ['Negative', 'Positive', 'Zero'],
        correctIndex: 0,
        explanation:
            'Falling means the rise is negative, so the slope is negative. A flat line would have slope zero.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm5_seed_6',
        subLessonTitle: 'Understanding Linear Relationships',
        question:
            'In a table, y goes 7, 10, 13 as x goes 1, 2, 3. What is the rate of change?',
        type: QuizQuestionType.multipleChoice,
        options: const ['3', '7', '10'],
        correctIndex: 0,
        explanation:
            'Each step of 1 in x adds 3 to y, and because that step is always the same, the relationship is linear.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm5_seed_7',
        subLessonTitle: 'Building Linear Equations',
        question:
            'You start with 5 coins and earn 2 coins per level. Which equation fits?',
        type: QuizQuestionType.multipleChoice,
        options: const ['y = 2x + 5', 'y = 5x + 2', 'y = 7x'],
        correctIndex: 0,
        explanation:
            'The rate of change rides with x, so 2x, and the starting amount is added on, giving y = 2x + 5.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm5_seed_8',
        subLessonTitle: 'Graphing Linear Equations',
        question: 'Where does the line y = 3x − 4 cross the y-axis?',
        type: QuizQuestionType.multipleChoice,
        options: const ['−4', '3', '4'],
        correctIndex: 0,
        explanation:
            'At the y-axis x is 0, so y = 3(0) − 4 = −4. The b in y = mx + b is the y-intercept.',
        difficulty: 3,
      ),
      ModuleQuizQuestion(
        id: 'm5_seed_9',
        subLessonTitle: 'Graphing Linear Equations',
        question: 'For y = ${m}x + $b, what is y when x = 2?',
        type: QuizQuestionType.multipleChoice,
        options: ['$yAtTwo', '${m + b}', '${2 * (m + b)}'],
        correctIndex: 0,
        explanation:
            'Substitute x = 2: y = $m × 2 + $b = $yAtTwo.',
        difficulty: 3,
      ),
      ModuleQuizQuestion(
        id: 'm5_seed_10',
        subLessonTitle: 'Reading Linear Graphs',
        question:
            'Coins per level follow y = 4x + 6. What does the point (3, 18) mean?',
        type: QuizQuestionType.multipleChoice,
        options: const [
          '18 coins at level 3',
          '3 coins at level 18',
          '18 coins earned each level',
        ],
        correctIndex: 0,
        explanation:
            'x is the level and y is the coins, and 4(3) + 6 = 18, so it means 18 coins at level 3.',
        difficulty: 3,
      ),
    ];

    return ModuleQuiz(
      moduleId: 'module5',
      moduleTitle: 'Linear Relationships',
      questions: questions,
      generatedAt: DateTime.now(),
      providerUsed: 'Algebrix Curated Seed Bank',
    );
  }

  ModuleQuiz _buildModule6SeedQuiz(Random rng) {
    // p and q are kept distinct so the sum and the product can never collide,
    // which would make two options identical.
    final p = 1 + rng.nextInt(4); // 1..4
    final q = p + 1 + rng.nextInt(3); // p+1..p+3
    final sum = p + q;
    final product = p * q;

    final questions = <ModuleQuizQuestion>[
      ModuleQuizQuestion(
        id: 'm6_seed_1',
        subLessonTitle: 'Meet the Polynomials',
        question: 'How many terms does 4x² + 3x − 7 have?',
        type: QuizQuestionType.multipleChoice,
        options: const ['2', '3', '4'],
        correctIndex: 1,
        explanation:
            'Terms are separated by + and −, so the three terms are 4x², 3x and −7.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm6_seed_2',
        subLessonTitle: 'Meet the Polynomials',
        question: 'In the term 5x², what is the coefficient?',
        type: QuizQuestionType.multipleChoice,
        options: const ['5', '2', 'x'],
        correctIndex: 0,
        explanation:
            'The coefficient is the number multiplying the variable. The 2 is the exponent.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm6_seed_3',
        subLessonTitle: 'Meet the Polynomials',
        question: 'A polynomial with exactly two terms is called a:',
        type: QuizQuestionType.multipleChoice,
        options: const ['Monomial', 'Binomial', 'Trinomial'],
        correctIndex: 1,
        explanation:
            'Bi means two, so x + 3 is a binomial. One term is a monomial and three is a trinomial.',
        difficulty: 1,
      ),
      ModuleQuizQuestion(
        id: 'm6_seed_4',
        subLessonTitle: 'Adding Polynomials',
        question: 'Add (3x² + 2x) + (2x² + 5x).',
        type: QuizQuestionType.multipleChoice,
        options: const ['5x² + 7x', '5x⁴ + 7x²', '7x² + 5x'],
        correctIndex: 0,
        explanation:
            'Combine like terms: 3x² + 2x² = 5x² and 2x + 5x = 7x. Exponents never add here.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm6_seed_5',
        subLessonTitle: 'Meet the Polynomials',
        question: 'Are 3x² and 2x like terms?',
        type: QuizQuestionType.trueFalse,
        options: const ['True', 'False'],
        correctIndex: 1,
        explanation:
            'Like terms need the same variable AND the same exponent. These have different exponents.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm6_seed_6',
        subLessonTitle: 'Subtracting Polynomials',
        question: 'Subtract (5x + 4) − (2x − 3).',
        type: QuizQuestionType.multipleChoice,
        options: const ['3x + 7', '3x + 1', '7x + 1'],
        correctIndex: 0,
        explanation:
            'Distribute the negative: 5x + 4 − 2x + 3. The −3 becomes +3, giving 3x + 7.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm6_seed_7',
        subLessonTitle: 'Subtracting Polynomials',
        question:
            'When you subtract the group (x² − 2x + 5), what does the −2x become?',
        type: QuizQuestionType.multipleChoice,
        options: const ['+2x', '−2x', '−2'],
        correctIndex: 0,
        explanation:
            'Every term is multiplied by −1, so −2x becomes +2x. Terms that were already negative turn positive.',
        difficulty: 2,
      ),
      ModuleQuizQuestion(
        id: 'm6_seed_8',
        subLessonTitle: 'Multiplying Polynomials',
        question: 'Multiply (x + 2)(x + 3).',
        type: QuizQuestionType.multipleChoice,
        options: const ['x² + 5x + 6', 'x² + 6x + 5', 'x² + 6'],
        correctIndex: 0,
        explanation:
            'Every piece meets every piece: x² + 3x + 2x + 6, and the middle terms combine to 5x.',
        difficulty: 3,
      ),
      ModuleQuizQuestion(
        id: 'm6_seed_9',
        subLessonTitle: 'Multiplying Polynomials',
        question: 'Multiply (x + $p)(x + $q).',
        type: QuizQuestionType.multipleChoice,
        options: [
          'x² + ${sum}x + $product',
          'x² + ${product}x + $sum',
          'x² + $product',
        ],
        correctIndex: 0,
        explanation:
            'The two numbers add to give the middle term ($sum) and multiply to give the constant ($product).',
        difficulty: 3,
      ),
      ModuleQuizQuestion(
        id: 'm6_seed_10',
        subLessonTitle: 'Factoring Polynomials',
        question: 'Factor x² + 7x + 12.',
        type: QuizQuestionType.multipleChoice,
        options: const [
          '(x + 3)(x + 4)',
          '(x + 2)(x + 6)',
          '(x + 1)(x + 12)',
        ],
        correctIndex: 0,
        explanation:
            'Find two numbers that multiply to 12 and add to 7. Only 3 and 4 do both.',
        difficulty: 3,
      ),
    ];

    return ModuleQuiz(
      moduleId: 'module6',
      moduleTitle: 'Polynomials',
      questions: questions,
      generatedAt: DateTime.now(),
      providerUsed: 'Algebrix Curated Seed Bank',
    );
  }
}
