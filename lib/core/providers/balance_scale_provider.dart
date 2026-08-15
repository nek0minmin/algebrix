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

  // Reasoning check state
  bool _reasoningPassed = false;
  bool _showReasoningCheck = false;

  // Dynamic operation chips for the current problem
  List<Map<String, dynamic>> _dynamicOps = [];

  BalanceScaleProblem? get currentProblem => _currentProblem;
  String get leftExpr => _leftExpr;
  String get rightExpr => _rightExpr;
  List<BalanceScaleStep> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  bool get isSolved => _isSolved;
  String get providerUsed => _providerUsed;
  String? get errorMessage => _errorMessage;
  int get xpEarned => _xpEarned;
  bool get reasoningPassed => _reasoningPassed;
  bool get showReasoningCheck => _showReasoningCheck;
  List<Map<String, dynamic>> get dynamicOps => List.unmodifiable(_dynamicOps);

  /// Number of moves (operations applied) so far.
  int get moveCount => _history.length;

  /// Optimal number of moves for the current problem.
  int get optimalMoves => _currentProblem?.optimalMoves ?? 2;

  /// Star rating based on moves vs optimal.
  /// 3★ = solved in optimal moves or fewer
  /// 2★ = solved in optimal + 1 or + 2 moves
  /// 1★ = solved in more than optimal + 2 moves
  int get starRating {
    if (!_isSolved) return 0;
    if (moveCount <= optimalMoves) return 3;
    if (moveCount <= optimalMoves + 2) return 2;
    return 1;
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
    _reasoningPassed = false;
    _showReasoningCheck = false;
    _dynamicOps = _apiService.generateOpsForProblem(nextProb);
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
      // Award XP based on star rating
      switch (starRating) {
        case 3:
          _xpEarned = 30;
          break;
        case 2:
          _xpEarned = 20;
          break;
        default:
          _xpEarned = 10;
      }
      // Show reasoning check instead of immediate celebration
      _showReasoningCheck = true;
    }
  }

  /// Called when user selects a reasoning option.
  /// Returns true if the answer was correct.
  bool submitReasoningAnswer(int selectedIndex) {
    if (_currentProblem == null) return false;
    final isCorrect = selectedIndex == _currentProblem!.correctReasoningIndex;
    if (isCorrect) {
      _reasoningPassed = true;
      _showReasoningCheck = false;
    }
    notifyListeners();
    return isCorrect;
  }

  /// Skip reasoning (still lets them proceed but no bonus).
  void skipReasoning() {
    _showReasoningCheck = false;
    _reasoningPassed = false;
    notifyListeners();
  }

  void resetCurrentProblem() {
    if (_currentProblem == null) return;
    _leftExpr = _currentProblem!.leftExpr;
    _rightExpr = _currentProblem!.rightExpr;
    _history = [];
    _isSolved = false;
    _errorMessage = null;
    _xpEarned = 0;
    _reasoningPassed = false;
    _showReasoningCheck = false;
    notifyListeners();
  }
}
