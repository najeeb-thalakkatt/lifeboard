import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/screens/onboarding/auth_screen.dart';
import 'package:lifeboard/screens/onboarding/create_join_space_screen.dart';
import 'package:lifeboard/screens/onboarding/invite_partner_screen.dart';
import 'package:lifeboard/screens/onboarding/welcome_screen.dart';
import 'package:lifeboard/theme/app_theme.dart';
import 'package:lifeboard/screens/home/home_dashboard_screen.dart';
import 'package:lifeboard/screens/board/board_view_screen.dart';
import 'package:lifeboard/screens/task/task_detail_screen.dart';
import 'package:lifeboard/widgets/responsive_shell.dart';
import 'package:lifeboard/screens/weekly/weekly_view_screen.dart';
import 'package:lifeboard/widgets/shared_app_bar.dart';
import 'package:lifeboard/screens/profile/profile_settings_screen.dart';
import 'package:lifeboard/providers/profile_provider.dart';

// ── Placeholder screens (replaced in later phases) ──────────

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SharedAppBar(title: title),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

// ── Router ───────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Routes only for unauthenticated users (login/signup).
const _unauthOnlyPaths = ['/welcome', '/auth'];

/// Routes that require auth but live outside the bottom-nav shell.
const _authNoShellPaths = ['/create-space', '/invite'];

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/spaces',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isAuthenticated = user != null;
      final currentPath = state.matchedLocation;
      final isUnauthOnly =
          _unauthOnlyPaths.any(currentPath.startsWith);
      final isAuthNoShell =
          _authNoShellPaths.any(currentPath.startsWith);

      // Not authenticated → force to welcome (unless already on unauth route)
      if (!isAuthenticated && !isUnauthOnly) {
        return '/welcome';
      }

      // Authenticated but on an unauth-only route → send to spaces
      if (isAuthenticated && isUnauthOnly) {
        return '/spaces';
      }

      // Auth no-shell routes require authentication
      if (!isAuthenticated && isAuthNoShell) {
        return '/welcome';
      }

      return null; // No redirect needed.
    },
    routes: [
      // ── Public routes (no shell / no bottom nav) ──────────
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'signup';
          return AuthScreen(isSignUp: mode == 'signup');
        },
      ),
      GoRoute(
        path: '/create-space',
        builder: (context, state) => const CreateJoinSpaceScreen(),
      ),
      GoRoute(
        path: '/invite',
        builder: (context, state) {
          final space = state.extra as SpaceModel;
          return InvitePartnerScreen(space: space);
        },
      ),

      // ── Authenticated routes (with responsive nav shell) ──
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(
            path: '/spaces',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeDashboardScreen(),
            ),
            routes: [
              GoRoute(
                path: ':spaceId',
                builder: (context, state) {
                  final spaceId = state.pathParameters['spaceId']!;
                  return BoardViewScreen(spaceId: spaceId);
                },
                routes: [
                  GoRoute(
                    path: 'task/:taskId',
                    builder: (context, state) {
                      final spaceId = state.pathParameters['spaceId']!;
                      final taskId = state.pathParameters['taskId']!;
                      return TaskDetailScreen(
                        spaceId: spaceId,
                        taskId: taskId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/weekly',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WeeklyViewScreen(),
            ),
          ),
          GoRoute(
            path: '/activity',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderScreen(title: 'Activity'),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileSettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});


// ── Root App Widget ──────────────────────────────────────────

class LifeboardApp extends ConsumerWidget {
  const LifeboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Lifeboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
    );
  }
}
