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
    // Levels 5–7: Substitution (placeholder — mechanics coming soon)
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l5',
      levelNumber: 5,
      mechanic: PairadiseMechanic.substitution,
      clue1: 'y = x + 2',
      clue2: 'x + y = 8',
      solutionX: 3,
      solutionY: 5,
      candidateValues: [-3, -1, 1, 2, 3, 4, 5, 7],
      optimalMoves: 3,
      hasReasoningCheckpoint: false,
      introDialogue:
          'Clue 1 tells us what y equals! Can we use that in Clue 2? 🔄',
      hintDialogue:
          'y = x + 2 means wherever you see y, you can write (x + 2) instead!',
    ),

    PairadiseProblem(
      id: 'pairadise_l6',
      levelNumber: 6,
      mechanic: PairadiseMechanic.substitution,
      clue1: 'x = 2y - 1',
      clue2: 'x + y = 8',
      solutionX: 5,
      solutionY: 3,
      candidateValues: [-2, -1, 1, 2, 3, 4, 5, 7],
      optimalMoves: 3,
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
          'This time, Clue 1 tells us what x equals in terms of y! 🔄',
      hintDialogue:
          'Replace x with (2y - 1) in the second equation and simplify.',
    ),

    PairadiseProblem(
      id: 'pairadise_l7',
      levelNumber: 7,
      mechanic: PairadiseMechanic.substitution,
      clue1: 'y = 3x - 4',
      clue2: '2x + y = 11',
      solutionX: 3,
      solutionY: 5,
      candidateValues: [-4, -2, 1, 2, 3, 4, 5, 8],
      optimalMoves: 3,
      hasReasoningCheckpoint: false,
      introDialogue:
          'A trickier substitution! Can you replace y in Clue 2 using Clue 1? 🔄',
      hintDialogue:
          'y = 3x - 4, so plug that into 2x + y = 11 to get a single equation with just x.',
    ),

    // =========================================================================
    // Levels 8–9: Cancelation / Elimination Method (placeholder)
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l8',
      levelNumber: 8,
      mechanic: PairadiseMechanic.cancelation,
      clue1: 'x + y = 10',
      clue2: 'x - y = 4',
      solutionX: 7,
      solutionY: 3,
      candidateValues: [-3, -1, 2, 3, 4, 5, 7, 9],
      optimalMoves: 2,
      hasReasoningCheckpoint: false,
      introDialogue:
          'Stack the equations! When +y and -y meet... 💥 they cancel!',
      hintDialogue:
          'Add the left sides together and the right sides together. What happens to y?',
    ),

    PairadiseProblem(
      id: 'pairadise_l9',
      levelNumber: 9,
      mechanic: PairadiseMechanic.cancelation,
      clue1: '2x + y = 13',
      clue2: '2x - y = 7',
      solutionX: 5,
      solutionY: 3,
      candidateValues: [-2, -1, 1, 2, 3, 4, 5, 8],
      optimalMoves: 2,
      hasReasoningCheckpoint: false,
      introDialogue:
          'The equations share 2x! When you stack them, +y and -y will cancel! 💥',
      hintDialogue:
          'Add both equations. The +y and -y cancel, leaving just an equation with x.',
    ),

    // =========================================================================
    // Level 10: The Twin Gate — Free Choice (placeholder)
    // =========================================================================
    PairadiseProblem(
      id: 'pairadise_l10',
      levelNumber: 10,
      mechanic: PairadiseMechanic.freeChoice,
      clue1: '2x + y = 11',
      clue2: 'x - y = 1',
      solutionX: 4,
      solutionY: 3,
      candidateValues: [-3, -1, 1, 2, 3, 4, 5, 7],
      optimalMoves: 2,
      hasReasoningCheckpoint: false,
      introDialogue:
          '🔐 THE TWIN GATE\n\nTwo locks. Two unknowns. Choose your strategy!\n\n🔄 Substitute or 💥 Eliminate — it\'s your call.',
      hintDialogue:
          'From Clue 2: y = x - 1. Substitute into Clue 1: 2x + (x - 1) = 11.',
    ),
  ];
}
