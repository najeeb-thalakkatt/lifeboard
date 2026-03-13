// Pattern: Adding a GoRoute (shell vs full-screen)
// Source: lib/app.dart
// Usage: When adding new screens to the app

// ── Option 1: Shell route (with bottom nav) ────────────────
// Add inside ShellRoute.routes[] — screen gets ResponsiveShell wrapper
ShellRoute(
  navigatorKey: _shellNavigatorKey,
  builder: (context, state, child) => ResponsiveShell(
    currentLocation: state.matchedLocation,
    child: child,
  ),
  routes: [
    GoRoute(path: '/board', builder: (_, __) => const BoardViewScreen()),
    GoRoute(path: '/chores', builder: (_, __) => const ChoresScreen()),
    GoRoute(path: '/buylist', builder: (_, __) => const BuylistScreen()),
    // Add new tab here:
    GoRoute(path: '/newfeature', builder: (_, __) => const NewFeatureScreen()),
  ],
),

// ── Option 2: Full-screen push (no bottom nav) ────────────
// Use parentNavigatorKey: rootNavigatorKey to bypass shell
GoRoute(
  path: '/board/task/:taskId',
  parentNavigatorKey: rootNavigatorKey,
  builder: (_, state) => TaskDetailScreen(
    taskId: state.pathParameters['taskId']!,
  ),
),

// ── Navigation in code ─────────────────────────────────────
context.go('/board');                    // Replace current route
context.push('/board/task/$taskId');     // Push on stack

// ── Auth redirect logic ────────────────────────────────────
// Routes are auto-protected: unauthenticated users → /welcome
// Authenticated users trying /welcome or /auth → /board
// No-shell paths (/create-space, /invite) bypass shell but require auth

// Key points:
// 1. Shell routes = bottom nav visible. Full-screen = no nav chrome.
// 2. Use rootNavigatorKey for full-screen pushes over the shell
// 3. Auth redirects are automatic via GoRouter.redirect
// 4. Path params: state.pathParameters['key']
// 5. Update _paths in ResponsiveShell if adding new shell tabs
