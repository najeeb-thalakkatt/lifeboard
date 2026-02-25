import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/screens/onboarding/welcome_screen.dart';
import 'package:lifeboard/theme/app_theme.dart';

/// Wraps a widget in MaterialApp.router with a GoRouter for testing.
Widget _buildTestApp({required String initialLocation}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, state) => Scaffold(
          body: Center(
            child: Text('Auth: ${state.uri.queryParameters['mode']}'),
          ),
        ),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    theme: AppTheme.light,
  );
}

void main() {
  group('WelcomeScreen', () {
    testWidgets('displays app name and tagline', (tester) async {
      await tester.pumpWidget(_buildTestApp(initialLocation: '/welcome'));
      await tester.pumpAndSettle();

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.tagline), findsOneWidget);
    });

    testWidgets('displays Get Started button', (tester) async {
      await tester.pumpWidget(_buildTestApp(initialLocation: '/welcome'));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Get Started'),
          matching: find.byType(FilledButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays Log In button', (tester) async {
      await tester.pumpWidget(_buildTestApp(initialLocation: '/welcome'));
      await tester.pumpAndSettle();

      expect(find.text('Log In'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Log In'),
          matching: find.byType(TextButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Get Started navigates to auth signup', (tester) async {
      await tester.pumpWidget(_buildTestApp(initialLocation: '/welcome'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Auth: signup'), findsOneWidget);
    });

    testWidgets('Log In navigates to auth login', (tester) async {
      await tester.pumpWidget(_buildTestApp(initialLocation: '/welcome'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Auth: login'), findsOneWidget);
    });

    testWidgets('has logo image or fallback icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(initialLocation: '/welcome'));
      await tester.pumpAndSettle();

      // Either the Image.asset or the fallback kayaking Icon should exist
      final hasImage = find.byType(Image).evaluate().isNotEmpty;
      final hasIcon = find.byIcon(Icons.kayaking).evaluate().isNotEmpty;

      expect(hasImage || hasIcon, isTrue);
    });
  });
}
