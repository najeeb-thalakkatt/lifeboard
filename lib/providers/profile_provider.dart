import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';

// ── Theme Mode Provider ─────────────────────────────────────────

/// Holds the current [ThemeMode] and persists across the session.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  void setThemeMode(ThemeMode mode) => state = mode;

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
    state = const AsyncLoading();
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateUserProfile(
        userId: userId,
        fields: {'displayName': name},
      );
      await FirebaseAuth.instance.currentUser!.updateDisplayName(name);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Updates the mood emoji.
  Future<void> updateMoodEmoji(String? emoji) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateUserProfile(
        userId: userId,
        fields: {'moodEmoji': emoji},
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Updates photo URL after upload.
  Future<void> updatePhotoUrl(String url) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateUserProfile(
        userId: userId,
        fields: {'photoUrl': url},
      );
      await FirebaseAuth.instance.currentUser!.updatePhotoURL(url);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Updates notification preferences.
  Future<void> updateNotificationPrefs({
    required bool pushEnabled,
    required bool emailEnabled,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateNotificationPrefs(
        userId: userId,
        pushEnabled: pushEnabled,
        emailEnabled: emailEnabled,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Leaves a space.
  Future<void> leaveSpace(String spaceId) async {
    state = const AsyncLoading();
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.leaveSpace(spaceId: spaceId, userId: userId);
      _ref.invalidate(userSpacesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Deletes a space (owner only).
  Future<void> deleteSpace(String spaceId) async {
    state = const AsyncLoading();
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.deleteSpace(spaceId: spaceId, userId: userId);
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
    state = const AsyncLoading();
    try {
      final user = FirebaseAuth.instance.currentUser!;
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
    final authService = _ref.read(authServiceProvider);
    await authService.signOut();
  }

  /// Deletes the user's account (Firestore data + Firebase Auth).
  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.deleteUserAccount(userId: user.uid);
      await user.delete();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final profileActionProvider =
    StateNotifierProvider<ProfileActionNotifier, AsyncValue<void>>((ref) {
  return ProfileActionNotifier(ref);
});
