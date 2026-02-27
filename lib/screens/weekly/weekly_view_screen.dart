import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/providers/weekly_provider.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/screens/weekly/plan_week_sheet.dart';

/// Weekly view screen — focused planning view for the current week.
class WeeklyViewScreen extends ConsumerWidget {
  const WeeklyViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekProvider);
    final allTasksAsync = ref.watch(allUserTasksProvider);
    final isCurrentWeek =
        mondayOf(DateTime.now()).isAtSameMomentAs(weekStart);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: allTasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Could not load tasks',
                style: GoogleFonts.inter(fontSize: 14, color: colors.onSurface),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(allUserTasksProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (_) {
          final weeklyTasks = ref.watch(weeklyTasksProvider);
          final myTasks = ref.watch(myWeeklyTasksProvider);
          final nextUp = ref.watch(nextUpTasksProvider);
          final summary = ref.watch(weeklySummaryProvider);

          return RefreshIndicator(
            color: colors.primary,
            onRefresh: () async {
              ref.invalidate(allUserTasksProvider);
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              slivers: [
                // ── Header with week navigation ─────────────
                SliverToBoxAdapter(
                  child: _WeekHeader(weekStart: weekStart),
                ),

                // ── Weekly Summary Card ─────────────────────
                SliverToBoxAdapter(
                  child: _WeeklySummaryCard(
                    total: summary.total,
                    completed: summary.completed,
                  ),
                ),

                // ── End-of-week prompt ──────────────────────
                if (isCurrentWeek && _isWeekEnd())
                  SliverToBoxAdapter(
                    child: _EndOfWeekPrompt(weekStart: weekStart),
                  ),

                // ── "Our Week Plan" section ─────────────────
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Our Week Plan',
                    icon: Icons.people_outline,
                    count: weeklyTasks.length,
                  ),
                ),
                if (weeklyTasks.isEmpty)
                  const SliverToBoxAdapter(
                    child: _EmptySectionHint(
                      message: 'No tasks planned for this week yet.',
                    ),
                  )
                else
                  _TaskListSliver(tasks: weeklyTasks),

                // ── "My Tasks" section ──────────────────────
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'My Tasks',
                    icon: Icons.person_outline,
                    count: myTasks.length,
                  ),
                ),
                if (myTasks.isEmpty)
                  const SliverToBoxAdapter(
                    child: _EmptySectionHint(
                      message: 'No tasks assigned to you this week.',
                    ),
                  )
                else
                  _TaskListSliver(tasks: myTasks),

                // ── "Next Up" section ───────────────────────
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Next Up',
                    icon: Icons.upcoming_outlined,
                    count: nextUp.length,
                  ),
                ),
                if (nextUp.isEmpty)
                  const SliverToBoxAdapter(
                    child: _EmptySectionHint(
                      message: 'No upcoming tasks due in the next 7 days.',
                    ),
                  )
                else
                  _TaskListSliver(tasks: nextUp),

                // Bottom padding for FAB
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlanWeekSheet(context),
        icon: const Icon(Icons.edit_calendar),
        label: const Text('Plan Week'),
      ),
    );
  }

  void _showPlanWeekSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const PlanWeekSheet(),
    );
  }

  static bool _isWeekEnd() {
    final weekday = DateTime.now().weekday;
    return weekday >= DateTime.friday;
  }
}

// ── Week Header with Navigation ──────────────────────────────────────

class _WeekHeader extends ConsumerWidget {
  const _WeekHeader({required this.weekStart});
  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM d');
    final label =
        '${dateFormat.format(weekStart)} \u{2013} ${dateFormat.format(weekEnd)}';
    final isCurrentWeek =
        mondayOf(DateTime.now()).isAtSameMomentAs(weekStart);
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () =>
                    ref.read(selectedWeekProvider.notifier).goToPreviousWeek(),
                icon: const Icon(Icons.chevron_left),
                color: colors.primary,
                tooltip: 'Previous week',
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    ref.read(selectedWeekProvider.notifier).goToNextWeek(),
                icon: const Icon(Icons.chevron_right),
                color: colors.primary,
                tooltip: 'Next week',
              ),
            ],
          ),
          if (!isCurrentWeek)
            Center(
              child: TextButton(
                onPressed: () =>
                    ref.read(selectedWeekProvider.notifier).goToCurrentWeek(),
                child: Text(
                  'Back to this week',
                  style: GoogleFonts.inter(fontSize: 13, color: colors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Weekly Summary Card ──────────────────────────────────────────────

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({required this.total, required this.completed});
  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final allDone = total > 0 && completed == total;
    final progress = total > 0 ? completed / total : 0.0;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shadowColor: isDark ? AppColors.darkCardShadow : AppColors.cardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    allDone ? Icons.celebration : Icons.bar_chart_rounded,
                    color: allDone ? AppColors.accentWarm : colors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      allDone
                          ? 'You did it all! \u{1F389}'
                          : total == 0
                              ? 'No tasks planned yet'
                              : 'You\'ve completed $completed of $total tasks this week!',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: colors.primaryContainer,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      allDone ? AppColors.accentWarm : colors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.count,
  });
  final String title;
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Section Hint ───────────────────────────────────────────────

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ── Task List Sliver ─────────────────────────────────────────────────

class _TaskListSliver extends StatelessWidget {
  const _TaskListSliver({required this.tasks});
  final List<({String spaceId, TaskModel task})> tasks;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _WeeklyTaskCard(entry: tasks[index]),
          childCount: tasks.length,
        ),
      ),
    );
  }
}

// ── Weekly Task Card ─────────────────────────────────────────────────

class _WeeklyTaskCard extends StatelessWidget {
  const _WeeklyTaskCard({required this.entry});
  final ({String spaceId, TaskModel task}) entry;

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    final isDone = task.status == 'done';
    final statusLabel = StatusDisplayName.fromStatus(task.status);
    final hasOverdueDueDate =
        task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) && !isDone;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shadowColor: isDark ? AppColors.darkCardShadow : AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/spaces/${entry.spaceId}/task/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor(task.status),
                ),
              ),
              const SizedBox(width: 12),

              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDone
                            ? colors.onSurface.withValues(alpha: 0.5)
                            : colors.onSurface,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(task.status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _statusColor(task.status),
                            ),
                          ),
                        ),
                        if (task.dueDate != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: hasOverdueDueDate
                                ? colors.error
                                : colors.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d').format(task.dueDate!),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: hasOverdueDueDate
                                  ? colors.error
                                  : colors.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Emoji tag
              if (task.emojiTag != null && task.emojiTag!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(task.emojiTag!, style: const TextStyle(fontSize: 18)),
                ),

              Icon(
                Icons.chevron_right,
                color: colors.onSurface.withValues(alpha: 0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return const Color(0xFF4CAF50);
      case 'in_progress':
        return AppColors.accentWarm;
      default:
        return AppColors.statusTodo;
    }
  }
}

// ── End-of-Week Prompt ───────────────────────────────────────────────

class _EndOfWeekPrompt extends ConsumerWidget {
  const _EndOfWeekPrompt({required this.weekStart});
  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: AppColors.accentWarm.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('\u{1F4C5}', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Want to plan next week together?',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick tasks for next week and stay on track!',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to next week then open plan sheet
                  ref.read(selectedWeekProvider.notifier).goToNextWeek();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => const PlanWeekSheet(),
                  );
                },
                child: const Text('Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
