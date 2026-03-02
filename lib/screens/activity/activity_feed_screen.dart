import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lifeboard/models/activity_model.dart';
import 'package:lifeboard/providers/activity_provider.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/widgets/stagger_animation.dart';

/// Activity feed screen showing chronological activity across all spaces.
class ActivityFeedScreen extends ConsumerStatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  ConsumerState<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends ConsumerState<ActivityFeedScreen> {
  @override
  void initState() {
    super.initState();
    // Mark activity as read when user opens the tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activityActionProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(activityFeedProvider);
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
            ref.invalidate(activityFeedProvider);
            await ref.read(activityActionProvider.notifier).markAllRead();
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ActivityHeader(),
              ),

              // ── Feed ──────────────────────────────────────────
              activityAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: _ErrorView(
                    onRetry: () => ref.invalidate(activityFeedProvider),
                  ),
                ),
                data: (activities) {
                  if (activities.isEmpty) {
                    return const SliverFillRemaining(
                      child: _EmptyActivityView(),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final activity = activities[index];
                          return StaggeredListItem(
                            index: index,
                            child: _ActivityCard(activity: activity),
                          );
                        },
                        childCount: activities.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────

class _ActivityHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity',
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What\u2019s happening across your spaces',
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

// ── Activity Card ────────────────────────────────────────────────────

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({required this.activity});
  final ActivityModel activity;

  static const _typeIcons = {
    'task_created': Icons.add_circle_outline,
    'task_moved': Icons.swap_horiz,
    'task_completed': Icons.check_circle_outline,
    'comment_added': Icons.chat_bubble_outline,
    'member_joined': Icons.person_add_outlined,
  };

  static const _typeColors = {
    'task_created': AppColors.statusTodo,
    'task_moved': AppColors.statusInProgress,
    'task_completed': AppColors.statusDone,
    'comment_added': AppColors.primaryDark,
    'member_joined': AppColors.accentWarm,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final icon = _typeIcons[activity.type] ?? Icons.notifications_outlined;
    final accentColor = _typeColors[activity.type] ?? colors.primary;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Card(
      elevation: 1,
      shadowColor: ext.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: activity.taskId != null
            ? () => context.go(
                  '/spaces/${activity.spaceId}/task/${activity.taskId}',
                )
            : null,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored left accent bar
              Container(width: 4, color: accentColor),
              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Activity type icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ActorName(
                                  actorId: activity.actorId,
                                  message: activity.message,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimeAgo(activity.createdAt),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colors.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Reactions row
                      if (activity.reactions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _ReactionsRow(
                          reactions: activity.reactions,
                          currentUserId: userId ?? '',
                          onToggle: (emoji) {
                            ref
                                .read(activityActionProvider.notifier)
                                .toggleReaction(
                                  spaceId: activity.spaceId,
                                  activityId: activity.id,
                                  emoji: emoji,
                                );
                          },
                        ),
                      ],
                      // Quick reaction button
                      const SizedBox(height: 6),
                      _QuickReactionBar(
                        onReact: (emoji) {
                          ref
                              .read(activityActionProvider.notifier)
                              .toggleReaction(
                                spaceId: activity.spaceId,
                                activityId: activity.id,
                                emoji: emoji,
                              );
                        },
                      ),
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
    if (diff.inDays > 7) {
      return DateFormat.MMMd().format(date);
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

// ── Actor Name (resolves user display name from Firestore) ───────────

class _ActorName extends ConsumerWidget {
  const _ActorName({required this.actorId, required this.message});
  final String actorId;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    // Try to resolve the display name from Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(actorId)
          .snapshots(),
      builder: (context, snapshot) {
        String name = 'Someone';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['displayName'] as String? ?? 'Someone';
          // Use first name only
          final parts = name.split(' ');
          if (parts.isNotEmpty) name = parts.first;
        }

        return RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.onSurface,
            ),
            children: [
              TextSpan(
                text: name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: ' $message'),
            ],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

// ── Reactions Row ────────────────────────────────────────────────────

class _ReactionsRow extends StatelessWidget {
  const _ReactionsRow({
    required this.reactions,
    required this.currentUserId,
    required this.onToggle,
  });
  final Map<String, List<String>> reactions;
  final String currentUserId;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: reactions.entries.map((entry) {
        final emoji = entry.key;
        final users = entry.value;
        final isMine = users.contains(currentUserId);

        return GestureDetector(
          onTap: () => onToggle(emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isMine
                  ? colors.primary.withValues(alpha: 0.15)
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: isMine
                  ? Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: Text(
              '$emoji ${users.length}',
              style: GoogleFonts.inter(fontSize: 13),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Quick Reaction Bar ───────────────────────────────────────────────

class _QuickReactionBar extends StatelessWidget {
  const _QuickReactionBar({required this.onReact});
  final ValueChanged<String> onReact;

  static const _emojis = ['\u2764\uFE0F', '\uD83D\uDC4D', '\uD83D\uDE02', '\uD83D\uDE05'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _emojis.map((emoji) {
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onReact(emoji),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────

class _EmptyActivityView extends StatelessWidget {
  const _EmptyActivityView();

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
                Icons.notifications_none,
                size: 40,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'All quiet here',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activity from your spaces will\nshow up here as it happens.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View ───────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
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
              'Could not load activity',
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
