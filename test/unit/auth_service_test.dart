import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lifeboard/core/errors/app_exceptions.dart';
import 'package:lifeboard/services/auth_service.dart';

// ── Mocks (only for Firebase Auth — Firestore uses FakeFirebaseFirestore) ──

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

// ── Fakes ────────────────────────────────────────────────────

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late AuthService authService;

  late MockUserCredential mockCredential;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    authService = AuthService(auth: mockAuth, firestore: fakeFirestore);

    mockCredential = MockUserCredential();
    mockUser = MockUser();

    // Default user properties
    when(() => mockUser.uid).thenReturn('test-uid');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.displayName).thenReturn('Test User');
    when(() => mockUser.photoURL).thenReturn(null);
    when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});

    // Default credential
    when(() => mockCredential.user).thenReturn(mockUser);
  });

  // ── authStateChanges ────────────────────────────────────────

  group('authStateChanges', () {
    test('returns stream from FirebaseAuth', () {
      final controller = StreamController<User?>();
      when(() => mockAuth.authStateChanges())
          .thenAnswer((_) => controller.stream);

      expect(authService.authStateChanges, isA<Stream<User?>>());
      controller.close();
    });

    test('emits user when signed in, null when signed out', () async {
      final controller = StreamController<User?>();
      when(() => mockAuth.authStateChanges())
          .thenAnswer((_) => controller.stream);

      final states = <User?>[];
      final sub = authService.authStateChanges.listen(states.add);

      controller.add(mockUser);
      controller.add(null);
      await controller.close();
      await sub.cancel();

      expect(states, [mockUser, null]);
    });
  });

  // ── currentUser ─────────────────────────────────────────────

  group('currentUser', () {
    test('returns null when no user signed in', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(authService.currentUser, isNull);
    });

    test('returns user when signed in', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      expect(authService.currentUser, mockUser);
    });
  });

  // ── signUpWithEmail ─────────────────────────────────────────

  group('signUpWithEmail', () {
    test('creates user, updates display name, and creates Firestore doc',
        () async {
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);

      final result = await authService.signUpWithEmail(
        email: 'alice@example.com',
        password: 'password123',
        displayName: 'Alice',
      );

      expect(result, mockCredential);

      // Verify createUserWithEmailAndPassword was called
      verify(() => mockAuth.createUserWithEmailAndPassword(
            email: 'alice@example.com',
            password: 'password123',
          )).called(1);

      // Verify display name was updated
      verify(() => mockUser.updateDisplayName('Alice')).called(1);

      // Verify Firestore user doc was created
      final doc = await fakeFirestore.collection('users').doc('test-uid').get();
      expect(doc.exists, isTrue);
    });

    test('creates Firestore doc with correct user data', () async {
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);

      await authService.signUpWithEmail(
        email: 'alice@example.com',
        password: 'password123',
        displayName: 'Alice',
      );

      final doc = await fakeFirestore.collection('users').doc('test-uid').get();
      final data = doc.data()!;

      expect(data['displayName'], 'Alice');
      expect(data['email'], 'test@example.com');
      expect(data['spaceIds'], isEmpty);
      expect(data['notificationPrefs']['pushEnabled'], isTrue);
      expect(data['notificationPrefs']['emailEnabled'], isTrue);
      expect(data['createdAt'], isA<Timestamp>());
    });

    test('propagates FirebaseAuthException on weak password', () async {
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(
        code: 'weak-password',
        message: 'Password is too weak',
      ));

      expect(
        () => authService.signUpWithEmail(
          email: 'alice@example.com',
          password: '123',
          displayName: 'Alice',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('propagates FirebaseAuthException on email-already-in-use', () async {
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'Email already in use',
      ));

      expect(
        () => authService.signUpWithEmail(
          email: 'taken@example.com',
          password: 'password123',
          displayName: 'Alice',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ── signInWithEmail ─────────────────────────────────────────

  group('signInWithEmail', () {
    test('signs in with email and password', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);

      final result = await authService.signInWithEmail(
        email: 'alice@example.com',
        password: 'password123',
      );

      expect(result, mockCredential);
      verify(() => mockAuth.signInWithEmailAndPassword(
            email: 'alice@example.com',
            password: 'password123',
          )).called(1);
    });

    test('does not create Firestore doc on sign in', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);

      await authService.signInWithEmail(
        email: 'alice@example.com',
        password: 'password123',
      );

      // Firestore users collection should be empty — signIn doesn't create docs
      final snapshot = await fakeFirestore.collection('users').get();
      expect(snapshot.docs, isEmpty);
    });

    test('propagates FirebaseAuthException on wrong password', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(
        code: 'wrong-password',
        message: 'Wrong password',
      ));

      expect(
        () => authService.signInWithEmail(
          email: 'alice@example.com',
          password: 'wrong',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('propagates FirebaseAuthException on user-not-found', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found',
      ));

      expect(
        () => authService.signInWithEmail(
          email: 'nobody@example.com',
          password: 'password123',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ── signOut ─────────────────────────────────────────────────

  group('signOut', () {
    test('calls FirebaseAuth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await authService.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });
  });

  // ── AuthCancelledException ──────────────────────────────────

  group('AuthCancelledException', () {
    test('has descriptive toString', () {
      const e = AuthCancelledException();
      expect(e.toString(), 'Sign-in was cancelled');
    });

    test('implements Exception', () {
      expect(const AuthCancelledException(), isA<Exception>());
    });
  });
}

/// Minimal FirebaseAuthException for testing (mirrors Firebase SDK).
class FirebaseAuthException extends FirebaseException {
  FirebaseAuthException({required super.code, super.message})
      : super(plugin: 'auth');
}
