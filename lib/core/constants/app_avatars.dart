import 'package:algebrix/core/constants/app_assets.dart';

/// A selectable learner avatar, drawn from the existing Xy mascot artwork.
class AvatarOption {
  const AvatarOption({
    required this.key,
    required this.label,
    required this.asset,
  });

  /// Stable slug persisted to `profiles.avatar_url` and auth user metadata.
  ///
  /// Must satisfy the `profiles_avatar_url_valid` constraint: lowercase
  /// alphanumerics and hyphens, 1–40 characters.
  final String key;

  /// Short human label shown under the avatar in the picker.
  final String label;

  /// Bundled asset path this key resolves to.
  final String asset;
}

/// Catalog of preset avatars available in Account Settings.
///
/// Avatars are preset rather than uploaded: no camera/storage permissions, no
/// image moderation burden, no new dependency, and every option is on-brand.
/// The `profiles.avatar_url` constraint also accepts an https URL, so swapping
/// in real uploads later needs no schema change.
class AppAvatars {
  AppAvatars._();

  static const String defaultKey = 'xy-happy';

  static const List<AvatarOption> options = [
    AvatarOption(key: 'xy-happy', label: 'Happy', asset: AppAssets.xyHappy),
    AvatarOption(key: 'xy-wave', label: 'Wave', asset: AppAssets.xyWave),
    AvatarOption(key: 'xy-idea', label: 'Idea', asset: AppAssets.xyIdea),
    AvatarOption(key: 'xy-insight', label: 'Insight', asset: AppAssets.xyInsight),
    AvatarOption(key: 'xy-question', label: 'Curious', asset: AppAssets.xyQuestion),
    AvatarOption(key: 'xy-balance', label: 'Balance', asset: AppAssets.xyBalance),
    AvatarOption(key: 'xy-notes', label: 'Notes', asset: AppAssets.xyNotes),
    AvatarOption(key: 'xy-practice', label: 'Practice', asset: AppAssets.xyPractice),
    AvatarOption(key: 'xy-lessons', label: 'Lessons', asset: AppAssets.xyLessons),
    AvatarOption(key: 'xy-quiz', label: 'Quiz', asset: AppAssets.xyQuiz),
    AvatarOption(key: 'xy-sit-pencil', label: 'Study', asset: AppAssets.xySitPencil),
    AvatarOption(key: 'xy-explaining', label: 'Explain', asset: AppAssets.xyExplaining),
  ];

  /// Resolves a stored avatar key to its bundled asset path.
  ///
  /// Returns `null` for an unknown key or an https URL, so callers can fall
  /// back to initials rather than crashing on a value this build doesn't know.
  static String? assetForKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final option in options) {
      if (option.key == key) return option.asset;
    }
    return null;
  }

  /// Whether [key] is one of the presets this build ships.
  static bool isKnownKey(String? key) => assetForKey(key) != null;
}
