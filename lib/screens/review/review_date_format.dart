/// Compact, dependency-free timestamp formatting for the quiz review log.
///
/// The project does not depend on `intl`, and the review list only needs a
/// short human label, so this stays local to the review feature.
library;

const List<String> _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats [timestamp] as "Today, 3:04 PM", "Yesterday, 9:12 AM", or "12 Sep".
///
/// [now] is injectable so tests do not depend on the wall clock.
String formatReviewTimestamp(DateTime timestamp, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final local = timestamp.toLocal();

  final startOfToday = DateTime(current.year, current.month, current.day);
  final startOfTimestamp = DateTime(local.year, local.month, local.day);
  final dayDelta = startOfToday.difference(startOfTimestamp).inDays;

  if (dayDelta == 0) return 'Today, ${formatClockTime(local)}';
  if (dayDelta == 1) return 'Yesterday, ${formatClockTime(local)}';
  if (dayDelta > 1 && dayDelta < 7) return '$dayDelta days ago';

  final month = _monthAbbreviations[local.month - 1];
  if (local.year != current.year) {
    return '${local.day} $month ${local.year}';
  }
  return '${local.day} $month';
}

/// Formats the time portion as a 12-hour clock, e.g. "3:04 PM".
String formatClockTime(DateTime timestamp) {
  final hour24 = timestamp.hour;
  final suffix = hour24 < 12 ? 'AM' : 'PM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $suffix';
}
