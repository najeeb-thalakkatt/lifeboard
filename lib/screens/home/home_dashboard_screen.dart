import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lifeboard/providers/space_provider.dart';

/// Key used to persist the last visited space ID.
const _lastSpaceKey = 'last_space_id';

/// Home dashboard — auto-redirects to the last visited space's board,
/// or the first space if no preference is saved.
class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    // If data is already cached (e.g. coming from another tab), redirect
    // immediately without waiting for the next stream event.
    final existing = ref.read(userSpacesProvider).valueOrNull;
    if (existing != null && existing.isNotEmpty) {
      _hasRedirected = true;
      _redirect(existing);
    }
    ref.listenManual(userSpacesProvider, (_, next) {
      if (_hasRedirected) return;
      final spaces = next.valueOrNull;
      if (spaces == null || spaces.isEmpty) return;

      _hasRedirected = true;
      _redirect(spaces);
    });
  }

  Future<void> _redirect(List spaces) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSpaceId = prefs.getString(_lastSpaceKey);
    final targetSpace = (lastSpaceId != null &&
            spaces.any((s) => s.id == lastSpaceId))
        ? lastSpaceId
        : spaces.first.id;
    if (mounted) {
      context.go('/spaces/$targetSpace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacesAsync = ref.watch(userSpacesProvider);

    return spacesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: _ErrorView(
          message: 'Could not load spaces',
          onRetry: () => ref.invalidate(userSpacesProvider),
        ),
      ),
      data: (spaces) {
        if (spaces.isEmpty) {
          return const Scaffold(body: _EmptySpacesView());
        }

        return const Scaffold(
          body: SizedBox.shrink(),
        );
      },
    );
  }
}

/// Saves the current space ID so we can restore it next time.
Future<void> saveLastSpaceId(String spaceId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastSpaceKey, spaceId);
}

// ── Empty State ───────────────────────────────────────────────────

class _EmptySpacesView extends StatelessWidget {
  const _EmptySpacesView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.workspaces_outlined,
                size: 40,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No spaces yet',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first space and start\norganizing life as a team.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/create-space'),
              icon: const Icon(Icons.add),
              label: const Text('Create a Space'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
