import 'package:algebrix/models/pairadise_problem.dart';

/// Service that provides static problem definitions for all Pairadise levels.
///
/// Progressive 10-level structure:
/// - Levels 1–2: Discovery (Experiment freely, both clues must agree)
/// - Level 3: Reasoning Checkpoint ("Why wasn't a one-clue pair enough?")
/// - Levels 4–5: More difficult pair deduction / substitution
/// - Level 6: Reasoning Checkpoint (Substitution prediction)
/// - Levels 7–9: Formal solving strategies (Substitution & Elimination)
/// - Level 10: The Twin Gate (Unrestricted boss challenge)
class PairadiseProblemService {
  const PairadiseProblemService();

  /// Returns the problem definition for the given level number (1–10).
  ///
  /// Throws [ArgumentError] if the level number is out of range.
  PairadiseProblem getLevelProblem(int levelNumber) {
    if (levelNumber < 1 || levelNumber > _levelProblems.length) {
      throw ArgumentError(
        'Pairadise level $levelNumber is out of range (1–${_levelProblems.length})',
      );
    }
    return _levelProblems[levelNumber - 1];
  }

  /// Whether the given level number has a playable mechanic implemented.
  bool isLevelPlayable(int levelNumber) {
    if (levelNumber < 1 || levelNumber > _levelProblems.length) return false;
    final problem = _levelProblems[levelNumber - 1];
    return problem.mechanic == PairadiseMechanic.discovery ||
        problem.mechanic == PairadiseMechanic.elimination;
  }

  // ---------------------------------------------------------------------------
  // Static Level Problem Definitions
  // ---------------------------------------------------------------------------

  static const List<PairadiseProblem> _levelProblems = [
    // =========================================================================
    // Level 1: Twin Introductions (Discovery)
    //
    // Experiment freely. Teaches "both clues must agree."
    // 8 responsive choices including negative values.
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l1',
      levelNumber: 1,
      mechanic: PairadiseMechanic.discovery,
      clue1: 'x + y = 7',
      clue2: 'x - y = 1',
      solutionX: 4,
      solutionY: 3,
      candidateValues: [-2, -1, 1, 2, 3, 4, 5, 6],
      optimalMoves: 1,
      hasReasoningCheckpoint: false,
      introDialogue:
          'Welcome to Pairadise! 🌴\n\nHere, we discover mystery pairs — two values that satisfy TWO clues at once!\n\nDrag values into 💜 x and 🩵 y, then test your pair!',
      hintDialogue:
          'Try x = 4. Does 4 + y = 7? What must y be? Now check: does 4 - y = 1?',
    ),

    // =========================================================================
    // Level 2: Simple Pairs (Discovery)
    //
    // Experiment freely. Reinforces relationship reasoning.
    // 8 responsive choices including negative values.
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l2',
      levelNumber: 2,
      mechanic: PairadiseMechanic.discovery,
      clue1: 'x + y = 10',
      clue2: 'x - y = 2',
      solutionX: 6,
      solutionY: 4,
      candidateValues: [-3, -1, 2, 3, 4, 5, 6, 8],
      optimalMoves: 1,
      hasReasoningCheckpoint: false,
      introDialogue:
          'Another mystery pair awaits! 🔍\n\nRemember: one clue isn\'t enough — you need BOTH clues to find the exact pair!',
      hintDialogue:
          'If x - y = 2, then x is 2 more than y. What pair adds up to 10 with x being 2 more?',
    ),

    // =========================================================================
    // Level 3: Eliminate Suspects (Elimination + Conceptual Checkpoint)
    //
    // Conceptual checkpoint: Tests WHY one clue is not enough.
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l3',
      levelNumber: 3,
      mechanic: PairadiseMechanic.elimination,
      clue1: 'x + y = 8',
      clue2: 'x - y = 2',
      solutionX: 5,
      solutionY: 3,
      candidatePairs: [
        CandidatePair(x: 2, y: 6),
        CandidatePair(x: 3, y: 5),
        CandidatePair(x: 4, y: 4),
        CandidatePair(x: 5, y: 3),
        CandidatePair(x: 6, y: 2),
        CandidatePair(x: 7, y: 1),
      ],
      optimalMoves: 5,
      hasReasoningCheckpoint: true,
      reasoningQuestion: 'Why wasn\'t x = 6, y = 2 the mystery pair?',
      reasoningOptions: [
        'The values are too large for the puzzle.',
        'It satisfies only one clue (6 + 2 = 8, but 6 - 2 = 4 ≠ 2).',
        'In algebra, x must always be smaller than y.',
        'y cannot be less than 3.',
      ],
      correctReasoningIndex: 1,
      introDialogue:
          'Detective time! 🔎\n\nAll these pairs satisfy Clue 1. But which one ALSO satisfies Clue 2?\n\nCross out the imposters!',
      hintDialogue:
          'Check each pair against x - y = 2. For (2, 6): 2 - 6 = -4 ≠ 2, so cross it out!',
    ),

    // =========================================================================
    // Level 4: Narrow the Search (Elimination)
    //
    // Harder elimination with coefficient. Pure puzzle celebration upon solving.
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l4',
      levelNumber: 4,
      mechanic: PairadiseMechanic.elimination,
      clue1: 'x + y = 12',
      clue2: '2x - y = 3',
      solutionX: 5,
      solutionY: 7,
      candidatePairs: [
        CandidatePair(x: 2, y: 10),
        CandidatePair(x: 3, y: 9),
        CandidatePair(x: 4, y: 8),
        CandidatePair(x: 5, y: 7),
        CandidatePair(x: 6, y: 6),
        CandidatePair(x: 7, y: 5),
      ],
      optimalMoves: 5,
      hasReasoningCheckpoint: false,
      introDialogue:
          'This time, Clue 2 has a coefficient! 🧮\n\n2x - y = 3 means we multiply x by 2 before subtracting y.\n\nEliminate the pairs that don\'t work!',
      hintDialogue:
          'For each pair, compute 2×x - y and check if it equals 3. For (3, 9): 2(3) - 9 = -3 ≠ 3.',
    ),

    // =========================================================================
    // Level 5: Substitution Swap (Discovery)
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l5',
      levelNumber: 5,
      mechanic: PairadiseMechanic.discovery,
      clue1: 'y = x + 2',
      clue2: 'x + y = 8',
      solutionX: 3,
      solutionY: 5,
      candidateValues: [-3, -1, 1, 2, 3, 4, 5, 7],
      optimalMoves: 1,
      hasReasoningCheckpoint: false,
      introDialogue:
          'Clue 1 tells us that y is 2 more than x (y = x + 2)! 🔄\n\nFind the mystery values for x and y that satisfy BOTH clues!',
      hintDialogue:
          'If y = x + 2, plug it into x + y = 8. Then x + (x + 2) = 8, so 2x + 2 = 8.',
    ),

    // =========================================================================
    // Level 6: Twin Variables (Elimination + Reasoning Checkpoint)
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l6',
      levelNumber: 6,
      mechanic: PairadiseMechanic.elimination,
      clue1: 'x = 2y - 1',
      clue2: 'x + y = 8',
      solutionX: 5,
      solutionY: 3,
      candidatePairs: [
        CandidatePair(x: 1, y: 7),
        CandidatePair(x: 3, y: 5),
        CandidatePair(x: 5, y: 3),
        CandidatePair(x: 7, y: 1),
        CandidatePair(x: 9, y: -1),
      ],
      optimalMoves: 4,
      hasReasoningCheckpoint: true,
      reasoningQuestion:
          'When substituting x = 2y - 1 into x + y = 8, what single-variable equation do we get?',
      reasoningOptions: [
        '(2y - 1) + y = 8 (which simplifies to 3y - 1 = 8)',
        '2y - 1 + 8 = y',
        'x + (2y - 1) = 8 with two variables remaining',
      ],
      correctReasoningIndex: 0,
      introDialogue:
          'Detective challenge! 🔎\n\nAll candidate pairs add up to 8. But only ONE satisfies x = 2y - 1!\n\nCross out the imposters!',
      hintDialogue:
          'For each pair, calculate 2y - 1 and see if it equals x. For (3, 5): 2(5) - 1 = 9 ≠ 3.',
    ),

    // =========================================================================
    // Level 7: Dual Step Pairs (Discovery)
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l7',
      levelNumber: 7,
      mechanic: PairadiseMechanic.discovery,
      clue1: 'y = 3x - 4',
      clue2: '2x + y = 11',
      solutionX: 3,
      solutionY: 5,
      candidateValues: [-4, -2, 1, 2, 3, 4, 5, 8],
      optimalMoves: 1,
      hasReasoningCheckpoint: false,
      introDialogue:
          'Dual step pairs! ⚡\n\nClue 1 has multiplication and subtraction: y = 3x - 4.\n\nFind the mystery x and y that satisfy both clues!',
      hintDialogue:
          'Try x = 3. What is y = 3(3) - 4? Then test: does 2(3) + 5 = 11?',
    ),

    // =========================================================================
    // Level 8: Equation Stacking (Elimination)
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l8',
      levelNumber: 8,
      mechanic: PairadiseMechanic.elimination,
      clue1: 'x + y = 10',
      clue2: 'x - y = 4',
      solutionX: 7,
      solutionY: 3,
      candidatePairs: [
        CandidatePair(x: 4, y: 6),
        CandidatePair(x: 5, y: 5),
        CandidatePair(x: 6, y: 4),
        CandidatePair(x: 7, y: 3),
        CandidatePair(x: 8, y: 2),
        CandidatePair(x: 9, y: 1),
      ],
      optimalMoves: 5,
      hasReasoningCheckpoint: false,
      introDialogue:
          'Stack the equations! 💥\n\nWhen +y and -y meet, they cancel out!\n\nEliminate the candidate pairs that don\'t satisfy x - y = 4.',
      hintDialogue:
          'For each pair, subtract y from x. For (6, 4): 6 - 4 = 2 ≠ 4, so eliminate it!',
    ),

    // =========================================================================
    // Level 9: Advanced Cancelation (Discovery)
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l9',
      levelNumber: 9,
      mechanic: PairadiseMechanic.discovery,
      clue1: '2x + y = 13',
      clue2: '2x - y = 7',
      solutionX: 5,
      solutionY: 3,
      candidateValues: [-2, -1, 1, 2, 3, 4, 5, 8],
      optimalMoves: 1,
      hasReasoningCheckpoint: false,
      introDialogue:
          'Both clues have 2x! ⚡\n\nAdding both equations cancels +y and -y, giving 4x = 20.\n\nFind the values for x and y!',
      hintDialogue:
          'If 4x = 20, then x = 5. Now plug x = 5 into 2x + y = 13 to find y!',
    ),

    // =========================================================================
    // Level 10: The Twin Gate (Elimination Boss Challenge)
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l10',
      levelNumber: 10,
      mechanic: PairadiseMechanic.elimination,
      clue1: '2x + y = 11',
      clue2: 'x - y = 1',
      solutionX: 4,
      solutionY: 3,
      candidatePairs: [
        CandidatePair(x: 1, y: 9),
        CandidatePair(x: 2, y: 7),
        CandidatePair(x: 3, y: 5),
        CandidatePair(x: 4, y: 3),
        CandidatePair(x: 5, y: 1),
        CandidatePair(x: 6, y: -1),
      ],
      optimalMoves: 5,
      hasReasoningCheckpoint: false,
      introDialogue:
          '🔐 THE TWIN GATE — FINAL CHALLENGE!\n\nAll candidate pairs satisfy 2x + y = 11.\n\nEliminate the imposters to unlock the Twin Summit!',
      hintDialogue:
          'Check each pair against x - y = 1. Only (4, 3) gives 4 - 3 = 1!',
    ),
  ];
}
