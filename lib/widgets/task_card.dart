import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/avatar_widget.dart';

/// A card displaying a task's title, emoji tag, assignees, and due date.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.memberNames = const {},
  });

  final TaskModel task;
  final VoidCallback? onTap;

  /// Map of userId → displayName for showing assignee avatars.
  final Map<String, String> memberNames;

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.statusAccent(task.status);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.darkCardShadow : AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status accent bar
              Container(width: 4, color: accentColor),
              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with emoji tag
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: colors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (task.emojiTag != null) ...[
                            const SizedBox(width: 8),
                            Text(task.emojiTag!,
                                style: const TextStyle(fontSize: 18)),
                          ],
                        ],
                      ),

                      // Subtask progress
                      if (task.subtasks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _SubtaskProgress(subtasks: task.subtasks),
                      ],

                      // Bottom row: assignees + due date
                      if (task.assignees.isNotEmpty ||
                          task.dueDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Assignee avatars (stacked)
                            if (task.assignees.isNotEmpty)
                              _AssigneeAvatars(
                                assignees: task.assignees,
                                memberNames: memberNames,
                              ),
                            const Spacer(),
                            // Due date chip
                            if (task.dueDate != null)
                              _DueDateChip(date: task.dueDate!),
                          ],
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
}

class _SubtaskProgress extends StatelessWidget {
  const _SubtaskProgress({required this.subtasks});
  final List<Subtask> subtasks;

  @override
  Widget build(BuildContext context) {
    final completed = subtasks.where((s) => s.completed).length;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(Icons.checklist, size: 14, color: onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          '$completed/${subtasks.length}',
          style: AppTextStyles.caption.copyWith(
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _AssigneeAvatars extends StatelessWidget {
  const _AssigneeAvatars({
    required this.assignees,
    required this.memberNames,
  });
  final List<String> assignees;
  final Map<String, String> memberNames;

  @override
  Widget build(BuildContext context) {
    // Show up to 3 avatars, stacked with overlap.
    final visible = assignees.take(3).toList();
    return SizedBox(
      width: 16.0 * visible.length + 12,
      height: 24,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * 16.0,
              child: AvatarWidget(
                name: memberNames[visible[i]] ?? '?',
                radius: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  const _DueDateChip({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isOverdue = date.isBefore(DateTime.now());
    final colors = Theme.of(context).colorScheme;
    final color = isOverdue ? colors.error : colors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today, size: 12, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          DateFormat('MMM d').format(date),
          style: AppTextStyles.caption.copyWith(
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
