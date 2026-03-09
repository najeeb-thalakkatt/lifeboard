import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:lifeboard/providers/activity_provider.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';

// ── Theme Mode Provider ─────────────────────────────────────────

/// Holds the current [ThemeMode] and persists it via SharedPreferences.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
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

    // Cancel active Firestore listeners before revoking auth
    // to avoid permission-denied errors during the sign-out window.
    _ref.invalidate(currentUserProvider);
    _ref.invalidate(userSpacesProvider);
    _ref.invalidate(unreadActivityCountProvider);

    final authService = _ref.read(authServiceProvider);
    await authService.signOut();
  }

  /// Returns the primary sign-in provider for the current user.
  String? getSignInProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') return 'google.com';
      if (info.providerId == 'apple.com') return 'apple.com';
      if (info.providerId == 'password') return 'password';
    }
    return null;
  }

  /// Re-authenticates with email/password, then deletes the account.
  Future<void> deleteAccountWithPassword(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      debugPrint('[DELETE] No current user or email — aborting');
      return;
    }

    debugPrint('[DELETE] Starting deletion for ${user.email}');
    state = const AsyncLoading();
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      debugPrint('[DELETE] Re-authenticating...');
      await user.reauthenticateWithCredential(credential);
      debugPrint('[DELETE] Re-auth successful, proceeding to delete');
      await _performAccountDeletion(user);
    } catch (e, st) {
      debugPrint('[DELETE] ERROR: $e');
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Re-authenticates with Google, then deletes the account.
  Future<void> deleteAccountWithGoogle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await user.reauthenticateWithCredential(credential);
      await _performAccountDeletion(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Re-authenticates with Apple, then deletes the account.
  Future<void> deleteAccountWithApple() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) throw Exception('Apple Sign-In was cancelled.');

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );
      await user.reauthenticateWithCredential(oauthCredential);
      await _performAccountDeletion(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Deletes Firestore data and the Firebase Auth account,
  /// then invalidates providers to trigger navigation to auth screen.
  Future<void> _performAccountDeletion(User user) async {
    final firestoreService = _ref.read(firestoreServiceProvider);

    // 1. Delete Firestore user data
    debugPrint('[DELETE] Deleting Firestore data for ${user.uid}');
    await firestoreService.deleteUserAccount(userId: user.uid);
    debugPrint('[DELETE] Firestore data deleted');

    // 2. Delete the Firebase Auth account — must happen BEFORE
    //    invalidating providers, because invalidation triggers
    //    navigation which could abort this async operation.
    debugPrint('[DELETE] Deleting Firebase Auth account');
    await user.delete();
    debugPrint('[DELETE] Firebase Auth account deleted');

    // 3. Now safe to invalidate providers and clear local state.
    _ref.invalidate(currentUserProvider);
    _ref.invalidate(userSpacesProvider);
    _ref.invalidate(unreadActivityCountProvider);

    state = const AsyncData(null);
    debugPrint('[DELETE] Account deletion complete');
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

final profileActionProvider =
    StateNotifierProvider<ProfileActionNotifier, AsyncValue<void>>((ref) {
  return ProfileActionNotifier(ref);
});
