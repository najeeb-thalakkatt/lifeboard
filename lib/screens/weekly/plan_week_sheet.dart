import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/providers/weekly_provider.dart';
import 'package:lifeboard/theme/app_colors.dart';

/// Bottom sheet for selecting backlog tasks to add to the weekly plan.
class PlanWeekSheet extends ConsumerStatefulWidget {
  const PlanWeekSheet({super.key});

  @override
  ConsumerState<PlanWeekSheet> createState() => _PlanWeekSheetState();
}

class _PlanWeekSheetState extends ConsumerState<PlanWeekSheet> {
  /// Set of (spaceId, taskId) pairs toggled ON by the user.
  final _selected = <(String, String)>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-select tasks whose dueDate falls within the selected week.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preselectDueDateTasks();
    });
  }

  void _preselectDueDateTasks() {
    final weekStart = ref.read(selectedWeekProvider);
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
    final backlog = ref.read(backlogTasksProvider);

    final autoSelected = <(String, String)>{};
    for (final entry in backlog) {
      final due = entry.task.dueDate;
      if (due != null && !due.isBefore(weekStart) && !due.isAfter(weekEnd)) {
        autoSelected.add((entry.spaceId, entry.task.id));
      }
    }
    if (autoSelected.isNotEmpty && mounted) {
      setState(() => _selected.addAll(autoSelected));
    }
  }

  Future<void> _addToWeek() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);

    final weekStart = ref.read(selectedWeekProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    // Group selected tasks by spaceId for batch updates.
    final bySpace = <String, List<String>>{};
    for (final (spaceId, taskId) in _selected) {
      bySpace.putIfAbsent(spaceId, () => []).add(taskId);
    }

    try {
      for (final entry in bySpace.entries) {
        await firestoreService.batchSetWeeklyTasks(
          spaceId: entry.key,
          taskIds: entry.value,
          isWeeklyTask: true,
          weekStart: weekStart,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = ref.watch(selectedWeekProvider);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM d');
    final weekLabel =
        '${dateFormat.format(weekStart)} \u{2013} ${dateFormat.format(weekEnd)}';

    final backlog = ref.watch(backlogTasksProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── Handle ────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'Plan Your Week',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weekLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Task list ─────────────────────────────────────
            Expanded(
              child: backlog.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: AppColors.textPrimary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No backlog tasks available',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color:
                                    AppColors.textPrimary.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create tasks on your boards first.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color:
                                    AppColors.textPrimary.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: backlog.length,
                      itemBuilder: (context, index) {
                        final entry = backlog[index];
                        final key = (entry.spaceId, entry.task.id);
                        final isSelected = _selected.contains(key);

                        return _BacklogTaskTile(
                          task: entry.task,
                          isSelected: isSelected,
                          onToggle: () {
                            setState(() {
                              if (isSelected) {
                                _selected.remove(key);
                              } else {
                                _selected.add(key);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),

            // ── Bottom action bar ─────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed:
                        _selected.isEmpty || _saving ? null : _addToWeek,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _selected.isEmpty
                                ? 'Select tasks to plan'
                                : 'Add ${_selected.length} task${_selected.length == 1 ? '' : 's'} to This Week',
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Backlog Task Tile ────────────────────────────────────────────────

class _BacklogTaskTile extends StatelessWidget {
  const _BacklogTaskTile({
    required this.task,
    required this.isSelected,
    required this.onToggle,
  });
  final TaskModel task;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 2 : 0,
      shadowColor: AppColors.cardShadow,
      color: isSelected ? AppColors.primaryLight : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryDark.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primaryDark : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
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
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: AppColors.textPrimary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${DateFormat('MMM d').format(task.dueDate!)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Emoji tag
              if (task.emojiTag != null && task.emojiTag!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child:
                      Text(task.emojiTag!, style: const TextStyle(fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
