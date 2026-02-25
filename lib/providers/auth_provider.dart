import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/models/user_model.dart';
import 'package:lifeboard/services/auth_service.dart';

/// Provides the [AuthService] singleton.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Streams the current Firebase Auth user (null when signed out).
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// A [ChangeNotifier] that fires whenever auth state changes.
/// Used as GoRouter's `refreshListenable`.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._authService) {
    _subscription = _authService.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  final AuthService _authService;
  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provides the [AuthNotifier] for GoRouter refresh.
final authNotifierProvider = Provider<AuthNotifier>((ref) {
  final authService = ref.watch(authServiceProvider);
  final notifier = AuthNotifier(authService);
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Streams the current user's Firestore document as a [UserModel].
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});
