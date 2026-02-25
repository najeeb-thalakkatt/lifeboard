import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/models/user_model.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/screens/home/home_dashboard_screen.dart';
import 'package:lifeboard/theme/app_theme.dart';

/// Wraps [HomeDashboardScreen] with required providers and GoRouter.
Widget _buildTestApp({
  required List<SpaceModel> spaces,
  UserModel? user,
  bool loadingSpaces = false,
  String? spacesError,
}) {
  final router = GoRouter(
    initialLocation: '/spaces',
    routes: [
      GoRoute(
        path: '/spaces',
        builder: (_, __) => const HomeDashboardScreen(),
        routes: [
          GoRoute(
            path: ':spaceId',
            builder: (_, state) => Scaffold(
              body: Center(
                child: Text('Board: ${state.pathParameters['spaceId']}'),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/create-space',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Create Space')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      userSpacesProvider.overrideWith((ref) {
        if (spacesError != null) {
          return Stream.error(Exception(spacesError));
        }
        if (loadingSpaces) {
          // Return a stream that never emits to keep loading state
          return StreamController<List<SpaceModel>>().stream;
        }
        return Stream.value(spaces);
      }),
      currentUserProvider.overrideWith((ref) {
        if (user != null) return Stream.value(user);
        return Stream.value(null);
      }),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
    ),
  );
}

// ── Test Data ─────────────────────────────────────────────────────

final _testUser = UserModel(
  id: 'user-1',
  displayName: 'Alex Smith',
  email: 'alex@example.com',
  spaceIds: ['space-1'],
  createdAt: DateTime(2025, 1, 1),
);

final _testSpaces = [
  SpaceModel(
    id: 'space-1',
    name: 'Our Home',
    members: {
      'user-1': SpaceMember(role: 'owner', joinedAt: DateTime(2025, 1, 1)),
      'user-2': SpaceMember(role: 'member', joinedAt: DateTime(2025, 1, 2)),
    },
    inviteCode: 'ABC123',
    themes: ['Home', 'Kids', 'Finances'],
    createdAt: DateTime(2025, 1, 1),
  ),
  SpaceModel(
    id: 'space-2',
    name: 'Work Projects',
    members: {
      'user-1': SpaceMember(role: 'owner', joinedAt: DateTime(2025, 2, 1)),
    },
    inviteCode: 'XYZ789',
    themes: ['Office'],
    createdAt: DateTime(2025, 2, 1),
  ),
];

// ── Tests ─────────────────────────────────────────────────────────

void main() {
  group('HomeDashboardScreen', () {
    testWidgets('shows welcome header with user first name', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: _testSpaces, user: _testUser),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Welcome back, Alex'), findsOneWidget);
    });

    testWidgets('shows "Your spaces" subtitle', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: _testSpaces, user: _testUser),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your spaces'), findsOneWidget);
    });

    testWidgets('displays space cards with names', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: _testSpaces, user: _testUser),
      );
      await tester.pumpAndSettle();

      expect(find.text('Our Home'), findsOneWidget);
      expect(find.text('Work Projects'), findsOneWidget);
    });

    testWidgets('displays member count on space cards', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: _testSpaces, user: _testUser),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 members'), findsOneWidget);
      expect(find.text('1 member'), findsOneWidget);
    });

    testWidgets('displays theme tags on space cards', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: _testSpaces, user: _testUser),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Kids'), findsOneWidget);
      expect(find.text('Finances'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
    });

    testWidgets('tapping a space card navigates to board', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: _testSpaces, user: _testUser),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Our Home'));
      await tester.pumpAndSettle();

      expect(find.text('Board: space-1'), findsOneWidget);
    });

    testWidgets('shows empty state when no spaces', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: [], user: _testUser),
      );
      await tester.pumpAndSettle();

      expect(find.text('No spaces yet'), findsOneWidget);
      expect(find.text('Create a Space'), findsOneWidget);
    });

    testWidgets('empty state Create button navigates to create-space',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: [], user: _testUser),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create a Space'));
      await tester.pumpAndSettle();

      expect(find.text('Create Space'), findsOneWidget);
    });

    testWidgets('shows FAB with "New Space" label', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: _testSpaces, user: _testUser),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Space'), findsOneWidget);
    });

    testWidgets('FAB navigates to create-space screen', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: _testSpaces, user: _testUser),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Space'));
      await tester.pumpAndSettle();

      expect(find.text('Create Space'), findsOneWidget);
    });

    testWidgets('shows loading indicator when spaces are loading',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: [], loadingSpaces: true),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error view with retry when spaces fail to load',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(spaces: [], spacesError: 'Network error'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load spaces'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows generic welcome when user has no name', (tester) async {
      final noNameUser = UserModel(
        id: 'user-1',
        displayName: '',
        email: 'alex@example.com',
        spaceIds: [],
        createdAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        _buildTestApp(spaces: [], user: noNameUser),
      );
      await tester.pumpAndSettle();

      // Should show generic welcome without a name
      expect(find.textContaining('Welcome back'), findsOneWidget);
      expect(find.textContaining('Welcome back, '), findsNothing);
    });
  });
}
