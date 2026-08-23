import 'package:algebrix/models/quest_map_model.dart';
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

/// Supabase-backed implementation of [QuestRepository].
class SupabaseQuestRepository implements QuestRepository {
  SupabaseQuestRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<QuestLand>> fetchAllLands() async {
    return _withRetry(() async {
      final rows = await _client
          .from('quest_lands')
          .select()
          .order('sort_order', ascending: true);

      return rows.map((row) => QuestLand.fromJson(row)).toList();
    });
  }

  @override
  Future<List<QuestLevelProgress>> fetchLandProgress(String landId) async {
    final userId = _requireAuthenticatedUser();

    return _withRetry(() async {
      final rows = await _client
          .from('quest_level_progress')
          .select()
          .eq('user_id', userId)
          .eq('land_id', landId)
          .order('level_number', ascending: true);

      return rows.map((row) => QuestLevelProgress.fromJson(row)).toList();
    });
  }

  @override
  Future<int> fetchTotalStars() async {
    final userId = _requireAuthenticatedUser();

    return _withRetry(() async {
      final rows = await _client
          .from('quest_level_progress')
          .select('stars_earned')
          .eq('user_id', userId);

      int total = 0;
      for (final row in rows) {
        total += (row['stars_earned'] as num).toInt();
      }
      return total;
    });
  }

  @override
  Future<void> saveLevelResult({
    required String landId,
    required int levelNumber,
    required int starsEarned,
    required int moveCount,
    required bool reasoningPassed,
  }) async {
    final userId = _requireAuthenticatedUser();

    return _withRetry(() async {
      // Fetch existing progress for this level (if any).
      final existing = await _client
          .from('quest_level_progress')
          .select('id, stars_earned, best_moves, reasoning_passed')
          .eq('user_id', userId)
          .eq('land_id', landId)
          .eq('level_number', levelNumber)
          .maybeSingle();

      if (existing == null) {
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
        final oldStars = (existing['stars_earned'] as num).toInt();
        final oldBestMoves = existing['best_moves'] as int?;
        final oldReasoning = existing['reasoning_passed'] as bool;

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
              .eq('id', existing['id'] as String);
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers (same patterns as SupabaseProgressRepository)
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

  String _requireAuthenticatedUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('An authenticated account is required.');
    }
    return user.id;
  }
}
