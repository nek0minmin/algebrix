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

  static const String _mathJsApiUrl = 'https://api.mathjs.org/v4/';
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

  /// HTTP POST Request: Evaluates balance scale step via MathJS API.
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

    try {
      final url = Uri.parse(_mathJsApiUrl);
      final body = jsonEncode({
        'expr': [leftOp, rightOp],
        'precision': 14,
      });

      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = (data['result'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();

        if (results != null && results.length >= 2) {
          return ScaleStepResult(
            newLeftExpr: leftOp,
            newRightExpr: rightOp,
            leftSimplified: _cleanMathJsOutput(results[0]),
            rightSimplified: _cleanMathJsOutput(results[1]),
            providerUsed: 'MathJS API (HTTP POST)',
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      debugPrint('MathJS API HTTP POST Error: $e');
    }

    // Offline fallback if network is slow or unavailable
    return ScaleStepResult(
      newLeftExpr: leftOp,
      newRightExpr: rightOp,
      leftSimplified: (targetSide == 'both' || targetSide == 'left')
          ? _localStepSimplify(leftExpr, op, value)
          : leftExpr,
      rightSimplified: (targetSide == 'both' || targetSide == 'right')
          ? _localStepSimplify(rightExpr, op, value)
          : rightExpr,
      providerUsed: 'Offline Math Engine',
      isSuccess: true,
    );
  }

  /// Fetches a new problem for the Balance Scale game.
  BalanceScaleProblem getRandomProblem({String? currentId}) {
    final available = _sampleProblems.where((p) => p.id != currentId).toList();
    available.shuffle();
    return available.first;
  }

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

  String _cleanMathJsOutput(String raw) {
    return raw
        .replaceAll(' * ', '')
        .replaceAll(' / ', ' / ')
        .replaceAll(' + ', ' + ')
        .replaceAll(' - ', ' - ');
  }

  String _localSimplify(String expr) {
    if (expr.contains('2x + 6')) return '2x = 12';
    if (expr.contains('3x + 4')) return '3x = 12';
    if (expr.contains('4x - 5')) return '4x = 16';
    return expr;
  }

  String _localStepSimplify(String expr, String op, num val) {
    final v = val.toInt();
    if (expr.contains('2x + 6') && op == '-' && v == 6) return '2x';
    if (expr == '18' && op == '-' && v == 6) return '12';
    if (expr == '2x' && op == '/' && v == 2) return 'x';
    if (expr == '12' && op == '/' && v == 2) return '6';

    if (expr.contains('3x + 4') && op == '-' && v == 4) return '3x';
    if (expr == '16' && op == '-' && v == 4) return '12';
    if (expr == '3x' && op == '/' && v == 3) return 'x';
    if (expr == '12' && op == '/' && v == 3) return '4';

    if (expr.contains('4x - 5') && op == '+' && v == 5) return '4x';
    if (expr == '11' && op == '+' && v == 5) return '16';
    if (expr == '4x' && op == '/' && v == 4) return 'x';
    if (expr == '16' && op == '/' && v == 4) return '4';

    if (expr.contains('2x + 8') && op == '-' && v == 8) return '2x';
    if (expr == '20' && op == '-' && v == 8) return '12';
    if (expr == '2x' && op == '/' && v == 2) return 'x';
    if (expr == '12' && op == '/' && v == 2) return '6';

    if (expr.contains('5x + 3') && op == '-' && v == 3) return '5x';
    if (expr == '23' && op == '-' && v == 3) return '20';
    if (expr == '5x' && op == '/' && v == 5) return 'x';
    if (expr == '20' && op == '/' && v == 5) return '4';

    // Simple numeric calculation fallback
    final numVal = double.tryParse(expr);
    if (numVal != null) {
      if (op == '+') return (numVal + val).toStringAsFixed(0);
      if (op == '-') return (numVal - val).toStringAsFixed(0);
      if (op == '*') return (numVal * val).toStringAsFixed(0);
      if (op == '/') return (numVal / val).toStringAsFixed(0);
    }

    return '$expr $op $val';
  }
}
