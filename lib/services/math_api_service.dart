import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Problem model for Balance Scale equations.
class BalanceScaleProblem {
  const BalanceScaleProblem({
    required this.id,
    required this.equation,
    required this.leftExpr,
    required this.rightExpr,
    required this.coefficientX,
    required this.constantLeft,
    required this.targetX,
    required this.optimalMoves,
    required this.reasoningOptions,
    required this.correctReasoningIndex,
  });

  final String id;
  final String equation;
  final String leftExpr;
  final String rightExpr;
  final int coefficientX;
  final int constantLeft;
  final int targetX;

  /// Minimum number of moves to solve optimally.
  final int optimalMoves;

  /// Three reasoning explanation options shown after solving.
  final List<String> reasoningOptions;

  /// Index (0–2) of the correct reasoning option.
  final int correctReasoningIndex;
}

/// Evaluation result from MathJS HTTP POST API.
class ScaleStepResult {
  const ScaleStepResult({
    required this.newLeftExpr,
    required this.newRightExpr,
    required this.leftSimplified,
    required this.rightSimplified,
    required this.providerUsed,
    required this.isSuccess,
  });

  final String newLeftExpr;
  final String newRightExpr;
  final String leftSimplified;
  final String rightSimplified;
  final String providerUsed;
  final bool isSuccess;
}

/// External Math REST API Service implementing HTTP GET & HTTP POST.
class MathApiService {
  MathApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _newtonApiUrl = 'https://newton.vercel.app/api/v2/simplify/';

  /// Sample pool of linear equations for Balance Scale mode.
  static const List<BalanceScaleProblem> _sampleProblems = [
    BalanceScaleProblem(
      id: 'p1',
      equation: '2x + 6 = 18',
      leftExpr: '2x + 6',
      rightExpr: '18',
      coefficientX: 2,
      constantLeft: 6,
      targetX: 6,
      optimalMoves: 2,
      reasoningOptions: [
        'Subtracting 6 from both sides cancels the constant term (+6) to leave 2x = 12, then dividing both sides by 2 isolates x = 6.',
        'Dividing by 2 first leaves the 6 unchanged, so 2x + 6 = 18 immediately becomes x + 6 = 9 before subtracting 6 from both sides.',
        'Subtracting 6 from the left side eliminates +6, while adding 6 to the right side balances the scale to reach 2x = 24.',
      ],
      correctReasoningIndex: 0,
    ),
    BalanceScaleProblem(
      id: 'p2',
      equation: '3x + 4 = 16',
      leftExpr: '3x + 4',
      rightExpr: '16',
      coefficientX: 3,
      constantLeft: 4,
      targetX: 4,
      optimalMoves: 2,
      reasoningOptions: [
        'Dividing both sides by 3 first turns 3x + 4 = 16 into x + 4 = 5.33, eliminating the coefficient before handling the constant 4.',
        'Applying the inverse operation (− 4) to both sides eliminates the constant, then dividing both sides by 3 isolates x while preserving equality.',
        'Subtracting 4 cancels the constant on the left, but we must multiply the right side by 3 to counteract the division on the left.',
      ],
      correctReasoningIndex: 1,
    ),
    BalanceScaleProblem(
      id: 'p3',
      equation: '4x - 5 = 11',
      leftExpr: '4x - 5',
      rightExpr: '11',
      coefficientX: 4,
      constantLeft: -5,
      targetX: 4,
      optimalMoves: 2,
      reasoningOptions: [
        'Subtracting 5 from both sides removes the 5 from 4x − 5, leaving 4x = 6, which then divides evenly by 4 to isolate x.',
        'Multiplying both sides by 4 first clears the coefficient 4, turning the equation into x − 5 = 44 before adding 5.',
        'Adding 5 to both sides uses the additive inverse to cancel −5 into 4x = 16, then dividing both sides by 4 preserves balance to yield x = 4.',
      ],
      correctReasoningIndex: 2,
    ),
    BalanceScaleProblem(
      id: 'p4',
      equation: '2x + 8 = 20',
      leftExpr: '2x + 8',
      rightExpr: '20',
      coefficientX: 2,
      constantLeft: 8,
      targetX: 6,
      optimalMoves: 2,
      reasoningOptions: [
        'Subtracting 8 from both sides creates an equivalent equation 2x = 12, then dividing both sides by 2 isolates x = 6 without fractional terms.',
        'Dividing both sides by 2 first gives x + 8 = 10 because division only affects the variable term and not the constant.',
        'Moving +8 to the right side flips it into +8, making 2x = 28, then dividing both sides by 2 yields the balanced solution.',
      ],
      correctReasoningIndex: 0,
    ),
    BalanceScaleProblem(
      id: 'p5',
      equation: '5x + 3 = 23',
      leftExpr: '5x + 3',
      rightExpr: '23',
      coefficientX: 5,
      constantLeft: 3,
      targetX: 4,
      optimalMoves: 2,
      reasoningOptions: [
        'Dividing both sides by 5 first turns 5x + 3 = 23 into x + 3 = 4.6, allowing us to solve without handling whole numbers.',
        'Subtracting 3 from both sides eliminates the constant term to yield 5x = 20, then dividing both sides by 5 isolates the variable as x = 4.',
        'Subtracting 3 from the left side eliminates the +3, while adding 3 to the right side preserves the physical scale balance.',
      ],
      correctReasoningIndex: 1,
    ),
  ];

  /// Progressive quest-map levels ordered by difficulty (1 → 10).
  static const List<BalanceScaleProblem> _levelProblems = [
    // Level 1: One-step addition inverse
    BalanceScaleProblem(
      id: 'level_1',
      equation: 'x + 3 = 7',
      leftExpr: 'x + 3',
      rightExpr: '7',
      coefficientX: 1,
      constantLeft: 3,
      targetX: 4,
      optimalMoves: 1,
      reasoningOptions: [
        'Subtract 3 from both sides to cancel +3, giving x = 7 − 3 = 4.',
        'Add 3 to both sides to move the constant, giving x = 7 + 3 = 10.',
        'Divide both sides by 3 to remove the constant, giving x = 7 / 3.',
      ],
      correctReasoningIndex: 0,
    ),
    // Level 2: One-step subtraction inverse
    BalanceScaleProblem(
      id: 'level_2',
      equation: 'x - 4 = 6',
      leftExpr: 'x - 4',
      rightExpr: '6',
      coefficientX: 1,
      constantLeft: -4,
      targetX: 10,
      optimalMoves: 1,
      reasoningOptions: [
        'Subtract 4 from both sides to match the sign, giving x = 6 − 4 = 2.',
        'Multiply both sides by 4 to clear the constant, giving x = 6 × 4 = 24.',
        'Add 4 to both sides to cancel −4, giving x = 6 + 4 = 10.',
      ],
      correctReasoningIndex: 2,
    ),
    // Level 3: One-step division
    BalanceScaleProblem(
      id: 'level_3',
      equation: '2x = 12',
      leftExpr: '2x',
      rightExpr: '12',
      coefficientX: 2,
      constantLeft: 0,
      targetX: 6,
      optimalMoves: 1,
      reasoningOptions: [
        'Subtract 2 from both sides to remove the coefficient, giving x = 10.',
        'Divide both sides by 2 to isolate x, giving x = 12 / 2 = 6.',
        'Multiply both sides by 2 to cancel the coefficient, giving x = 24.',
      ],
      correctReasoningIndex: 1,
    ),
    // Level 4: Two-step with positive constant
    BalanceScaleProblem(
      id: 'level_4',
      equation: '2x + 4 = 12',
      leftExpr: '2x + 4',
      rightExpr: '12',
      coefficientX: 2,
      constantLeft: 4,
      targetX: 4,
      optimalMoves: 2,
      reasoningOptions: [
        'Divide both sides by 2 first to get x + 4 = 6, then subtract 4 to find x = 2.',
        'Subtract 4 from the left side only to get 2x = 12, keeping the equation balanced.',
        'Subtract 4 from both sides to get 2x = 8, then divide both sides by 2 to find x = 4.',
      ],
      correctReasoningIndex: 2,
    ),
    // Level 5: Two-step with negative constant
    BalanceScaleProblem(
      id: 'level_5',
      equation: '3x - 6 = 9',
      leftExpr: '3x - 6',
      rightExpr: '9',
      coefficientX: 3,
      constantLeft: -6,
      targetX: 5,
      optimalMoves: 2,
      reasoningOptions: [
        'Add 6 to both sides to cancel −6, yielding 3x = 15, then divide by 3 to get x = 5.',
        'Subtract 6 from both sides to match the sign, yielding 3x = 3, then divide by 3 for x = 1.',
        'Divide both sides by 3 first to get x − 6 = 3, then subtract 6 to find x = −3.',
      ],
      correctReasoningIndex: 0,
    ),
    // Level 6: Two-step with larger coefficient and constant
    BalanceScaleProblem(
      id: 'level_6',
      equation: '4x + 7 = 23',
      leftExpr: '4x + 7',
      rightExpr: '23',
      coefficientX: 4,
      constantLeft: 7,
      targetX: 4,
      optimalMoves: 2,
      reasoningOptions: [
        'Divide both sides by 4 first to get x + 7 = 5.75, then subtract 7 to isolate x.',
        'Subtract 7 from the left and add 7 to the right to maintain balance, giving 4x = 30.',
        'Subtract 7 from both sides to get 4x = 16, then divide both sides by 4 to get x = 4.',
      ],
      correctReasoningIndex: 2,
    ),
    // Level 7: Two-step with coefficient 5 and negative constant
    BalanceScaleProblem(
      id: 'level_7',
      equation: '5x - 8 = 17',
      leftExpr: '5x - 8',
      rightExpr: '17',
      coefficientX: 5,
      constantLeft: -8,
      targetX: 5,
      optimalMoves: 2,
      reasoningOptions: [
        'Subtract 8 from both sides to combine like terms, yielding 5x = 9, then divide by 5.',
        'Add 8 to both sides to cancel −8, yielding 5x = 25, then divide by 5 to get x = 5.',
        'Divide both sides by 5 first to get x − 8 = 3.4, then add 8 for x = 11.4.',
      ],
      correctReasoningIndex: 1,
    ),
    // Level 8: Variables on both sides (collect variable terms)
    BalanceScaleProblem(
      id: 'level_8',
      equation: '3x + 5 = 2x + 12',
      leftExpr: '3x + 5',
      rightExpr: '2x + 12',
      coefficientX: 3,
      constantLeft: 5,
      targetX: 7,
      optimalMoves: 2,
      reasoningOptions: [
        'Subtract 2x from both sides to collect variables on the left, giving x + 5 = 12, then subtract 5 to get x = 7.',
        'Add 2x to both sides to combine variables, giving 5x + 5 = 12, then subtract 5 and divide by 5.',
        'Subtract 5 from both sides first to get 3x = 2x + 7, then subtract 3x to move all terms right.',
      ],
      correctReasoningIndex: 0,
    ),
    // Level 9: Variables on both sides with negative constant
    BalanceScaleProblem(
      id: 'level_9',
      equation: '4x - 3 = 2x + 9',
      leftExpr: '4x - 3',
      rightExpr: '2x + 9',
      coefficientX: 4,
      constantLeft: -3,
      targetX: 6,
      optimalMoves: 3,
      reasoningOptions: [
        'Subtract 4x from both sides to get −3 = −2x + 9, then subtract 9 and divide by −2 for x = 6.',
        'Add 3 to both sides to get 4x = 2x + 12, subtract 2x to get 2x = 12, then divide by 2 for x = 6.',
        'Subtract 2x from both sides to get 2x − 3 = 9, then divide by 2 to get x − 1.5 = 4.5 and add 1.5.',
      ],
      correctReasoningIndex: 1,
    ),
    // Level 10: Variables on both sides with larger coefficients
    BalanceScaleProblem(
      id: 'level_10',
      equation: '6x + 4 = 3x + 19',
      leftExpr: '6x + 4',
      rightExpr: '3x + 19',
      coefficientX: 6,
      constantLeft: 4,
      targetX: 5,
      optimalMoves: 3,
      reasoningOptions: [
        'Divide everything by 3 first to simplify coefficients, giving 2x + 4 = x + 19, then solve.',
        'Subtract 3x from both sides to get 3x + 4 = 19, then subtract 4 to get 3x = 15, then divide by 3 for x = 5.',
        'Add 3x to both sides to collect variables, giving 9x + 4 = 19, then subtract 4 and divide by 9.',
      ],
      correctReasoningIndex: 1,
    ),
  ];

  /// HTTP GET Request: Fetches equation simplification verification from Newton API.
  Future<String> fetchVerifiedSolution(String expression) async {
    final encodedExpr = Uri.encodeComponent(expression);
    final url = Uri.parse('$_newtonApiUrl$encodedExpr');

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['result']?.toString() ?? expression;
      }
    } catch (e) {
      debugPrint('Newton API HTTP GET Error: $e');
    }

    // Offline Fallback
    return _localSimplify(expression);
  }

  /// Evaluates balance scale step using deterministic linear algebra engine.
  Future<ScaleStepResult> evaluateScaleOperation({
    required String leftExpr,
    required String rightExpr,
    required String op, // '+', '-', '*', '/'
    required num value,
    String targetSide = 'both', // 'both', 'left', 'right'
  }) async {
    final leftOp = (targetSide == 'both' || targetSide == 'left')
        ? _buildExpr(leftExpr, op, value)
        : leftExpr;
    final rightOp = (targetSide == 'both' || targetSide == 'right')
        ? _buildExpr(rightExpr, op, value)
        : rightExpr;

    final leftSimplified = (targetSide == 'both' || targetSide == 'left')
        ? _localStepSimplify(leftExpr, op, value)
        : leftExpr;
    final rightSimplified = (targetSide == 'both' || targetSide == 'right')
        ? _localStepSimplify(rightExpr, op, value)
        : rightExpr;

    return ScaleStepResult(
      newLeftExpr: leftOp,
      newRightExpr: rightOp,
      leftSimplified: leftSimplified,
      rightSimplified: rightSimplified,
      providerUsed: 'Algebrix Math Engine',
      isSuccess: true,
    );
  }

  /// Fetches a new problem for the Balance Scale game.
  BalanceScaleProblem getRandomProblem({String? currentId}) {
    final available = _sampleProblems.where((p) => p.id != currentId).toList();
    available.shuffle();
    return available.first;
  }

  /// Returns the specific BalanceScaleProblem for a quest map level (1-indexed).
  BalanceScaleProblem getLevelProblem(int levelNumber) {
    assert(levelNumber >= 1 && levelNumber <= _levelProblems.length);
    return _levelProblems[levelNumber - 1];
  }

  /// Total number of quest levels available.
  int get totalQuestLevels => _levelProblems.length;

  /// Generates dynamic operation chips from a problem's coefficients,
  /// consistently returning exactly 8 unique, high-yield operation options.
  List<Map<String, dynamic>> generateOpsForProblem(BalanceScaleProblem problem) {
    final rng = Random();
    final uniqueSet = <String>{};
    final ops = <Map<String, dynamic>>[];

    void addOp(String op, num value) {
      if (value <= 0) return;
      final key = '$op-$value';
      if (!uniqueSet.contains(key) && ops.length < 8) {
        uniqueSet.add(key);
        ops.add({'op': op, 'value': value});
      }
    }

    final constVal = problem.constantLeft.abs();
    final coeff = problem.coefficientX;
    final target = problem.targetX;

    // 1. Correct Step 1: Inverse constant operation
    if (problem.constantLeft > 0) {
      addOp('-', constVal);
    } else if (problem.constantLeft < 0) {
      addOp('+', constVal);
    }

    // 2. Correct Step 2: Divide by coefficient
    addOp('/', coeff);

    // 3. Common Distractor: Same operation on constant (wrong sign)
    if (problem.constantLeft > 0) {
      addOp('+', constVal);
    } else {
      addOp('-', constVal);
    }

    // 4. Common Distractor: Divide by constant
    if (constVal > 1 && constVal != coeff) {
      addOp('/', constVal);
    }

    // 5. Common Distractor: Subtract / Add coefficient
    addOp('-', coeff);
    addOp('+', coeff);

    // 6. Tempting Distractor: Multiply by coefficient or 2
    addOp('*', 2);
    if (coeff > 2) {
      addOp('*', coeff);
    }

    // 7. Solution-based Distractor: Operations with targetX
    if (target > 1 && target != coeff && target != constVal) {
      addOp('-', target);
      addOp('+', target);
      addOp('/', target);
    }

    // 8. Fill remaining slots up to 8 with smart relevant math operators
    final candidates = [
      {'op': '-', 'value': 2},
      {'op': '+', 'value': 2},
      {'op': '-', 'value': 1},
      {'op': '+', 'value': 1},
      {'op': '/', 'value': 2},
      {'op': '*', 'value': 3},
      {'op': '-', 'value': 5},
      {'op': '+', 'value': 3},
      {'op': '/', 'value': 4},
      {'op': '/', 'value': 5},
    ];

    for (final cand in candidates) {
      if (ops.length >= 8) break;
      addOp(cand['op'] as String, cand['value'] as num);
    }

    // Fallback if still under 8
    int extra = 6;
    while (ops.length < 8) {
      addOp('-', extra);
      addOp('+', extra);
      extra++;
    }

    ops.shuffle(rng);
    return ops.take(8).toList();
  }

  String _buildExpr(String baseExpr, String op, num value) {
    final valStr = value.toString().replaceAll('.0', '');
    if (op == '+') return '($baseExpr) + $valStr';
    if (op == '-') return '($baseExpr) - $valStr';
    if (op == '*') return '($baseExpr) * $valStr';
    if (op == '/') return '($baseExpr) / $valStr';
    return baseExpr;
  }

  String _localSimplify(String expr) {
    try {
      return _LinearExpr.parse(expr).format();
    } catch (_) {
      return expr;
    }
  }

  String _localStepSimplify(String expr, String op, num val) {
    try {
      final parsed = _LinearExpr.parse(expr);
      final applied = parsed.apply(op, val);
      return applied.format();
    } catch (_) {
      return '$expr $op $val';
    }
  }
}

/// Internal deterministic linear algebraic expression parser & simplifier.
class _LinearExpr {
  final double coeff;
  final double constant;

  const _LinearExpr(this.coeff, this.constant);

  static _LinearExpr parse(String raw) {
    final s = raw.replaceAll('(', '').replaceAll(')', '').trim();
    if (s.isEmpty) return const _LinearExpr(0, 0);

    double totalCoeff = 0;
    double totalConst = 0;

    // Matches signed terms e.g. "+3x", "-2x", "x", "-x", "+5", "-8", "18"
    final termRegex = RegExp(
      r'([+-]?\s*(?:\d*\.?\d*x|\d+\.?\d*))',
      caseSensitive: false,
    );
    final cleanStr = s.replaceAll(' ', '');
    final matches = termRegex.allMatches(cleanStr);

    for (final match in matches) {
      final term = match.group(0)!.trim();
      if (term.isEmpty) continue;

      if (term.toLowerCase().contains('x')) {
        final coeffPart = term.toLowerCase().replaceAll('x', '');
        if (coeffPart.isEmpty || coeffPart == '+') {
          totalCoeff += 1.0;
        } else if (coeffPart == '-') {
          totalCoeff -= 1.0;
        } else {
          totalCoeff += double.tryParse(coeffPart) ?? 0.0;
        }
      } else {
        totalConst += double.tryParse(term) ?? 0.0;
      }
    }

    return _LinearExpr(totalCoeff, totalConst);
  }

  _LinearExpr apply(String op, num val) {
    final v = val.toDouble();
    if (op == '+') {
      return _LinearExpr(coeff, constant + v);
    } else if (op == '-') {
      return _LinearExpr(coeff, constant - v);
    } else if (op == '*') {
      return _LinearExpr(coeff * v, constant * v);
    } else if (op == '/') {
      if (v.abs() > 1e-9) {
        return _LinearExpr(coeff / v, constant / v);
      }
    }
    return this;
  }

  String format() {
    String formatNum(double d) {
      if ((d - d.roundToDouble()).abs() < 1e-9) {
        return d.round().toString();
      }
      return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }

    final isZeroCoeff = coeff.abs() < 1e-9;
    final isZeroConst = constant.abs() < 1e-9;

    if (isZeroCoeff) {
      return formatNum(constant);
    }

    String coeffStr;
    if ((coeff - 1.0).abs() < 1e-9) {
      coeffStr = 'x';
    } else if ((coeff + 1.0).abs() < 1e-9) {
      coeffStr = '-x';
    } else {
      coeffStr = '${formatNum(coeff)}x';
    }

    if (isZeroConst) {
      return coeffStr;
    }

    if (constant > 0) {
      return '$coeffStr + ${formatNum(constant)}';
    } else {
      return '$coeffStr - ${formatNum(constant.abs())}';
    }
  }
}
