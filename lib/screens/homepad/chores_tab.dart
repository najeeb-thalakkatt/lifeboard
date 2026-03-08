import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/models/chore_model.dart';
import 'package:lifeboard/providers/chore_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/screens/homepad/add_chore_sheet.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/chore_card.dart';
import 'package:lifeboard/widgets/stagger_animation.dart';

/// The chores tab content within HomePad.
class ChoresTab extends ConsumerStatefulWidget {
  const ChoresTab({super.key, required this.spaceId});
  final String spaceId;

  @override
  ConsumerState<ChoresTab> createState() => _ChoresTabState();
}

class _ChoresTabState extends ConsumerState<ChoresTab> {
  bool _doneSectionExpanded = true;

  String get spaceId => widget.spaceId;

  @override
  Widget build(BuildContext context) {
    final choresAsync = ref.watch(choresStreamProvider(spaceId));
    final todayChores = ref.watch(todayChoresProvider(spaceId));
    final upcomingChores = ref.watch(upcomingChoresProvider(spaceId));
    final completionsAsync = ref.watch(todayCompletionsProvider(spaceId));
    final completions = completionsAsync.valueOrNull ?? [];
    final memberProfiles = ref.watch(spaceMemberProfilesProvider(spaceId));
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return choresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Could not load chores',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Something went wrong. Give it another try!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(choresStreamProvider(spaceId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (allChores) {
        // Empty state — no chores at all
        if (allChores.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.choreAllCaughtUp,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.choreAddFirst,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // All done today empty state
        final allDoneToday =
            todayChores.isEmpty && completions.isNotEmpty;

        return CustomScrollView(
          slivers: [
            // ── "Today's Focus" Section ──────────────────────────
            if (todayChores.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: AppConstants.choreTodaysFocus,
                  count: todayChores.length,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chore = todayChores[index];
                    return StaggeredListItem(
                      index: index,
                      child: ChoreCard(
                        chore: chore,
                        assigneeName: chore.assigneeId != null
                            ? memberProfiles[chore.assigneeId]
                            : null,
                        onComplete: () =>
                            _completeChore(context, chore),
                        onSkip: () => _skipChore(context, chore),
                        onEdit: () =>
                            _showEditChoreSheet(context, chore),
                        onDelete: () =>
                            _deleteChore(context, chore),
                      ),
                    );
                  },
                  childCount: todayChores.length,
                ),
              ),
            ],

            // ── All Done Today — banner card ──────────────────
            if (allDoneToday)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.statusDone.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.statusDone.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppConstants.choreAllCaughtUpBanner,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Nothing Due Today — with next chore hint ────────
            if (todayChores.isEmpty && completions.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🌿', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.choreFreeDay,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                              ),
                            ),
                            if (upcomingChores.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Builder(builder: (context) {
                                final next = upcomingChores.first;
                                final now = DateTime.now();
                                final today = DateTime(
                                    now.year, now.month, now.day);
                                final dueDay = DateTime(
                                  next.nextDueDate.year,
                                  next.nextDueDate.month,
                                  next.nextDueDate.day,
                                );
                                final daysAway = dueDay
                                    .difference(today)
                                    .inDays;
                                final label = daysAway == 1
                                    ? 'tomorrow'
                                    : 'in $daysAway days';
                                return Text(
                                  'Next up: ${next.name} $label',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── "Coming Up" Section ─────────────────────────────
            if (upcomingChores.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: AppConstants.choreComingUp,
                  count: upcomingChores.length,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chore = upcomingChores[index];
                    return ChoreCard(
                      chore: chore,
                      assigneeName: chore.assigneeId != null
                          ? memberProfiles[chore.assigneeId]
                          : null,
                      isUpcoming: true,
                      onComplete: () =>
                          _completeChore(context, chore),
                      onSkip: () => _skipChore(context, chore),
                      onEdit: () =>
                          _showEditChoreSheet(context, chore),
                      onDelete: () =>
                          _deleteChore(context, chore),
                    );
                  },
                  childCount: upcomingChores.length,
                ),
              ),
            ],

            // ── "Done Today" Section ────────────────────────────
            if (completions.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => setState(
                      () => _doneSectionExpanded = !_doneSectionExpanded),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 16, top: 20, right: 12),
                    child: Row(
                      children: [
                        Text(
                          AppConstants.choreDoneToday,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${completions.length}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _doneSectionExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_doneSectionExpanded)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final comp = completions[index];
                      return DoneChoreCard(
                        emoji: comp.choreEmoji,
                        name: comp.choreName,
                        completedByName:
                            memberProfiles[comp.completedBy] ?? 'Someone',
                        completedAt: comp.completedAt,
                        hatTipBy: comp.hatTipBy,
                        currentUserId: currentUserId,
                        completedByUserId: comp.completedBy,
                        onHatTip: () {
                          ref.read(choreActionProvider.notifier).hatTip(
                                spaceId: spaceId,
                                completionId: comp.id,
                              );
                        },
                      );
                    },
                    childCount: completions.length,
                  ),
                ),
            ],

            // Bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
    );
  }

  void _showEditChoreSheet(BuildContext context, Chore chore) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          AddChoreSheet(spaceId: spaceId, existingChore: chore),
    );
  }

  Future<void> _completeChore(BuildContext context, Chore chore) async {
    final previousDueDate = chore.nextDueDate;

    final completion = await ref
        .read(choreActionProvider.notifier)
        .completeChore(spaceId: spaceId, chore: chore);

    if (completion != null && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${chore.emoji} ${chore.name} done!'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref.read(choreActionProvider.notifier).undoCompletion(
                    spaceId: spaceId,
                    completionId: completion.id,
                    choreId: chore.id,
                    previousNextDueDate: previousDueDate,
                  );
            },
          ),
        ),
      );
    }
  }

  Future<void> _deleteChore(BuildContext context, Chore chore) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chore?'),
        content: Text('Are you sure you want to delete "${chore.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(choreActionProvider.notifier).deleteChore(
            spaceId: spaceId,
            choreId: chore.id,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${chore.emoji} ${chore.name} deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _skipChore(BuildContext context, Chore chore) {
    ref.read(choreActionProvider.notifier).skipChore(
          spaceId: spaceId,
          chore: chore,
        );
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${chore.emoji} ${chore.name} skipped'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4, right: 16),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

