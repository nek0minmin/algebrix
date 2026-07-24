/// Centralized string constants for Algebrix.
///
/// Includes static labels, dynamic greeting generator, and placeholder content.
/// Future: integrate with l10n for multi-language support.
class AppStrings {
  AppStrings._();

  // ── App Identity ──────────────────────────────────────────────────────────
  static const String appName = 'Algebrix';
  static const String tagline = 'Explore the Whys.';

  // ── Navigation Labels ─────────────────────────────────────────────────────
  static const String navHome = 'Home';
  static const String navLessons = 'Lessons';
  static const String navQuiz = 'Quiz';
  static const String navPractice = 'Practice';

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static const String searchHint = 'Search lessons or topics';
  static const String continueLearning = 'Continue Learning';
  static const String dailyChallenge = 'Daily Challenge';
  static const String xyTipTitle = "Today's Tip from Xy";

  /// Generates a time-aware personalized greeting.
  static String greeting(String name) {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }
    return '$timeGreeting,\n$name! 👋';
  }

  // ── Xy Tips (rotates daily) ───────────────────────────────────────────────
  static const List<String> xyTips = [
    'Remember: whatever you do to one side, do it to the other!',
    'Variables are just letters that represent unknown numbers.',
    'An equation is like a balance scale — keep it equal!',
    'When you see x + 3 = 7, ask yourself: what plus 3 gives me 7?',
    'Algebra is like solving a puzzle. Take it one step at a time!',
    'Don\'t be afraid of mistakes — they help you learn!',
    'Patterns are everywhere in math. Can you spot them?',
  ];

  /// Returns the tip of the day based on the current date.
  static String get tipOfTheDay {
    final dayOfYear = DateTime.now().difference(
      DateTime(DateTime.now().year, 1, 1),
    ).inDays;
    return xyTips[dayOfYear % xyTips.length];
  }

  // ── Placeholder ───────────────────────────────────────────────────────────
  static const String comingSoon = 'Coming Soon';
  static const String readyToLearn = 'Ready to solve and level up?';
}
