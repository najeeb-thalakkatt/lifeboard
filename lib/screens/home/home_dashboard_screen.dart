import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/dashboard_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/theme/app_colors.dart';

/// Home dashboard showing all user spaces with previews.
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final spacesAsync = ref.watch(userSpacesProvider);

    final firebaseUser = ref.watch(authStateProvider).valueOrNull;

    final displayName = userAsync.whenOrNull(
          data: (user) => user?.displayName,
        ) ??
        firebaseUser?.displayName ??
        '';

    final firstName = displayName.split(' ').first;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [AppColors.darkGradientTop, AppColors.darkGradientBottom]
        : [AppColors.gradientTop, AppColors.gradientBottom];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () async {
            ref.invalidate(userSpacesProvider);
            ref.invalidate(currentUserProvider);
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              // ── Welcome Header ──────────────────────────────────
              SliverToBoxAdapter(
                child: _WelcomeHeader(firstName: firstName),
              ),

              // ── Space List ──────────────────────────────────────
              spacesAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: _ErrorView(
                    message: 'Could not load spaces',
                    onRetry: () => ref.invalidate(userSpacesProvider),
                  ),
                ),
                data: (spaces) {
                  if (spaces.isEmpty) {
                    return const SliverFillRemaining(
                      child: _EmptySpacesView(),
                    );
                  }
                  return _SpaceGridSliver(spaces: spaces);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/create-space'),
        icon: const Icon(Icons.add),
        label: const Text('New Space'),
      ),
    );
  }
}

// ── Welcome Header ────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstName.isNotEmpty
                ? 'Welcome back, $firstName \u{1F44B}'
                : 'Welcome back \u{1F44B}',
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your spaces',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Responsive Space Grid ─────────────────────────────────────────

class _SpaceGridSliver extends StatelessWidget {
  const _SpaceGridSliver({required this.spaces});
  final List<SpaceModel> spaces;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final crossAxisCount = _columnsForWidth(width);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: crossAxisCount == 1 ? 1.9 : 1.3,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _SpaceCard(
                space: spaces[index],
                accentColor: AppColors.spaceAccents[
                    index % AppColors.spaceAccents.length],
              ),
              childCount: spaces.length,
            ),
          );
        },
      ),
    );
  }

  int _columnsForWidth(double width) {
    if (width >= 1024) return 3; // Desktop
    if (width >= 600) return 2; // Tablet
    return 1; // Mobile
  }
}

// ── Space Card ────────────────────────────────────────────────────

class _SpaceCard extends ConsumerWidget {
  const _SpaceCard({required this.space, this.accentColor});
  final SpaceModel space;
  final Color? accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberCount = space.members.length;
    final timeAgo = _formatTimeAgo(space.createdAt);
    final summaryAsync = ref.watch(spaceTaskSummaryProvider(space.id));
    final accent = accentColor ?? Theme.of(context).colorScheme.primary;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shadowColor: isDark ? AppColors.darkCardShadow : AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.go('/spaces/${space.id}');
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored left accent bar
              Container(width: 5, color: accent),
              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Icon + Name Row ─────────────────────────────
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.workspaces_outlined,
                              color: accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              space.name,
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: colors.onSurface.withValues(alpha: 0.4),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // ── Task Summary Row ────────────────────────────
                      summaryAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (summary) {
                          if (summary.totalCount == 0) {
                            return Text(
                              'No tasks yet',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colors.onSurface.withValues(alpha: 0.5),
                              ),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${summary.todoCount} to do, ${summary.inProgressCount} in progress',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color:
                                      colors.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Mini progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: summary.completionPercent,
                                  minHeight: 4,
                                  backgroundColor: colors.primaryContainer,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(accent),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 8),

                      // ── Meta Info ───────────────────────────────────
                      Row(
                        children: [
                          _MetaChip(
                            icon: Icons.people_outline,
                            label:
                                '$memberCount member${memberCount == 1 ? '' : 's'}',
                          ),
                          const SizedBox(width: 12),
                          _MetaChip(
                            icon: Icons.access_time,
                            label: timeAgo,
                          ),
                        ],
                      ),

                      // ── Themes Preview ──────────────────────────────
                      if (space.themes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: space.themes.take(3).map((theme) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                theme,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 30) {
      return DateFormat.yMMMd().format(date);
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'just now';
  }
}

// ── Meta Chip ─────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
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
              'Ready to plan together?',
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
