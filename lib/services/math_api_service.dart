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
        'Subtracting 6 from both sides removes the constant, then dividing by 2 isolates x — keeping the equation balanced at each step.',
        'We subtracted 6 because it is the smallest number in the equation.',
        'Dividing by 2 works because 18 is an even number.',
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
        'We divided by 3 because 3 is a prime number.',
        'Subtracting 4 from both sides eliminates the constant term, then dividing by 3 isolates x while keeping both sides equal.',
        'Adding 4 to both sides cancels out the x term.',
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
        'We added 5 because subtracting would make x negative.',
        'Multiplying both sides by 4 directly gives us x.',
        'Adding 5 to both sides cancels the -5, then dividing by 4 isolates x — each step preserves the equality.',
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
        'Subtracting 8 from both sides removes the constant, then dividing by 2 isolates x — the equation stays balanced throughout.',
        'We subtract 8 because 8 is the largest single digit.',
        'Dividing first by 2 gives us x + 4 = 10, so we should always divide first.',
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
        'We subtract 3 because 23 minus 3 is 20, a round number.',
        'Subtracting 3 from both sides removes the constant term, then dividing by 5 isolates x — each inverse operation keeps the balance.',
        'We can just guess x = 4 because 5 × 4 = 20 and 20 + 3 = 23.',
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
  /// including correct operations plus distractors. Shuffled.
  List<Map<String, dynamic>> generateOpsForProblem(BalanceScaleProblem problem) {
    final rng = Random();
    final ops = <Map<String, dynamic>>[];

    // Correct operations
    if (problem.constantLeft > 0) {
      ops.add({'op': '-', 'value': problem.constantLeft});
    } else if (problem.constantLeft < 0) {
      ops.add({'op': '+', 'value': problem.constantLeft.abs()});
    }
    ops.add({'op': '/', 'value': problem.coefficientX});

    // Distractors — wrong direction / wrong value
    if (problem.constantLeft > 0) {
      ops.add({'op': '+', 'value': problem.constantLeft}); // wrong direction
    } else {
      ops.add({'op': '-', 'value': problem.constantLeft.abs()});
    }
    ops.add({'op': '-', 'value': problem.coefficientX}); // wrong value for subtract
    ops.add({'op': '*', 'value': 2}); // tempting multiply
    ops.add({'op': '/', 'value': (problem.constantLeft.abs() > 1) ? problem.constantLeft.abs() : (rng.nextInt(3) + 2)}); // wrong divisor

    ops.shuffle(rng);
    return ops;
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
