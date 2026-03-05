import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lifeboard/providers/activity_provider.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';

// ── Theme Mode Provider ─────────────────────────────────────────

/// Holds the current [ThemeMode] and persists it via SharedPreferences.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadFromPrefs();
  }

  static const _key = 'theme_mode';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'dark') {
      state = ThemeMode.dark;
    } else if (value == 'system') {
      state = ThemeMode.system;
    } else if (value == 'light') {
      state = ThemeMode.light;
    }
  }

  Future<void> _saveToPrefs(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _saveToPrefs(mode);
  }

  void toggle() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = next;
    _saveToPrefs(next);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// ── Stats Model ─────────────────────────────────────────────────

class SpaceStats {
  const SpaceStats({
    this.totalCompleted = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  final int totalCompleted;
  final int currentStreak;
  final int bestStreak;
}

/// Fetches aggregated stats across all user spaces.
final spaceStatsProvider = FutureProvider<SpaceStats>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const SpaceStats();

  final spacesAsync = ref.watch(userSpacesProvider);
  final spaces = spacesAsync.valueOrNull ?? [];
  if (spaces.isEmpty) return const SpaceStats();

  final spaceIds = spaces.map((s) => s.id).toList();
  final firestoreService = ref.read(firestoreServiceProvider);

  final totalCompleted = await firestoreService.getCompletedTaskCount(spaceIds);
  final weeks = await firestoreService.getCompletionWeeks(spaceIds);

  // Calculate current and best streaks
  int currentStreak = 0;
  int bestStreak = 0;

  if (weeks.isNotEmpty) {
    // weeks is sorted descending (most recent first)
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekKey = DateTime(
      currentMonday.year,
      currentMonday.month,
      currentMonday.day,
    );

    // Check if the most recent week is current or last week
    final mostRecent = weeks.first;
    final diffDays = currentWeekKey.difference(mostRecent).inDays;

    if (diffDays <= 7) {
      // Streak is active (completed this week or last week)
      currentStreak = 1;
      for (int i = 1; i < weeks.length; i++) {
        final expected = weeks[i - 1].subtract(const Duration(days: 7));
        final diff = weeks[i].difference(expected).inDays.abs();
        if (diff <= 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    // Calculate best streak
    int streak = 1;
    for (int i = 1; i < weeks.length; i++) {
      final expected = weeks[i - 1].subtract(const Duration(days: 7));
      final diff = weeks[i].difference(expected).inDays.abs();
      if (diff <= 1) {
        streak++;
      } else {
        if (streak > bestStreak) bestStreak = streak;
        streak = 1;
      }
    }
    if (streak > bestStreak) bestStreak = streak;
    if (currentStreak > bestStreak) bestStreak = currentStreak;
  }

  return SpaceStats(
    totalCompleted: totalCompleted,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
  );
});

// ── Profile Action Notifier ─────────────────────────────────────

class ProfileActionNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileActionNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  /// Updates display name on the user doc.
  Future<void> updateDisplayName(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateUserProfile(
        userId: user.uid,
        fields: {'displayName': name},
      );
      await user.updateDisplayName(name);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Updates the mood emoji.
  Future<void> updateMoodEmoji(String? emoji) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateUserProfile(
        userId: user.uid,
        fields: {'moodEmoji': emoji},
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Updates photo URL after upload.
  Future<void> updatePhotoUrl(String url) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateUserProfile(
        userId: user.uid,
        fields: {'photoUrl': url},
      );
      await user.updatePhotoURL(url);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Updates notification preferences.
  Future<void> updateNotificationPrefs({
    required bool pushEnabled,
    required bool emailEnabled,
    bool homePadUpdates = true,
    bool homePadComplete = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateNotificationPrefs(
        userId: user.uid,
        pushEnabled: pushEnabled,
        emailEnabled: emailEnabled,
        homePadUpdates: homePadUpdates,
        homePadComplete: homePadComplete,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Leaves a space.
  Future<void> leaveSpace(String spaceId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.leaveSpace(spaceId: spaceId, userId: user.uid);
      _ref.invalidate(userSpacesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Deletes a space (owner only).
  Future<void> deleteSpace(String spaceId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.deleteSpace(spaceId: spaceId, userId: user.uid);
      _ref.invalidate(userSpacesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Changes the user's password (email auth only).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    state = const AsyncLoading();
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _ref.read(notificationServiceProvider).removeToken();
    } catch (_) {
      // Best-effort token cleanup — don't block sign-out
    }
    final authService = _ref.read(authServiceProvider);
    await authService.signOut();
  }

  /// Deletes the user's account (Firestore data + Firebase Auth).
  /// Throws [FirebaseAuthException] with code 'requires-recent-login' if
  /// the session is too old — the caller should prompt re-authentication.
  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.deleteUserAccount(userId: user.uid);
      await user.delete();
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e, st);
      if (e.code == 'requires-recent-login') {
        rethrow;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final profileActionProvider =
    StateNotifierProvider<ProfileActionNotifier, AsyncValue<void>>((ref) {
  return ProfileActionNotifier(ref);
});
