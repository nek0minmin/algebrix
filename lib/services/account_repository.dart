import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persistence boundary for learner-editable account settings.
///
/// Covers only what the learner owns: display name, avatar, and deleting the
/// account outright. XP, level, and streak stay server-owned — the
/// `profiles_prepare_update` trigger pins them even if this client tried.
abstract interface class AccountRepository {
  /// Updates the learner's display name and avatar.
  ///
  /// [avatarKey] is a preset slug from `AppAvatars`, or `null` to clear it.
  Future<void> updateAccount({required String name, String? avatarKey});

  /// Permanently deletes the account and every row it owns.
  Future<void> deleteAccount();
}

/// Supabase-backed implementation of [AccountRepository].
class SupabaseAccountRepository implements AccountRepository {
  SupabaseAccountRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<void> updateAccount({required String name, String? avatarKey}) async {
    final userId = _requireAuthenticatedUser();
    final trimmedName = name.trim();
    final normalizedAvatar =
        (avatarKey == null || avatarKey.trim().isEmpty) ? null : avatarKey.trim();

    // Auth user metadata drives every name/avatar the UI reads today
    // (AuthService.getCurrentUser maps it into UserModel), so it must succeed
    // for the change to be visible.
    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': trimmedName,
          'name': trimmedName,
          'avatar_url': normalizedAvatar,
        },
      ),
    );

    // Mirror into public.profiles so the database stays canonical for
    // server-side features. Best-effort: legacy accounts predating the signup
    // trigger have no profiles row, and that must not fail the rename.
    try {
      await _client
          .from('profiles')
          .update({'name': trimmedName, 'avatar_url': normalizedAvatar})
          .eq('id', userId);
    } catch (error) {
      debugPrint('Profile mirror update skipped: $error');
    }
  }

  @override
  Future<void> deleteAccount() async {
    _requireAuthenticatedUser();

    // SECURITY DEFINER RPC — deletes only auth.uid()'s own row, then cascades.
    await _client.rpc('delete_own_account');
  }

  String _requireAuthenticatedUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User must be authenticated to change account settings.');
    }
    return user.id;
  }
}

/// In-memory implementation of [AccountRepository] for tests and offline mode.
class MemoryAccountRepository implements AccountRepository {
  String? lastName;
  String? lastAvatarKey;
  bool wasDeleted = false;

  /// When set, every call throws this instead of succeeding.
  Object? failure;

  @override
  Future<void> updateAccount({required String name, String? avatarKey}) async {
    if (failure != null) throw failure!;
    lastName = name.trim();
    lastAvatarKey = avatarKey;
  }

  @override
  Future<void> deleteAccount() async {
    if (failure != null) throw failure!;
    wasDeleted = true;
  }
}
