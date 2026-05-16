import 'package:intl/intl.dart';

/// DateTime extensions for display and API formatting.
///
/// All display dates follow the `dd MMM yyyy` format (e.g., "16 May 2026").
/// All API dates follow ISO 8601 `yyyy-MM-dd` format.
extension DateTimeExt on DateTime {
  /// Formats for display: "16 May 2026"
  String toDisplay() => DateFormat('dd MMM yyyy').format(this);

  /// Formats for display with time: "16 May 2026, 10:30 AM"
  String toDisplayWithTime() => DateFormat('dd MMM yyyy, hh:mm a').format(this);

  /// Formats for API calls: "2026-05-16"
  String toApiDate() => DateFormat('yyyy-MM-dd').format(this);

  /// Formats time only: "10:30 AM"
  String toTimeOnly() => DateFormat('hh:mm a').format(this);

  /// Formats time for chat bubbles: "10:30"
  String toDisplayTime() => DateFormat('HH:mm').format(this);

  /// Formats as short date: "16 May"
  String toShortDate() => DateFormat('dd MMM').format(this);

  /// Returns a human-readable relative time string.
  ///
  /// Examples: "just now", "5 minutes ago", "2 hours ago", "yesterday"
  String toRelative() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return toDisplay();
  }

  /// Whether this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Whether this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}
