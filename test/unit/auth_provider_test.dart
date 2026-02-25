import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/services/auth_service.dart';

// ── Mocks ────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

void main() {
  // ── authServiceProvider ───────────────────────────────────

  group('authServiceProvider', () {
    test('provides an AuthService instance', () {
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(authServiceProvider), isA<AuthService>());
    });
  });

  // ── authStateProvider ─────────────────────────────────────

  group('authStateProvider', () {
    test('emits auth state from AuthService stream', () async {
      final mockAuth = MockAuthService();
      final mockUser = MockUser();
      final controller = StreamController<User?>();

      when(() => mockAuth.authStateChanges)
          .thenAnswer((_) => controller.stream);

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(() {
        container.dispose();
        controller.close();
      });

      // Initially loading
      expect(
        container.read(authStateProvider),
        isA<AsyncLoading<User?>>(),
      );

      // Emit a user
      controller.add(mockUser);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(authStateProvider).value,
        mockUser,
      );

      // Emit null (signed out)
      controller.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(authStateProvider).value,
        isNull,
      );
    });

    test('starts as AsyncLoading before first emission', () {
      final mockAuth = MockAuthService();
      final controller = StreamController<User?>();

      when(() => mockAuth.authStateChanges)
          .thenAnswer((_) => controller.stream);

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(() {
        container.dispose();
        controller.close();
      });

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncLoading<User?>>());
    });
  });

  // ── AuthNotifier ──────────────────────────────────────────

  group('AuthNotifier', () {
    test('notifies listeners on auth state change', () async {
      final mockAuth = MockAuthService();
      final controller = StreamController<User?>.broadcast();
      final mockUser = MockUser();

      when(() => mockAuth.authStateChanges)
          .thenAnswer((_) => controller.stream);

      final notifier = AuthNotifier(mockAuth);

      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      controller.add(mockUser);
      await Future<void>.delayed(Duration.zero);
      expect(notifyCount, 1);

      controller.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(notifyCount, 2);

      notifier.dispose();
      await controller.close();
    });

    test('is a ChangeNotifier', () {
      final mockAuth = MockAuthService();
      final controller = StreamController<User?>();
      when(() => mockAuth.authStateChanges)
          .thenAnswer((_) => controller.stream);

      final notifier = AuthNotifier(mockAuth);
      expect(notifier, isA<ChangeNotifier>());

      notifier.dispose();
      controller.close();
    });

    test('stops listening after dispose', () async {
      final mockAuth = MockAuthService();
      final controller = StreamController<User?>.broadcast();

      when(() => mockAuth.authStateChanges)
          .thenAnswer((_) => controller.stream);

      final notifier = AuthNotifier(mockAuth);

      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.dispose();

      // After dispose, new events should not trigger notifications
      controller.add(MockUser());
      await Future<void>.delayed(Duration.zero);
      expect(notifyCount, 0);

      await controller.close();
    });
  });

  // ── authNotifierProvider ──────────────────────────────────

  group('authNotifierProvider', () {
    test('provides an AuthNotifier instance', () {
      final mockAuth = MockAuthService();
      final controller = StreamController<User?>();
      when(() => mockAuth.authStateChanges)
          .thenAnswer((_) => controller.stream);

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(() {
        container.dispose();
        controller.close();
      });

      expect(container.read(authNotifierProvider), isA<AuthNotifier>());
    });
  });
}
