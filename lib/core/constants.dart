/// App-wide constants and warm display label mappings.
abstract final class AppConstants {
  // ── App Info ─────────────────────────────────────────────
  static const String appName = 'Lifeboard';
  static const String tagline = 'Plan life together, simply.';

  // ── Warm Status Labels ───────────────────────────────────
  /// Maps internal status keys to user-facing warm labels.
  static const Map<String, String> statusLabels = {
    'todo': 'To Do',
    'in_progress': 'Working on it',
    'done': 'We did it! \u{1F389}',
  };

  // ── Column Display Labels (Kanban headers) ───────────────
  static const Map<String, String> columnLabels = {
    'backlog': 'Next Up',
    'sprint': 'This Week',
    'todo': 'To Do',
    'in_progress': 'Working on it',
    'done': 'We did it! \u{1F389}',
  };

  // ── Task Statuses ───────────────────────────────────────────
  static const List<String> taskStatuses = ['todo', 'in_progress', 'done'];

  // ── Default Board Name ────────────────────────────────────
  static const String defaultBoardName = 'Home';

  // ── Emoji Tags ───────────────────────────────────────────
  static const List<String> emojiTags = [
    '\u{1F4B0}', // 💰 Finances
    '\u{1F3E1}', // 🏡 Home
    '\u{2764}\u{FE0F}', // ❤️ Relationship
    '\u{1F9E0}', // 🧠 Personal growth
    '\u{1F4AA}', // 💪 Health
    '\u{2600}\u{FE0F}', // ☀️ Fun / Leisure
  ];

  // ── Default Space Name ───────────────────────────────────
  static const String defaultSpaceName = 'Our Home';

  // ── Invite Code Length ───────────────────────────────────
  static const int inviteCodeLength = 6;
}

/// Helper to get the warm display label for a task status.
class StatusDisplayName {
  const StatusDisplayName._();

  static String fromStatus(String status) {
    return AppConstants.statusLabels[status] ?? status;
  }
}
