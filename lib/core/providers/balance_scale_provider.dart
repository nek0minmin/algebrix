import 'package:flutter/foundation.dart';
import 'package:algebrix/services/math_api_service.dart';

class BalanceScaleStep {
  const BalanceScaleStep({
    required this.leftBefore,
    required this.rightBefore,
    required this.leftAfter,
    required this.rightAfter,
    required this.operationText,
    required this.providerUsed,
  });

  final String leftBefore;
  final String rightBefore;
  final String leftAfter;
  final String rightAfter;
  final String operationText;
  final String providerUsed;
}

class BalanceScaleProvider extends ChangeNotifier {
  BalanceScaleProvider({MathApiService? apiService})
      : _apiService = apiService ?? MathApiService() {
    initNewProblem();
  }

  final MathApiService _apiService;

  BalanceScaleProblem? _currentProblem;
  String _leftExpr = '';
  String _rightExpr = '';
  List<BalanceScaleStep> _history = [];
  bool _isLoading = false;
  bool _isSolved = false;
  String _providerUsed = 'MathJS API (HTTP POST)';
  String? _errorMessage;
  int _xpEarned = 0;

  BalanceScaleProblem? get currentProblem => _currentProblem;
  String get leftExpr => _leftExpr;
  String get rightExpr => _rightExpr;
  List<BalanceScaleStep> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  bool get isSolved => _isSolved;
  String get providerUsed => _providerUsed;
  String? get errorMessage => _errorMessage;
  int get xpEarned => _xpEarned;

  /// Returns scale tilt angle in radians:
  /// 0.0 = Balanced horizontal
  /// Negative angle (-0.14 rad) = Left side heavier (Left tilts down)
  /// Positive angle (+0.14 rad) = Right side heavier (Right tilts down)
  double get tiltAngle {
    if (_currentProblem == null) return 0.0;
    final targetX = _currentProblem!.targetX;

    final leftWeight = _evaluateExprWeight(_leftExpr, targetX);
    final rightWeight = _evaluateExprWeight(_rightExpr, targetX);

    final diff = leftWeight - rightWeight;
    if (diff.abs() < 0.01) return 0.0;

    return diff > 0 ? -0.14 : 0.14;
  }

  bool get isCurrentlyBalanced => tiltAngle == 0.0;

  double _evaluateExprWeight(String expr, int targetX) {
    var cleaned = expr.replaceAll(' ', '').toLowerCase();
    if (cleaned == 'x') return targetX.toDouble();

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\d+)x'),
      (match) => '${int.parse(match.group(1)!) * targetX}',
    );
    cleaned = cleaned.replaceAll('x', '$targetX');

    double total = 0.0;
    final matches = RegExp(r'([\+\-]?\d+)').allMatches(cleaned);
    for (final m in matches) {
      total += double.tryParse(m.group(0) ?? '0') ?? 0;
    }
    return total == 0 ? 1.0 : total;
  }

  void initNewProblem() {
    final nextProb = _apiService.getRandomProblem(currentId: _currentProblem?.id);
    _currentProblem = nextProb;
    _leftExpr = nextProb.leftExpr;
    _rightExpr = nextProb.rightExpr;
    _history = [];
    _isLoading = false;
    _isSolved = false;
    _errorMessage = null;
    _xpEarned = 0;
    notifyListeners();
  }

  Future<void> applyOperation(String op, num val, {String targetSide = 'both'}) async {
    if (_isSolved || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.evaluateScaleOperation(
        leftExpr: _leftExpr,
        rightExpr: _rightExpr,
        op: op,
        value: val,
        targetSide: targetSide,
      );

      final valStr = val.toString().replaceAll('.0', '');
      final targetLabel = targetSide == 'both'
          ? 'both sides'
          : (targetSide == 'left' ? 'left side' : 'right side');
      final opText = '$op $valStr ($targetLabel)';

      _history.add(
        BalanceScaleStep(
          leftBefore: _leftExpr,
          rightBefore: _rightExpr,
          leftAfter: res.leftSimplified,
          rightAfter: res.rightSimplified,
          operationText: opText,
          providerUsed: res.providerUsed,
        ),
      );

      _leftExpr = res.leftSimplified;
      _rightExpr = res.rightSimplified;
      _providerUsed = res.providerUsed;

      _checkIfSolved();
    } catch (e) {
      _errorMessage = 'Failed to evaluate operation: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _checkIfSolved() {
    if (_currentProblem == null) return;
    final targetStr = _currentProblem!.targetX.toString();

    final isLeftX = _leftExpr.trim().toLowerCase() == 'x';
    final isRightTarget = _rightExpr.trim() == targetStr;

    final isRightX = _rightExpr.trim().toLowerCase() == 'x';
    final isLeftTarget = _leftExpr.trim() == targetStr;

    if ((isLeftX && isRightTarget) || (isRightX && isLeftTarget)) {
      _isSolved = true;
      _xpEarned = 20;
    }
  }

  void resetCurrentProblem() {
    if (_currentProblem == null) return;
    _leftExpr = _currentProblem!.leftExpr;
    _rightExpr = _currentProblem!.rightExpr;
    _history = [];
    _isSolved = false;
    _errorMessage = null;
    _xpEarned = 0;
    notifyListeners();
  }
}
