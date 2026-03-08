import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Tab Persistence ───────────────────────────────────────────────

const _lastTabKey = 'last_tab_index';

/// Remembers which bottom-nav tab the user was on across app restarts.
class LastTabNotifier extends StateNotifier<int> {
  LastTabNotifier() : super(0) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_lastTabKey);
    if (saved != null && saved >= 0 && saved <= 2) {
      state = saved;
    }
  }

  Future<void> setTab(int index) async {
    state = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastTabKey, index);
  }
}

final lastTabProvider = StateNotifierProvider<LastTabNotifier, int>((ref) {
  return LastTabNotifier();
});
