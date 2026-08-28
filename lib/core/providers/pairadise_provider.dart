import 'package:flutter/foundation.dart';
import 'package:algebrix/models/pairadise_problem.dart';
import 'package:algebrix/services/pairadise_problem_service.dart';

/// A single recorded action in the Pairadise gameplay history.
class PairadiseStep {
  const PairadiseStep({
    required this.description,
    required this.isCorrect,
    this.testedX,
    this.testedY,
    this.eliminatedPairIndex,
  });

  final String description;
  final bool isCorrect;
  final int? testedX;
  final int? testedY;
  final int? eliminatedPairIndex;
}

/// Current phase of the Pairadise gameplay loop.
enum PairadisePhase {
  /// Player is assigning values / selecting pairs.
  exploring,

  /// Animating clue 1 verification.
  clue1Checking,

  /// Animating clue 2 verification.
  clue2Checking,

  /// Both clues satisfied — mystery pair found!
  pairFound,

  /// One or both clues failed — try again.
  pairFailed,
}

/// State management for the Pairadise gameplay.
///
/// Manages the full gameplay lifecycle for Discovery (L1–2) and Elimination
/// (L3–4) mechanics, including value assignment, pair testing, clue
/// verification, move tracking, and star scoring.
class PairadiseProvider extends ChangeNotifier {
  PairadiseProvider({PairadiseProblemService? problemService})
      : _problemService = problemService ?? const PairadiseProblemService();

  final PairadiseProblemService _problemService;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  PairadiseProblem? _currentProblem;
  int? _assignedX;
  int? _assignedY;
  final Set<int> _eliminatedPairIndices = {};
  int? _confirmedPairIndex;
  final List<PairadiseStep> _history = [];
  PairadisePhase _phase = PairadisePhase.exploring;
  bool _isSolved = false;
  bool _clue1Passed = false;
  bool _clue2Passed = false;

  // Reasoning check state
  bool _reasoningPassed = false;
  bool _showReasoningCheck = false;
  int _failedTests = 0;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  PairadiseProblem? get currentProblem => _currentProblem;
  int? get assignedX => _assignedX;
  int? get assignedY => _assignedY;
  Set<int> get eliminatedPairIndices => Set.unmodifiable(_eliminatedPairIndices);
  int? get confirmedPairIndex => _confirmedPairIndex;
  List<PairadiseStep> get history => List.unmodifiable(_history);
  PairadisePhase get phase => _phase;
  bool get isSolved => _isSolved;
  bool get clue1Passed => _clue1Passed;
  bool get clue2Passed => _clue2Passed;
  bool get reasoningPassed => _reasoningPassed;
  bool get showReasoningCheck => _showReasoningCheck;
  int get failedTests => _failedTests;

  /// Number of moves (tested pairs + eliminations) so far.
  int get moveCount => _history.length;

  /// Optimal number of moves for the current problem.
  int get optimalMoves => _currentProblem?.optimalMoves ?? 2;

  /// Whether both x and y slots are filled (Discovery mechanic).
  bool get isPairReady => _assignedX != null && _assignedY != null;

  /// Whether the level mechanic is playable (L1–4 for now).
  bool get isLevelPlayable {
    if (_currentProblem == null) return false;
    return _currentProblem!.mechanic == PairadiseMechanic.discovery ||
        _currentProblem!.mechanic == PairadiseMechanic.elimination;
  }

  /// Number of remaining non-eliminated candidate pairs (Elimination mechanic).
  int get remainingPairCount {
    if (_currentProblem == null) return 0;
    return _currentProblem!.candidatePairs.length -
        _eliminatedPairIndices.length;
  }

  /// Whether the current problem has a conceptual reasoning checkpoint.
  bool get hasReasoningCheckpoint =>
      _currentProblem?.hasReasoningCheckpoint ?? false;

  /// Star rating based on mistakes and (if present) conceptual checkpoint.
  int get starRating {
    if (!_isSolved) return 0;
    return calculateStars(_reasoningPassed);
  }

  /// Calculate stars for a given test/mistake outcome.
  ///
  /// - 3★: 1st checking + reasoning correct
  /// - 2★: After 2 checkings + reasoning correct OR 1st checking + reasoning incorrect
  /// - 1★: More than 2 checkings + reasoning incorrect
  int calculateStars(bool reasoningCorrect) {
    if (!_isSolved) return 0;
    final failed = _failedTests;

    if (_currentProblem?.hasReasoningCheckpoint == true) {
      if (failed == 0 && reasoningCorrect) return 3;
      if (failed <= 1 && reasoningCorrect) return 2;
      if (failed == 0 && !reasoningCorrect) return 2;
      if (failed >= 2 && reasoningCorrect) return 2;
      return 1;
    } else {
      if (failed == 0) return 3;
      if (failed <= 1) return 2;
      return 1;
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Loads the problem definition for the given level number.
  void initLevelProblem(int levelNumber) {
    _currentProblem = _problemService.getLevelProblem(levelNumber);
    _resetState();
    notifyListeners();
  }

  /// Resets gameplay state without changing the current problem.
  void resetCurrentProblem() {
    _resetState();
    notifyListeners();
  }

  /// Assigns a value to the x slot (Discovery mechanic).
  void assignX(int value) {
    if (_isSolved) return;
    if (_phase == PairadisePhase.clue1Checking ||
        _phase == PairadisePhase.clue2Checking) {
      return;
    }
    _phase = PairadisePhase.exploring;
    _clue1Passed = false;
    _clue2Passed = false;
    _assignedX = value == 0 ? null : value;
    notifyListeners();
  }

  /// Assigns a value to the y slot (Discovery mechanic).
  void assignY(int value) {
    if (_isSolved) return;
    if (_phase == PairadisePhase.clue1Checking ||
        _phase == PairadisePhase.clue2Checking) {
      return;
    }
    _phase = PairadisePhase.exploring;
    _clue1Passed = false;
    _clue2Passed = false;
    _assignedY = value == 0 ? null : value;
    notifyListeners();
  }

  /// Clears the current value assignments without counting as a move.
  void clearAssignments() {
    if (_isSolved) return;
    if (_phase == PairadisePhase.clue1Checking ||
        _phase == PairadisePhase.clue2Checking) {
      return;
    }
    _assignedX = null;
    _assignedY = null;
    _clue1Passed = false;
    _clue2Passed = false;
    _phase = PairadisePhase.exploring;
    notifyListeners();
  }

  /// Tests the currently assigned pair against both clues (Discovery mechanic).
  ///
  /// Transitions through checking phases and records the result as a move.
  /// Returns true if the pair is the correct solution.
  Future<bool> testPair() async {
    if (_currentProblem == null || !isPairReady || _isSolved) return false;
    final x = _assignedX!;
    final y = _assignedY!;

    // Phase 1: Check clue 1
    _phase = PairadisePhase.clue1Checking;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    _clue1Passed = _currentProblem!.evaluateClue1(x, y) ?? false;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Phase 2: Check clue 2
    _phase = PairadisePhase.clue2Checking;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    _clue2Passed = _currentProblem!.evaluateClue2(x, y) ?? false;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    final isCorrect = _clue1Passed && _clue2Passed;
    _history.add(PairadiseStep(
      description: isCorrect
          ? '✅ Tested ($x, $y) — Both clues satisfied!'
          : '❌ Tested ($x, $y) — ${!_clue1Passed ? "Clue 1 failed" : "Clue 2 failed"}',
      isCorrect: isCorrect,
      testedX: x,
      testedY: y,
    ));

    if (isCorrect) {
      _isSolved = true;
      if (_currentProblem?.hasReasoningCheckpoint == true) {
        _showReasoningCheck = true;
        _reasoningPassed = false;
      } else {
        _showReasoningCheck = false;
        _reasoningPassed = true;
      }
      _phase = PairadisePhase.pairFound;
    } else {
      _failedTests++;
      _phase = PairadisePhase.pairFailed;
    }

    notifyListeners();
    return isCorrect;
  }

  /// Toggles elimination of a candidate pair by index (Elimination mechanic).
  ///
  /// - Tapping an active pair crosses it out.
  /// - Retapping an eliminated pair restores/un-crosses it.
  /// - When exactly 1 pair remains uncrossed, the app automatically checks it.
  Future<void> togglePairElimination(int pairIndex) async {
    if (_currentProblem == null || _isSolved) return;
    if (_phase == PairadisePhase.clue1Checking ||
        _phase == PairadisePhase.clue2Checking) {
      return;
    }

    if (_eliminatedPairIndices.contains(pairIndex)) {
      // Undo crossing out
      _eliminatedPairIndices.remove(pairIndex);
      _phase = PairadisePhase.exploring;
      _clue1Passed = false;
      _clue2Passed = false;
      _confirmedPairIndex = null;
      notifyListeners();
      return;
    }

    // Eliminate pair
    _eliminatedPairIndices.add(pairIndex);
    _phase = PairadisePhase.exploring;
    _clue1Passed = false;
    _clue2Passed = false;
    notifyListeners();

    // Check if exactly 1 pair remains
    if (remainingPairCount == 1) {
      final lastIndex = _currentProblem!.candidatePairs
          .asMap()
          .keys
          .firstWhere((i) => !_eliminatedPairIndices.contains(i));
      await checkRemainingCandidatePair(lastIndex);
    }
  }

  /// Backward-compatible eliminate method for tests.
  bool eliminatePair(int pairIndex) {
    if (_currentProblem == null || _isSolved) return false;
    if (_eliminatedPairIndices.contains(pairIndex)) return false;
    _eliminatedPairIndices.add(pairIndex);
    notifyListeners();
    return true;
  }

  /// Backward-compatible un-eliminate method.
  bool unEliminatePair(int pairIndex) {
    if (_currentProblem == null || _isSolved) return false;
    if (!_eliminatedPairIndices.contains(pairIndex)) return false;
    _eliminatedPairIndices.remove(pairIndex);
    _phase = PairadisePhase.exploring;
    _clue1Passed = false;
    _clue2Passed = false;
    notifyListeners();
    return true;
  }

  /// Confirms and checks a candidate pair.
  Future<bool> confirmPair(int pairIndex) =>
      checkRemainingCandidatePair(pairIndex);

  /// Checks the single remaining candidate pair against clues.
  Future<bool> checkRemainingCandidatePair(int pairIndex) async {
    if (_currentProblem == null || _isSolved) return false;
    final pair = _currentProblem!.candidatePairs[pairIndex];
    _confirmedPairIndex = pairIndex;

    // Phase 1: Check clue 1
    _phase = PairadisePhase.clue1Checking;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    _clue1Passed = _currentProblem!.evaluateClue1(pair.x, pair.y) ?? false;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    // Phase 2: Check clue 2
    _phase = PairadisePhase.clue2Checking;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    _clue2Passed = _currentProblem!.evaluateClue2(pair.x, pair.y) ?? false;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final isCorrect = _clue1Passed && _clue2Passed;
    _history.add(PairadiseStep(
      description: isCorrect
          ? '✅ Confirmed (${pair.x}, ${pair.y}) — Mystery Pair Found!'
          : '❌ Checked (${pair.x}, ${pair.y}) — Fails clue verification!',
      isCorrect: isCorrect,
      testedX: pair.x,
      testedY: pair.y,
    ));

    if (isCorrect) {
      _isSolved = true;
      if (_currentProblem?.hasReasoningCheckpoint == true) {
        _showReasoningCheck = true;
        _reasoningPassed = false;
      } else {
        _showReasoningCheck = false;
        _reasoningPassed = true;
      }
      _phase = PairadisePhase.pairFound;
    } else {
      _failedTests++;
      _phase = PairadisePhase.pairFailed;
      _confirmedPairIndex = null;
    }

    notifyListeners();
    return isCorrect;
  }

  /// Records the reasoning check result and advances to the celebration screen.
  void setReasoningResult(bool passed) {
    _reasoningPassed = passed;
    _showReasoningCheck = false;
    notifyListeners();
  }

  /// Submits the selected reasoning answer index and transitions to celebration.
  bool submitReasoningAnswer(int selectedIndex) {
    if (_currentProblem == null) return false;
    final isCorrect = selectedIndex == _currentProblem!.correctReasoningIndex;
    _reasoningPassed = isCorrect;
    _showReasoningCheck = false;
    notifyListeners();
    return isCorrect;
  }

  /// Resets the phase back to exploring after a failed attempt.
  void retryAfterFailure() {
    if (_isSolved) return;
    _phase = PairadisePhase.exploring;
    _clue1Passed = false;
    _clue2Passed = false;
    _assignedX = null;
    _assignedY = null;
    _confirmedPairIndex = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  void _resetState() {
    _assignedX = null;
    _assignedY = null;
    _eliminatedPairIndices.clear();
    _confirmedPairIndex = null;
    _history.clear();
    _phase = PairadisePhase.exploring;
    _isSolved = false;
    _clue1Passed = false;
    _clue2Passed = false;
    _reasoningPassed = false;
    _showReasoningCheck = false;
    _failedTests = 0;
  }
}
