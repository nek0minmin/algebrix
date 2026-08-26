import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:algebrix/models/quest_map_model.dart';
import 'package:algebrix/services/quest_repository.dart';
import 'package:algebrix/services/math_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String? _accountId;
  List<QuestLand> _lands = _defaultLands;
  Map<int, QuestLevelProgress> _levelProgress = {}; // keyed by levelNumber
  int _totalStars = 0;
  String? _activeLandId = 'balands';
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSeenPairadiseWelcome = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  String? get accountId => _accountId;
  List<QuestLand> get lands => List.unmodifiable(_lands);
  Map<int, QuestLevelProgress> get levelProgress =>
      Map.unmodifiable(_levelProgress);
  int get totalStars => _totalStars;
  String? get activeLandId => _activeLandId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSeenPairadiseWelcome => _hasSeenPairadiseWelcome;

  Future<void> markPairadiseWelcomeSeen() async {
    _hasSeenPairadiseWelcome = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_pairadise_welcome', true);
    } catch (_) {}
    notifyListeners();
  }

  /// The currently active land (defaults to Balands).
  QuestLand? get activeLand {
    if (_activeLandId == null) return null;
    return _lands.firstWhere(
      (l) => l.id == _activeLandId,
      orElse: () => _defaultLands.firstWhere(
        (l) => l.id == _activeLandId,
        orElse: () => _defaultLands.first,
      ),
    );
  }

  /// Number of stars earned in the active land.
  int get activeLandStars {
    int sum = 0;
    for (final progress in _levelProgress.values) {
      sum += progress.starsEarned;
    }
    return sum;
  }

  /// Whether a specific land is unlocked.
  bool isLandUnlocked(String landId) {
    if (landId == 'balands') return true;
    final land = _lands.firstWhere(
      (l) => l.id == landId,
      orElse: () => _defaultLands.firstWhere(
        (l) => l.id == landId,
        orElse: () => _defaultLands[1],
      ),
    );
    return _totalStars >= land.unlockStarsRequired;
  }

  /// Whether Pairadise (Land of Pairs) is currently unlocked (>= 25 total stars).
  bool get isPairadiseUnlocked => isLandUnlocked('pairadise');

  /// Static level definitions for the currently active land.
  List<QuestLevelDefinition> get levelDefinitions =>
      _activeLandId == 'pairadise' ? _pairadiseLevelDefs : _balandsLevelDefs;

  /// Whether a level is unlocked in the current land.
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

  /// The player's current frontier level (first uncompleted level 1-10).
  int get currentLevel {
    for (int i = 1; i <= 10; i++) {
      final progress = _levelProgress[i];
      if (progress == null || progress.starsEarned == 0) {
        return i;
      }
    }
    return 10;
  }

  /// Formatted land and level display string, e.g. "Balands IV (Level 4)".
  String get currentLandAndLevelLabel {
    final landName = activeLand?.name ?? 'Balands';
    final lvl = currentLevel;
    final roman = _toRoman(lvl);
    return '$landName $roman (Level $lvl)';
  }

  static String _toRoman(int n) {
    const map = {
      10: 'X',
      9: 'IX',
      8: 'VIII',
      7: 'VII',
      6: 'VI',
      5: 'V',
      4: 'IV',
      3: 'III',
      2: 'II',
      1: 'I',
    };
    return map[n] ?? '$n';
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Binds the current authenticated user account and loads their specific progress.
  void bindAccount(String? accountId) {
    if (_accountId == accountId) return;
    _accountId = accountId;

    if (accountId == null) {
      _levelProgress = {};
      _totalStars = 0;
      _activeLandId = 'balands';
      notifyListeners();
      return;
    }

    unawaited(loadQuestMap());
  }

  /// Load all lands and progress for the first (or given) land.
  Future<void> loadQuestMap({String? landId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final targetLand = landId ?? _activeLandId ?? 'balands';

    try {
      final fetchedLands = await _repository.fetchAllLands();
      final landMap = {for (final l in _defaultLands) l.id: l};
      for (final l in fetchedLands) {
        landMap[l.id] = l;
      }
      _lands = landMap.values.toList();
      _activeLandId = targetLand;
      _totalStars = await _repository.fetchTotalStars();

      try {
        final prefs = await SharedPreferences.getInstance();
        _hasSeenPairadiseWelcome =
            prefs.getBool('has_seen_pairadise_welcome') ?? false;
      } catch (_) {}

      final progressList = await _repository.fetchLandProgress(targetLand);
      _levelProgress = {
        for (final p in progressList) p.levelNumber: p,
      };
    } catch (e) {
      if (_lands.isEmpty) _lands = _defaultLands;
      _activeLandId = targetLand;
      _errorMessage = 'Failed to load quest map: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switch the active game world (e.g. from 'balands' to 'pairadise').
  Future<void> switchLand(String landId) async {
    if (_activeLandId == landId) return;
    await loadQuestMap(landId: landId);
  }

  /// Submit the result of completing a level.
  ///
  /// Calculates stars using the combined rubric or custom stars, and persists the best score.
  Future<int> submitLevelResult({
    String? landId,
    required int levelNumber,
    required int moveCount,
    required int optimalMoves,
    required bool reasoningPassed,
    int? starsEarned,
  }) async {
    final effectiveLandId = landId ?? _activeLandId ?? 'balands';
    final withinMoves = moveCount <= optimalMoves;
    int stars = starsEarned ?? (
      (withinMoves && reasoningPassed)
          ? 3
          : (withinMoves || reasoningPassed)
              ? 2
              : 1
    );

    try {
      await _repository.saveLevelResult(
        landId: effectiveLandId,
        levelNumber: levelNumber,
        starsEarned: stars,
        moveCount: moveCount,
        reasoningPassed: reasoningPassed,
      );

      // Update local state if active land matches
      if (_activeLandId == effectiveLandId) {
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
          landId: effectiveLandId,
          levelNumber: levelNumber,
          starsEarned: bestStars,
          bestMoves: bestMoves,
          reasoningPassed: bestReasoning,
          completedAt: DateTime.now().toUtc(),
        );
      }

      // Refresh total stars across all lands
      try {
        _totalStars = await _repository.fetchTotalStars();
      } catch (_) {
        int sum = 0;
        for (final p in _levelProgress.values) {
          sum += p.starsEarned;
        }
        _totalStars = sum;
      }
    } catch (e) {
      // Silently handle persistence errors — local state is still updated
      _levelProgress[levelNumber] = QuestLevelProgress(
        userId: '',
        landId: effectiveLandId,
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
  // Static Fallback Seed Lands
  // ---------------------------------------------------------------------------

  static const List<QuestLand> _defaultLands = [
    QuestLand(
      id: 'balands',
      name: 'Balands',
      subtitle: 'The Land of Balancing',
      sortOrder: 1,
      totalLevels: 10,
      unlockStarsRequired: 0,
    ),
    QuestLand(
      id: 'pairadise',
      name: 'Pairadise',
      subtitle: 'The Land of Pairs',
      sortOrder: 2,
      totalLevels: 10,
      unlockStarsRequired: 25,
    ),
  ];

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

  // ---------------------------------------------------------------------------
  // Static Level Definitions for Pairadise (The Land of Pairs)
  // ---------------------------------------------------------------------------

  static const List<QuestLevelDefinition> _pairadiseLevelDefs = [
    QuestLevelDefinition(
      levelNumber: 1,
      difficulty: 1,
      description: 'Twin Introductions',
    ),
    QuestLevelDefinition(
      levelNumber: 2,
      difficulty: 2,
      description: 'Simple Pairs',
    ),
    QuestLevelDefinition(
      levelNumber: 3,
      difficulty: 3,
      description: 'Eliminate Suspects',
    ),
    QuestLevelDefinition(
      levelNumber: 4,
      difficulty: 4,
      description: 'Narrow the Search',
    ),
    QuestLevelDefinition(
      levelNumber: 5,
      difficulty: 5,
      description: 'Substitution Swap',
    ),
    QuestLevelDefinition(
      levelNumber: 6,
      difficulty: 6,
      description: 'Twin Variables',
    ),
    QuestLevelDefinition(
      levelNumber: 7,
      difficulty: 7,
      description: 'Dual Step Pairs',
    ),
    QuestLevelDefinition(
      levelNumber: 8,
      difficulty: 8,
      description: 'Equation Stacking',
    ),
    QuestLevelDefinition(
      levelNumber: 9,
      difficulty: 9,
      description: 'Advanced Cancelation',
    ),
    QuestLevelDefinition(
      levelNumber: 10,
      difficulty: 10,
      description: 'The Twin Gate',
    ),
  ];
}
