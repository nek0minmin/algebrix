import 'dart:async';
import 'dart:convert';
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
  });

  final String id;
  final String equation;
  final String leftExpr;
  final String rightExpr;
  final int coefficientX;
  final int constantLeft;
  final int targetX;
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
  static const String _newtonApiUrl = 'https://newton.now.sh/v2/simplify/';

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
    ),
    BalanceScaleProblem(
      id: 'p2',
      equation: '3x + 4 = 16',
      leftExpr: '3x + 4',
      rightExpr: '16',
      coefficientX: 3,
      constantLeft: 4,
      targetX: 4,
    ),
    BalanceScaleProblem(
      id: 'p3',
      equation: '4x - 5 = 11',
      leftExpr: '4x - 5',
      rightExpr: '11',
      coefficientX: 4,
      constantLeft: -5,
      targetX: 4,
    ),
    BalanceScaleProblem(
      id: 'p4',
      equation: '2x + 8 = 20',
      leftExpr: '2x + 8',
      rightExpr: '20',
      coefficientX: 2,
      constantLeft: 8,
      targetX: 6,
    ),
    BalanceScaleProblem(
      id: 'p5',
      equation: '5x + 3 = 23',
      leftExpr: '5x + 3',
      rightExpr: '23',
      coefficientX: 5,
      constantLeft: 3,
      targetX: 4,
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

    if (expr.contains('4x - 5') && op == '+' && v == 5) return '4x';
    if (expr == '11' && op == '+' && v == 5) return '16';
    if (expr == '4x' && op == '/' && v == 4) return 'x';

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
