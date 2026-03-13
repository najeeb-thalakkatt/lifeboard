import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/task_card.dart';

/// A compact kanban column for the all-columns-on-screen layout.
///
/// Designed to fit 3 columns vertically on a single mobile screen with
/// drag-and-drop support between columns.
class CompactKanbanColumn extends StatefulWidget {
  const CompactKanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.memberNames,
    required this.onQuickAdd,
    this.wipLimit,
    this.isDragOver = false,
    this.isDragging = false,
    this.onTaskTap,
    this.onTaskCompleted,
    this.onTaskMoveToStatus,
    this.onTaskAssignToMe,
    this.onTaskArchive,
    this.onTaskDelete,
    this.onDragStarted,
    this.onDragEnd,
  });

  final String status;
  final List<TaskModel> tasks;
  final Map<String, String> memberNames;
  final void Function(String title) onQuickAdd;
  final int? wipLimit;
  final bool isDragOver;

  /// True when any task across the board is being dragged.
  /// Used to disable ListView scroll so drag can escape the column.
  final bool isDragging;
  final void Function(TaskModel task)? onTaskTap;
  final void Function(TaskModel task)? onTaskCompleted;
  final void Function(TaskModel task, String newStatus)? onTaskMoveToStatus;
  final void Function(TaskModel task)? onTaskAssignToMe;
  final void Function(TaskModel task)? onTaskArchive;
  final void Function(TaskModel task)? onTaskDelete;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  @override
  State<CompactKanbanColumn> createState() => _CompactKanbanColumnState();
}

class _CompactKanbanColumnState extends State<CompactKanbanColumn> {
  bool _isAddingTask = false;
  final _addController = TextEditingController();
  final _addFocusNode = FocusNode();

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  Widget _buildContextMenuWrapper({
    required BuildContext context,
    required TaskModel task,
    required Widget child,
  }) {
    if (kIsWeb) return child;

    final otherStatuses = ['todo', 'in_progress', 'done']
        .where((s) => s != widget.status)
        .toList();

    return CupertinoContextMenu(
      enableHapticFeedback: true,
      actions: [
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            widget.onTaskTap?.call(task);
          },
          trailingIcon: CupertinoIcons.pencil,
          child: const Text('Edit'),
        ),
        for (final status in otherStatuses)
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              widget.onTaskMoveToStatus?.call(task, status);
            },
            trailingIcon: status == 'done'
                ? CupertinoIcons.check_mark_circled
                : CupertinoIcons.arrow_right,
            child: Text(
                'Move to ${StatusDisplayName.fromStatus(status)}'),
          ),
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            widget.onTaskAssignToMe?.call(task);
          },
          trailingIcon: CupertinoIcons.person_add,
          child: const Text('Assign to Me'),
        ),
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            widget.onTaskArchive?.call(task);
          },
          trailingIcon: CupertinoIcons.archivebox,
          child: const Text('Archive'),
        ),
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            widget.onTaskDelete?.call(task);
          },
          trailingIcon: CupertinoIcons.delete,
          child: const Text('Delete'),
        ),
      ],
      child: child,
    );
  }

  void _submitQuickAdd() {
    final title = _addController.text.trim();
    if (title.isNotEmpty) {
      widget.onQuickAdd(title);
      _addController.clear();
    }
    setState(() => _isAddingTask = false);
  }

  /// Short labels for the compact header.
  static const _compactLabels = {
    'todo': 'To Do',
    'in_progress': 'Doing',
    'done': 'Done!',
  };

  @override
  Widget build(BuildContext context) {
    final label = _compactLabels[widget.status] ??
        StatusDisplayName.fromStatus(widget.status);
    final accentColor = AppColors.statusAccent(widget.status);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isDragOver = widget.isDragOver;
    final columnBg = isDark
        ? AppColors.darkCardSurface.withValues(alpha: isDragOver ? 0.8 : 0.4)
        : AppColors.primaryLight.withValues(alpha: isDragOver ? 0.8 : 0.4);

    return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: columnBg,
            borderRadius: BorderRadius.circular(14),
            border: isDragOver
                ? Border.all(color: colors.primary, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Compact header with accent strip ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Builder(builder: (context) {
                      final count = widget.tasks.length;
                      final limit = widget.wipLimit;
                      Color badgeColor;
                      if (limit == null) {
                        badgeColor = accentColor;
                      } else if (count < limit) {
                        badgeColor = AppColors.statusTodo;
                      } else if (count == limit) {
                        badgeColor = AppColors.statusInProgress;
                      } else {
                        badgeColor = AppColors.error;
                      }
                      final text = limit != null
                          ? '$count/$limit'
                          : '$count';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          text,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    // Inline quick-add button
                    GestureDetector(
                      onTap: () {
                        setState(() => _isAddingTask = true);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _addFocusNode.requestFocus();
                        });
                      },
                      child: Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Quick-add field (inline, slides in) ──
              if (_isAddingTask)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 34,
                          child: TextField(
                            controller: _addController,
                            focusNode: _addFocusNode,
                            style: AppTextStyles.caption.copyWith(
                              color: colors.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'New task...',
                              hintStyle: AppTextStyles.caption.copyWith(
                                color:
                                    colors.onSurface.withValues(alpha: 0.4),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color:
                                      colors.onSurface.withValues(alpha: 0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color:
                                      colors.onSurface.withValues(alpha: 0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colors.primary,
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              filled: true,
                              fillColor: colors.surface,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitQuickAdd(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _isAddingTask = false),
                        child: Icon(Icons.close, size: 16,
                            color: colors.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),

              // ── Task list ──
              Expanded(
                child: widget.tasks.isEmpty && !isDragOver
                    ? Center(
                        child: Text(
                          _emptyHints[widget.status] ?? 'Drop tasks here',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                      )
                    : ListView.builder(
                        // Disable scrolling while dragging so the
                        // vertical drag can escape the column bounds
                        // and reach other DragTargets.
                        physics: widget.isDragging
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        itemCount: widget.tasks.length,
                        itemBuilder: (context, index) {
                          final task = widget.tasks[index];
                          Widget card = _buildContextMenuWrapper(
                            context: context,
                            task: task,
                            child: _CompactTaskTile(
                              task: task,
                              memberNames: widget.memberNames,
                              onTap: widget.onTaskTap != null
                                  ? () => widget.onTaskTap!(task)
                                  : null,
                            ),
                          );

                          // Swipe-to-complete for non-done tasks
                          if (widget.status != 'done' &&
                              widget.onTaskCompleted != null) {
                            card = Dismissible(
                              key: ValueKey(task.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                unawaited(HapticFeedback.mediumImpact());
                                widget.onTaskCompleted!(task);
                                return false;
                              },
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.statusDone,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 20),
                              ),
                              child: card,
                            );
                          }

                          final feedback = Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width:
                                  MediaQuery.of(context).size.width * 0.65,
                              child: Opacity(
                                opacity: 0.9,
                                child: _CompactTaskTile(
                                  task: task,
                                  memberNames: widget.memberNames,
                                ),
                              ),
                            ),
                          );
                          final childWhenDragging = Opacity(
                            opacity: 0.3,
                            child: _CompactTaskTile(
                              task: task,
                              memberNames: widget.memberNames,
                            ),
                          );

                          // Use Draggable on web (click-drag) and
                          // LongPressDraggable on mobile (long-press-drag).
                          if (kIsWeb) {
                            return Draggable<TaskModel>(
                              data: task,
                              feedback: feedback,
                              childWhenDragging: childWhenDragging,
                              onDragStarted: widget.onDragStarted,
                              onDragEnd: (_) => widget.onDragEnd?.call(),
                              child: card,
                            );
                          }
                          return LongPressDraggable<TaskModel>(
                            data: task,
                            hapticFeedbackOnStart: true,
                            feedback: feedback,
                            childWhenDragging: childWhenDragging,
                            onDragStarted: widget.onDragStarted,
                            onDragEnd: (_) => widget.onDragEnd?.call(),
                            child: card,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
  }

  static const _emptyHints = {
    'todo': 'Tap + to add tasks',
    'in_progress': 'Drag tasks here',
    'done': 'Complete tasks land here',
  };
}

/// A compact task tile for the all-columns view — shorter than [TaskCard].
class _CompactTaskTile extends StatelessWidget {
  const _CompactTaskTile({
    required this.task,
    this.memberNames = const {},
    this.onTap,
  });

  final TaskModel task;
  final Map<String, String> memberNames;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = task.isBlocked
        ? AppColors.error
        : AppColors.statusAccent(task.status);
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: ext.cardShadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status accent bar
              Container(width: 3, color: accentColor),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      if (task.isBlocked) ...[
                        const Icon(Icons.block, size: 12,
                            color: AppColors.error),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          task.title,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            color: task.isBlocked
                                ? colors.onSurface.withValues(alpha: 0.7)
                                : colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (task.emojiTag != null) ...[
                        const SizedBox(width: 4),
                        Text(task.emojiTag!,
                            style: const TextStyle(fontSize: 14)),
                      ],
                      if (task.subtasks.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${task.subtasks.where((s) => s.completed).length}/${task.subtasks.length}',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color:
                                colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.calendar_today,
                          size: 10,
                          color: task.dueDate!.isBefore(DateTime.now())
                              ? colors.error
                              : colors.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          DateFormat('M/d').format(task.dueDate!),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: task.dueDate!.isBefore(DateTime.now())
                                ? colors.error
                                : colors.onSurface.withValues(alpha: 0.5),
                          ),
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
