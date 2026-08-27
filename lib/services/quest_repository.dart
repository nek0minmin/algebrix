import 'dart:convert';
import 'package:algebrix/models/quest_map_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persistence boundary for quest map progression data.
abstract interface class QuestRepository {
  /// Fetches all available quest lands.
  Future<List<QuestLand>> fetchAllLands();

  /// Fetches level progress for a specific land.
  Future<List<QuestLevelProgress>> fetchLandProgress(String landId);

  /// Fetches the total stars earned across all lands.
  Future<int> fetchTotalStars();

  /// Saves or updates a level result.
  ///
  /// Uses "best score wins" logic — only updates if the new star count
  /// is higher than the existing one.
  Future<void> saveLevelResult({
    required String landId,
    required int levelNumber,
    required int starsEarned,
    required int moveCount,
    required bool reasoningPassed,
  });
}

/// Supabase-backed implementation of [QuestRepository] with offline/local fallback.
class SupabaseQuestRepository implements QuestRepository {
  SupabaseQuestRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

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

  @override
  Future<List<QuestLand>> fetchAllLands() async {
    try {
      return await _withRetry(() async {
        final rows = await _client
            .from('quest_lands')
            .select()
            .order('sort_order', ascending: true);

        if (rows.isEmpty) return _defaultLands;
        return rows.map((row) => QuestLand.fromJson(row)).toList();
      });
    } catch (e) {
      debugPrint('QuestRepository fetchAllLands fallback: $e');
      return _defaultLands;
    }
  }

  @override
  Future<List<QuestLevelProgress>> fetchLandProgress(String landId) async {
    String? userId;
    try {
      userId = _client.auth.currentUser?.id;
    } catch (_) {}

    final effectiveUserId = userId ?? 'guest';

    if (userId == null) {
      return _loadLocalLandProgress(landId, userId: effectiveUserId);
    }

    try {
      final remoteList = await _withRetry(() async {
        final rows = await _client
            .from('quest_level_progress')
            .select()
            .eq('user_id', userId!)
            .eq('land_id', landId)
            .order('level_number', ascending: true);

        return rows.map((row) => QuestLevelProgress.fromJson(row)).toList();
      });

      // Remote Supabase database is canonical for this user
      await _saveLocalLandProgress(landId, remoteList, userId: effectiveUserId);
      return remoteList;
    } catch (e) {
      debugPrint('QuestRepository fetchLandProgress fallback to local: $e');
      return _loadLocalLandProgress(landId, userId: effectiveUserId);
    }
  }

  @override
  Future<int> fetchTotalStars() async {
    String? userId;
    try {
      userId = _client.auth.currentUser?.id;
    } catch (_) {}

    final effectiveUserId = userId ?? 'guest';

    if (userId == null) {
      int localTotal = 0;
      for (final land in ['balands', 'pairadise']) {
        final list = await _loadLocalLandProgress(land, userId: effectiveUserId);
        for (final p in list) {
          localTotal += p.starsEarned;
        }
      }
      return localTotal;
    }

    try {
      final remoteTotal = await _withRetry(() async {
        final rows = await _client
            .from('quest_level_progress')
            .select('stars_earned')
            .eq('user_id', userId!);

        int total = 0;
        for (final row in rows) {
          total += (row['stars_earned'] as num).toInt();
        }
        return total;
      });

      return remoteTotal;
    } catch (e) {
      debugPrint('QuestRepository fetchTotalStars fallback: $e');
      int localTotal = 0;
      for (final land in ['balands', 'pairadise']) {
        final list = await _loadLocalLandProgress(land, userId: effectiveUserId);
        for (final p in list) {
          localTotal += p.starsEarned;
        }
      }
      return localTotal;
    }
  }

  @override
  Future<void> saveLevelResult({
    required String landId,
    required int levelNumber,
    required int starsEarned,
    required int moveCount,
    required bool reasoningPassed,
  }) async {
    String? userId;
    try {
      userId = _client.auth.currentUser?.id;
    } catch (_) {}
    final effectiveUserId = userId ?? 'guest';

    // 1. Immediately persist to user-namespaced local cache
    final currentList =
        await _loadLocalLandProgress(landId, userId: effectiveUserId);
    final map = {for (final p in currentList) p.levelNumber: p};
    final existing = map[levelNumber];

    final bestStars = existing != null && existing.starsEarned > starsEarned
        ? existing.starsEarned
        : starsEarned;
    final bestMoves = existing?.bestMoves != null &&
            existing!.bestMoves! < moveCount
        ? existing.bestMoves!
        : moveCount;
    final bestReasoning =
        reasoningPassed || (existing?.reasoningPassed ?? false);

    final updated = QuestLevelProgress(
      userId: effectiveUserId,
      landId: landId,
      levelNumber: levelNumber,
      starsEarned: bestStars,
      bestMoves: bestMoves,
      reasoningPassed: bestReasoning,
      completedAt: DateTime.now().toUtc(),
    );

    map[levelNumber] = updated;
    await _saveLocalLandProgress(
      landId,
      map.values.toList(),
      userId: effectiveUserId,
    );

    // 2. Persist to Supabase if authenticated
    if (userId == null) return;

    try {
      await _withRetry(() async {
        // Fetch existing progress for this level (if any).
        final remoteExisting = await _client
            .from('quest_level_progress')
            .select('id, stars_earned, best_moves, reasoning_passed')
            .eq('user_id', userId!)
            .eq('land_id', landId)
            .eq('level_number', levelNumber)
            .maybeSingle();

        if (remoteExisting == null) {
          // First attempt at this level — insert.
          await _client.from('quest_level_progress').insert({
            'user_id': userId,
            'land_id': landId,
            'level_number': levelNumber,
            'stars_earned': starsEarned,
            'best_moves': moveCount,
            'reasoning_passed': reasoningPassed,
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          });
        } else {
          // "Best score wins" — only update if improvement.
          final oldStars = (remoteExisting['stars_earned'] as num).toInt();
          final oldBestMoves = remoteExisting['best_moves'] as int?;
          final oldReasoning = remoteExisting['reasoning_passed'] as bool;

          final newStars = starsEarned > oldStars ? starsEarned : oldStars;
          final newBestMoves = oldBestMoves == null
              ? moveCount
              : (moveCount < oldBestMoves ? moveCount : oldBestMoves);
          final newReasoning = reasoningPassed || oldReasoning;

          if (newStars != oldStars ||
              newBestMoves != oldBestMoves ||
              newReasoning != oldReasoning) {
            await _client
                .from('quest_level_progress')
                .update({
                  'stars_earned': newStars,
                  'best_moves': newBestMoves,
                  'reasoning_passed': newReasoning,
                  'completed_at': DateTime.now().toUtc().toIso8601String(),
                })
                .eq('id', remoteExisting['id'] as String);
          }
        }
      });
    } catch (e) {
      debugPrint('QuestRepository saveLevelResult Supabase error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Local Cache Helpers (SharedPreferences)
  // ---------------------------------------------------------------------------

  Future<List<QuestLevelProgress>> _loadLocalLandProgress(
    String landId, {
    String? userId,
  }) async {
    try {
      final effectiveUserId =
          userId ?? _client.auth.currentUser?.id ?? 'guest';
      final prefs = await SharedPreferences.getInstance();
      final key = 'quest_progress_${effectiveUserId}_$landId';
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) =>
              QuestLevelProgress.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('QuestRepository _loadLocalLandProgress error: $e');
      return [];
    }
  }

  Future<void> _saveLocalLandProgress(
    String landId,
    List<QuestLevelProgress> progressList, {
    String? userId,
  }) async {
    try {
      final effectiveUserId =
          userId ?? _client.auth.currentUser?.id ?? 'guest';
      final prefs = await SharedPreferences.getInstance();
      final key = 'quest_progress_${effectiveUserId}_$landId';
      final raw = jsonEncode(progressList.map((p) => p.toJson()).toList());
      await prefs.setString(key, raw);
    } catch (e) {
      debugPrint('QuestRepository _saveLocalLandProgress error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<T> _withRetry<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await action();
      } catch (error) {
        final isJwtSkew = _isClockSkewError(error);
        if (attempt < maxAttempts &&
            (isJwtSkew || _isTransientNetworkError(error))) {
          final delayMs = isJwtSkew ? 750 * attempt : 400 * attempt;
          await Future<void>.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        rethrow;
      }
    }
  }

  bool _isClockSkewError(Object error) {
    final str = error.toString().toLowerCase();
    return str.contains('jwt issued at future') ||
        str.contains('pgrst303') ||
        (error is PostgrestException && error.code == 'PGRST303');
  }

  bool _isTransientNetworkError(Object error) {
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('connection closed') ||
        str.contains('clientexception') ||
        str.contains('timeout');
  }
}
