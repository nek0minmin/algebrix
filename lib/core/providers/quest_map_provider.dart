import 'package:flutter/foundation.dart';
import 'package:algebrix/models/quest_map_model.dart';
import 'package:algebrix/services/quest_repository.dart';
import 'package:algebrix/services/math_api_service.dart';

/// State management for the Quest Map feature.
///
/// Manages land registry, level progress, star totals, and persistence.
class QuestMapProvider extends ChangeNotifier {
  QuestMapProvider({
    required QuestRepository repository,
    MathApiService? apiService,
  })  : _repository = repository,
        _apiService = apiService ?? MathApiService();

  final QuestRepository _repository;
  final MathApiService _apiService;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<QuestLand> _lands = [];
  Map<int, QuestLevelProgress> _levelProgress = {}; // keyed by levelNumber
  int _totalStars = 0;
  String? _activeLandId;
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<QuestLand> get lands => List.unmodifiable(_lands);
  Map<int, QuestLevelProgress> get levelProgress =>
      Map.unmodifiable(_levelProgress);
  int get totalStars => _totalStars;
  String? get activeLandId => _activeLandId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// The currently active land (null until loaded).
  QuestLand? get activeLand {
    if (_activeLandId == null) return null;
    try {
      return _lands.firstWhere((l) => l.id == _activeLandId);
    } catch (_) {
      return null;
    }
  }

  /// Number of stars earned in the active land.
  int get activeLandStars {
    int sum = 0;
    for (final progress in _levelProgress.values) {
      sum += progress.starsEarned;
    }
    return sum;
  }

  /// Static level definitions for 'Balands' (10 levels).
  List<QuestLevelDefinition> get levelDefinitions => _balandsLevelDefs;

  /// Whether a level is unlocked.
  /// Level 1 is always unlocked. Level N+1 requires level N to have ≥ 1 star.
  bool isLevelUnlocked(int levelNumber) {
    if (levelNumber <= 1) return true;
    final prevProgress = _levelProgress[levelNumber - 1];
    return prevProgress != null && prevProgress.starsEarned >= 1;
  }

  /// Stars earned for a specific level (0 if not attempted).
  int starsForLevel(int levelNumber) {
    return _levelProgress[levelNumber]?.starsEarned ?? 0;
  }

  /// Best moves for a specific level (null if not attempted).
  int? bestMovesForLevel(int levelNumber) {
    return _levelProgress[levelNumber]?.bestMoves;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Load all lands and progress for the first (or given) land.
  Future<void> loadQuestMap({String landId = 'balands'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lands = await _repository.fetchAllLands();
      _activeLandId = landId;
      _totalStars = await _repository.fetchTotalStars();

      final progressList = await _repository.fetchLandProgress(landId);
      _levelProgress = {
        for (final p in progressList) p.levelNumber: p,
      };
    } catch (e) {
      _errorMessage = 'Failed to load quest map: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit the result of completing a level.
  ///
  /// Calculates stars using the combined rubric and persists the best score.
  Future<int> submitLevelResult({
    required int levelNumber,
    required int moveCount,
    required int optimalMoves,
    required bool reasoningPassed,
  }) async {
    // Calculate stars using the combined rubric
    final withinMoves = moveCount <= optimalMoves;
    int stars;
    if (withinMoves && reasoningPassed) {
      stars = 3;
    } else if (withinMoves || reasoningPassed) {
      stars = 2;
    } else {
      stars = 1;
    }

    final landId = _activeLandId ?? 'balands';

    try {
      await _repository.saveLevelResult(
        landId: landId,
        levelNumber: levelNumber,
        starsEarned: stars,
        moveCount: moveCount,
        reasoningPassed: reasoningPassed,
      );

      // Update local state with best-score logic
      final existing = _levelProgress[levelNumber];
      final bestStars = existing != null && existing.starsEarned > stars
          ? existing.starsEarned
          : stars;
      final bestMoves = existing?.bestMoves != null &&
              existing!.bestMoves! < moveCount
          ? existing.bestMoves!
          : moveCount;
      final bestReasoning =
          reasoningPassed || (existing?.reasoningPassed ?? false);

      _levelProgress[levelNumber] = QuestLevelProgress(
        userId: existing?.userId ?? '',
        landId: landId,
        levelNumber: levelNumber,
        starsEarned: bestStars,
        bestMoves: bestMoves,
        reasoningPassed: bestReasoning,
        completedAt: DateTime.now().toUtc(),
      );

      // Recalculate total stars
      _totalStars = 0;
      for (final p in _levelProgress.values) {
        _totalStars += p.starsEarned;
      }
    } catch (e) {
      // Silently handle persistence errors — local state is still updated
      _levelProgress[levelNumber] = QuestLevelProgress(
        userId: '',
        landId: landId,
        levelNumber: levelNumber,
        starsEarned: stars,
        bestMoves: moveCount,
        reasoningPassed: reasoningPassed,
        completedAt: DateTime.now().toUtc(),
      );
    }

    notifyListeners();
    return stars;
  }

  /// Get the balance scale problem for a specific level.
  BalanceScaleProblem getLevelProblem(int levelNumber) {
    return _apiService.getLevelProblem(levelNumber);
  }

  // ---------------------------------------------------------------------------
  // Static Level Definitions for Balands
  // ---------------------------------------------------------------------------

  static const List<QuestLevelDefinition> _balandsLevelDefs = [
    QuestLevelDefinition(
      levelNumber: 1,
      difficulty: 1,
      description: 'Simple addition',
    ),
    QuestLevelDefinition(
      levelNumber: 2,
      difficulty: 2,
      description: 'Simple subtraction',
    ),
    QuestLevelDefinition(
      levelNumber: 3,
      difficulty: 3,
      description: 'Single division',
    ),
    QuestLevelDefinition(
      levelNumber: 4,
      difficulty: 4,
      description: 'Two-step equation',
    ),
    QuestLevelDefinition(
      levelNumber: 5,
      difficulty: 5,
      description: 'Two-step with subtraction',
    ),
    QuestLevelDefinition(
      levelNumber: 6,
      difficulty: 6,
      description: 'Larger coefficient',
    ),
    QuestLevelDefinition(
      levelNumber: 7,
      difficulty: 7,
      description: 'Larger numbers',
    ),
    QuestLevelDefinition(
      levelNumber: 8,
      difficulty: 8,
      description: 'Variables on both sides',
    ),
    QuestLevelDefinition(
      levelNumber: 9,
      difficulty: 9,
      description: 'Multi-step with variables',
    ),
    QuestLevelDefinition(
      levelNumber: 10,
      difficulty: 10,
      description: 'Expert challenge',
    ),
  ];
}
