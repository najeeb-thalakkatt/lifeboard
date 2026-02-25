import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/screens/onboarding/auth_screen.dart';
import 'package:lifeboard/core/errors/app_exceptions.dart';
import 'package:lifeboard/services/auth_service.dart';
import 'package:lifeboard/theme/app_theme.dart';

// ── Mocks ────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

// ── Helpers ──────────────────────────────────────────────────

Widget _buildTestApp({
  required MockAuthService mockAuth,
  bool isSignUp = true,
}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(mockAuth),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: AuthScreen(isSignUp: isSignUp),
    ),
  );
}

void main() {
  late MockAuthService mockAuth;
  late MockUserCredential mockCredential;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockAuthService();
    mockCredential = MockUserCredential();
    mockUser = MockUser();
    when(() => mockCredential.user).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test-uid');
  });

  // ── Sign Up Mode ──────────────────────────────────────────

  group('AuthScreen (sign up mode)', () {
    testWidgets('displays Create Account title', (tester) async {
      await tester.pumpWidget(_buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Start planning life together'), findsOneWidget);
    });

    testWidgets('shows display name, email, and password fields',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows Google sign-in button', (tester) async {
      await tester.pumpWidget(_buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows toggle to Log In mode', (tester) async {
      await tester.pumpWidget(_buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      expect(find.text('Already have an account?'), findsOneWidget);
      // The toggle button text "Log In"
      expect(
        find.descendant(
          of: find.byType(TextButton),
          matching: find.text('Log In'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('validates empty form on submit', (tester) async {
      await tester.pumpWidget(_buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      // Find the Create Account FilledButton (submit)
      final submitButton = find.ancestor(
        of: find.text('Create Account'),
        matching: find.byType(FilledButton),
      );
      await tester.tap(submitButton.first);
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Display name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('validates invalid email', (tester) async {
      await tester.pumpWidget(_buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Alice',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'not-an-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      final submitButton = find.ancestor(
        of: find.text('Create Account'),
        matching: find.byType(FilledButton),
      );
      await tester.tap(submitButton.first);
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('validates short password', (tester) async {
      await tester.pumpWidget(_buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Alice',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'alice@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'short',
      );

      final submitButton = find.ancestor(
        of: find.text('Create Account'),
        matching: find.byType(FilledButton),
      );
      await tester.tap(submitButton.first);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    });

    testWidgets('calls signUpWithEmail on valid submit', (tester) async {
      when(() => mockAuth.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async => mockCredential);

      await tester.pumpWidget(_buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Alice',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'alice@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      final submitButton = find.ancestor(
        of: find.text('Create Account'),
        matching: find.byType(FilledButton),
      );
      await tester.tap(submitButton.first);
      await tester.pumpAndSettle();

      verify(() => mockAuth.signUpWithEmail(
            email: 'alice@example.com',
            password: 'password123',
            displayName: 'Alice',
          )).called(1);
    });

    testWidgets('shows snackbar on FirebaseException', (tester) async {
      when(() => mockAuth.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenThrow(
        FirebaseException(
          plugin: 'auth',
          code: 'email-already-in-use',
          message: 'Email already in use',
        ),
      );

      await tester.pumpWidget(_buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Alice',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'taken@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      final submitButton = find.ancestor(
        of: find.text('Create Account'),
        matching: find.byType(FilledButton),
      );
      await tester.tap(submitButton.first);
      await tester.pumpAndSettle();

      expect(find.text('Email already in use'), findsOneWidget);
    });

    testWidgets('does nothing on AuthCancelledException', (tester) async {
      when(() => mockAuth.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenThrow(const AuthCancelledException());

      await tester.pumpWidget(_buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Alice',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'alice@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      final submitButton = find.ancestor(
        of: find.text('Create Account'),
        matching: find.byType(FilledButton),
      );
      await tester.tap(submitButton.first);
      await tester.pumpAndSettle();

      // No snackbar should be shown
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  // ── Log In Mode ───────────────────────────────────────────

  group('AuthScreen (login mode)', () {
    testWidgets('displays Welcome Back title', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(mockAuth: mockAuth, isSignUp: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to your account'), findsOneWidget);
    });

    testWidgets('does not show display name field in login mode',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(mockAuth: mockAuth, isSignUp: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Display Name'), findsNothing);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows toggle to Sign Up mode', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(mockAuth: mockAuth, isSignUp: false),
      );
      await tester.pumpAndSettle();

      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TextButton),
          matching: find.text('Sign Up'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('calls signInWithEmail on valid submit', (tester) async {
      when(() => mockAuth.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);

      await tester.pumpWidget(
        _buildTestApp(mockAuth: mockAuth, isSignUp: false),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'alice@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      final submitButton = find.ancestor(
        of: find.text('Log In'),
        matching: find.byType(FilledButton),
      );
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      verify(() => mockAuth.signInWithEmail(
            email: 'alice@example.com',
            password: 'password123',
          )).called(1);
    });

    testWidgets('shows snackbar on wrong password error', (tester) async {
      when(() => mockAuth.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
        FirebaseException(
          plugin: 'auth',
          code: 'wrong-password',
          message: 'Wrong password',
        ),
      );

      await tester.pumpWidget(
        _buildTestApp(mockAuth: mockAuth, isSignUp: false),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'alice@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'wrongpass',
      );

      final submitButton = find.ancestor(
        of: find.text('Log In'),
        matching: find.byType(FilledButton),
      );
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Wrong password'), findsOneWidget);
    });
  });

  // ── Mode Toggle ───────────────────────────────────────────

  group('AuthScreen mode toggle', () {
    testWidgets('toggles from sign up to login', (tester) async {
      await tester.pumpWidget(_buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      // Initially in sign up mode
      expect(find.text('Create Account'), findsWidgets);

      // Scroll the toggle into view and tap it
      final toggleFinder = find.descendant(
        of: find.byType(TextButton),
        matching: find.text('Log In'),
      );
      await tester.ensureVisible(toggleFinder);
      await tester.pumpAndSettle();
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Now in login mode
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Display Name'), findsNothing);
    });

    testWidgets('toggles from login to sign up', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(mockAuth: mockAuth, isSignUp: false),
      );
      await tester.pumpAndSettle();

      // Initially in login mode
      expect(find.text('Welcome Back'), findsOneWidget);

      // Tap the toggle
      await tester.tap(find.descendant(
        of: find.byType(TextButton),
        matching: find.text('Sign Up'),
      ));
      await tester.pumpAndSettle();

      // Now in sign up mode
      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Display Name'), findsOneWidget);
    });
  });

  // ── Password Visibility ───────────────────────────────────

  group('AuthScreen password visibility', () {
    testWidgets('password is obscured by default', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(mockAuth: mockAuth, isSignUp: false),
      );
      await tester.pumpAndSettle();

      // Find the EditableText inside the password field to check obscureText
      final editableText = tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Password'),
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('toggle visibility icon reveals password', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(mockAuth: mockAuth, isSignUp: false),
      );
      await tester.pumpAndSettle();

      // Tap the visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      // Now the visibility_outlined icon should be shown
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}
