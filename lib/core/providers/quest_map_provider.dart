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
  final Map<String, Map<int, QuestLevelProgress>> _allLandsProgress = {
    'balands': {},
    'pairadise': {},
  };
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
      final key = 'has_seen_pairadise_welcome_${_accountId ?? 'guest'}';
      await prefs.setBool(key, true);
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

  /// The player's current frontier level in the currently active land (first uncompleted level 1-10).
  int get currentLevel {
    for (int i = 1; i <= 10; i++) {
      final progress = _levelProgress[i];
      if (progress == null || progress.starsEarned == 0) {
        return i;
      }
    }
    return 10;
  }

  /// Formatted land and level display string for the active screen, e.g. "Balands IV" or "Pairadise I".
  String get currentLandAndLevelLabel {
    final landName = activeLand?.name ?? 'Balands';
    final lvl = currentLevel;
    final roman = _toRoman(lvl);
    return '$landName $roman';
  }

  /// The player's absolute furthest unlocked frontier across ALL lands (e.g. "Pairadise V" even if navigating Balands).
  String get frontierLandAndLevelLabel {
    if (isPairadiseUnlocked) {
      final pairadiseMap = _allLandsProgress['pairadise'] ?? {};
      int lvl = 10;
      for (int i = 1; i <= 10; i++) {
        final p = pairadiseMap[i];
        if (p == null || p.starsEarned == 0) {
          lvl = i;
          break;
        }
      }
      return 'Pairadise ${_toRoman(lvl)}';
    } else {
      final balandsMap = _allLandsProgress['balands'] ?? _levelProgress;
      int lvl = 10;
      for (int i = 1; i <= 10; i++) {
        final p = balandsMap[i];
        if (p == null || p.starsEarned == 0) {
          lvl = i;
          break;
        }
      }
      return 'Balands ${_toRoman(lvl)}';
    }
  }

  /// Stars earned in the player's furthest unlocked realm.
  int get frontierLandStars {
    if (isPairadiseUnlocked) {
      final pairadiseMap = _allLandsProgress['pairadise'] ?? {};
      return pairadiseMap.values.fold(0, (sum, p) => sum + p.starsEarned);
    } else {
      final balandsMap = _allLandsProgress['balands'] ?? _levelProgress;
      return balandsMap.values.fold(0, (sum, p) => sum + p.starsEarned);
    }
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

  int _accountGeneration = 0;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Binds the current authenticated user account and loads their specific progress.
  void bindAccount(String? accountId) {
    if (_accountId == accountId) return;

    _accountGeneration++;
    _accountId = accountId;
    _allLandsProgress.clear();
    _levelProgress = {};
    _totalStars = 0;
    _activeLandId = 'balands';
    _hasSeenPairadiseWelcome = false;
    _errorMessage = null;

    if (accountId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    unawaited(_hydrateQuestMap(accountId, _accountGeneration));
  }

  Future<void> _hydrateQuestMap(String accountId, int generation) async {
    await loadQuestMap();
    if (_accountId != accountId || _accountGeneration != generation) return;
  }

  /// Load all lands and progress for the first (or given) land.
  Future<void> loadQuestMap({String? landId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String targetLand = landId ?? _activeLandId ?? 'balands';
    String? savedLand;
    final accountKey = _accountId ?? 'guest';

    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenPairadiseWelcome =
          prefs.getBool('has_seen_pairadise_welcome_$accountKey') ?? false;

      savedLand = prefs.getString('saved_active_land_id_$accountKey');
      if (landId == null && savedLand != null && savedLand.isNotEmpty) {
        targetLand = savedLand;
      }
    } catch (_) {}

    try {
      final fetchedLands = await _repository.fetchAllLands();
      final landMap = {for (final l in _defaultLands) l.id: l};
      for (final l in fetchedLands) {
        landMap[l.id] = l;
      }
      _lands = landMap.values.toList();
      _totalStars = await _repository.fetchTotalStars();

      // If user has already unlocked and entered Pairadise, remember Pairadise as active land
      if (landId == null && savedLand == null && _hasSeenPairadiseWelcome && _totalStars >= 25) {
        targetLand = 'pairadise';
      }

      _activeLandId = targetLand;

      final balandsList = await _repository.fetchLandProgress('balands');
      _allLandsProgress['balands'] = {
        for (final p in balandsList) p.levelNumber: p,
      };

      if (_totalStars >= 25) {
        final pairadiseList = await _repository.fetchLandProgress('pairadise');
        _allLandsProgress['pairadise'] = {
          for (final p in pairadiseList) p.levelNumber: p,
        };
      } else {
        _allLandsProgress['pairadise'] = {};
      }

      _levelProgress = _allLandsProgress[targetLand] ?? {};
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'saved_active_land_id_${_accountId ?? 'guest'}';
      await prefs.setString(key, landId);
    } catch (_) {}
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

      final landMap = _allLandsProgress.putIfAbsent(effectiveLandId, () => {});
      final existing = landMap[levelNumber] ?? _levelProgress[levelNumber];
      final bestStars = existing != null && existing.starsEarned > stars
          ? existing.starsEarned
          : stars;
      final bestMoves = existing?.bestMoves != null &&
              existing!.bestMoves! < moveCount
          ? existing.bestMoves!
          : moveCount;
      final bestReasoning =
          reasoningPassed || (existing?.reasoningPassed ?? false);

      final updated = QuestLevelProgress(
        userId: existing?.userId ?? _accountId ?? '',
        landId: effectiveLandId,
        levelNumber: levelNumber,
        starsEarned: bestStars,
        bestMoves: bestMoves,
        reasoningPassed: bestReasoning,
        completedAt: DateTime.now().toUtc(),
      );

      landMap[levelNumber] = updated;

      if (_activeLandId == effectiveLandId) {
        _levelProgress = Map.from(landMap);
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
