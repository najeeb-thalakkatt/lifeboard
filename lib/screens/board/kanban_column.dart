import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/providers/board_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/task_card.dart';

/// A single kanban column displaying tasks of a given status.
class KanbanColumn extends StatefulWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.memberNames,
    required this.onTaskDropped,
    required this.onQuickAdd,
    this.wipLimit,
    this.spaceId,
    this.boardId,
    this.onTaskTap,
    this.onTaskCompleted,
    this.onDragStarted,
    this.onDragEnd,
    this.onArchiveCompleted,
    this.onTaskMoveToStatus,
    this.onTaskAssignToMe,
    this.onTaskArchive,
    this.onTaskDelete,
  });

  /// The status key for this column ('todo', 'in_progress', 'done').
  final String status;

  /// Tasks belonging to this column, pre-sorted by order.
  final List<TaskModel> tasks;

  /// Map of userId → displayName for assignee avatars.
  final Map<String, String> memberNames;

  /// Called when a task is dropped into this column.
  final void Function(TaskModel task) onTaskDropped;

  /// Called when the user submits a quick-add title.
  final void Function(String title) onQuickAdd;

  /// WIP limit for this column. Null means no limit.
  final int? wipLimit;

  /// Space ID (for WIP limit updates).
  final String? spaceId;

  /// Board ID (for WIP limit updates).
  final String? boardId;

  /// Called when a task card is tapped.
  final void Function(TaskModel task)? onTaskTap;

  /// Called when a task is swiped to complete.
  final void Function(TaskModel task)? onTaskCompleted;

  /// Called when a task drag begins (for showing drop-zone overlays).
  final VoidCallback? onDragStarted;

  /// Called when a task drag ends.
  final VoidCallback? onDragEnd;

  /// Called when the user taps "Archive completed" in the Done column.
  final VoidCallback? onArchiveCompleted;

  /// Called when user picks "Move to..." from context menu.
  final void Function(TaskModel task, String newStatus)? onTaskMoveToStatus;

  /// Called when user picks "Assign to Me" from context menu.
  final void Function(TaskModel task)? onTaskAssignToMe;

  /// Called when user picks "Archive" from context menu.
  final void Function(TaskModel task)? onTaskArchive;

  /// Called when user picks "Delete" from context menu.
  final void Function(TaskModel task)? onTaskDelete;

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  bool _isAddingTask = false;
  final _addController = TextEditingController();
  final _addFocusNode = FocusNode();
  bool _isDragOver = false;

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
        // Edit
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            widget.onTaskTap?.call(task);
          },
          trailingIcon: CupertinoIcons.pencil,
          child: const Text('Edit'),
        ),
        // Move to status
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
        // Assign to me
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            widget.onTaskAssignToMe?.call(task);
          },
          trailingIcon: CupertinoIcons.person_add,
          child: const Text('Assign to Me'),
        ),
        // Archive
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            widget.onTaskArchive?.call(task);
          },
          trailingIcon: CupertinoIcons.archivebox,
          child: const Text('Archive'),
        ),
        // Delete
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

  @override
  Widget build(BuildContext context) {
    final label = StatusDisplayName.fromStatus(widget.status);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final columnBg = isDark
        ? AppColors.darkCardSurface.withValues(alpha: _isDragOver ? 0.8 : 0.4)
        : AppColors.primaryLight.withValues(alpha: _isDragOver ? 0.8 : 0.4);

    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) {
        if (details.data.status != widget.status) {
          setState(() => _isDragOver = true);
        }
        return true;
      },
      onLeave: (_) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
        HapticFeedback.lightImpact();
        widget.onTaskDropped(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: columnBg,
            borderRadius: BorderRadius.circular(16),
            border: _isDragOver
                ? Border.all(color: colors.primary, width: 2)
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header with WIP limit indicator
              _ColumnHeader(
                label: label,
                taskCount: widget.tasks.length,
                wipLimit: widget.wipLimit,
                status: widget.status,
                spaceId: widget.spaceId,
                boardId: widget.boardId,
              ),
              // Archive button for done column
              if (widget.status == 'done' &&
                  widget.tasks.isNotEmpty &&
                  widget.onArchiveCompleted != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: widget.onArchiveCompleted,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.archive_outlined,
                          size: 14,
                          color: colors.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Archive completed',
                        style: AppTextStyles.caption.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Task list
              Expanded(
                child: widget.tasks.isEmpty && !_isDragOver
                    ? _EmptyColumnHint(status: widget.status)
                    : ListView.builder(
                        itemCount: widget.tasks.length,
                        itemBuilder: (context, index) {
                          final task = widget.tasks[index];
                          Widget taskCard = _buildContextMenuWrapper(
                            context: context,
                            task: task,
                            child: TaskCard(
                              task: task,
                              memberNames: widget.memberNames,
                              onTap: widget.onTaskTap != null
                                  ? () => widget.onTaskTap!(task)
                                  : null,
                              onToggleComplete:
                                  widget.onTaskCompleted != null
                                      ? () => widget.onTaskCompleted!(task)
                                      : null,
                            ),
                          );

                          // Swipe-to-complete for non-done tasks
                          if (widget.status != 'done' &&
                              widget.onTaskCompleted != null) {
                            taskCard = Dismissible(
                              key: ValueKey(task.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                unawaited(HapticFeedback.mediumImpact());
                                widget.onTaskCompleted!(task);
                                return false; // Don't remove — Firestore handles it
                              },
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.statusDone,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 28),
                              ),
                              child: taskCard,
                            );
                          }

                          final feedback = Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: Opacity(
                                opacity: 0.9,
                                child: TaskCard(
                                  task: task,
                                  memberNames: widget.memberNames,
                                ),
                              ),
                            ),
                          );
                          final childWhenDragging = Opacity(
                            opacity: 0.3,
                            child: TaskCard(
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
                              child: taskCard,
                            );
                          }
                          return LongPressDraggable<TaskModel>(
                            data: task,
                            hapticFeedbackOnStart: true,
                            feedback: feedback,
                            childWhenDragging: childWhenDragging,
                            onDragStarted: widget.onDragStarted,
                            onDragEnd: (_) => widget.onDragEnd?.call(),
                            child: taskCard,
                          );
                        },
                      ),
              ),

              // Quick-add section
              const SizedBox(height: 8),
              if (_isAddingTask)
                _QuickAddField(
                  controller: _addController,
                  focusNode: _addFocusNode,
                  onSubmit: _submitQuickAdd,
                  onCancel: () => setState(() => _isAddingTask = false),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _isAddingTask = true);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _addFocusNode.requestFocus();
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add task'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurface.withValues(alpha: 0.6),
                      side: BorderSide(
                        color: colors.onSurface.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyColumnHint extends StatelessWidget {
  const _EmptyColumnHint({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final emojis = {
      'todo': '\u{1F4DD}',
      'in_progress': '\u{1F3C3}',
      'done': '\u{1F389}',
    };
    final messages = {
      'todo': 'Nothing here yet\nTap below to add a task!',
      'in_progress': 'Nothing here yet\nPick something to work on today!',
      'done': 'Nothing here yet\nFinished tasks land here!',
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emojis[status] ?? '\u{1F4CB}',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            messages[status] ?? 'Drop tasks here',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Column header showing label, task count, and WIP limit indicator.
class _ColumnHeader extends ConsumerWidget {
  const _ColumnHeader({
    required this.label,
    required this.taskCount,
    required this.wipLimit,
    required this.status,
    this.spaceId,
    this.boardId,
  });

  final String label;
  final int taskCount;
  final int? wipLimit;
  final String status;
  final String? spaceId;
  final String? boardId;

  Color _wipColor(ColorScheme colors) {
    if (wipLimit == null) return colors.primary;
    if (taskCount < wipLimit!) return AppColors.statusTodo; // teal — under
    if (taskCount == wipLimit!) return AppColors.statusInProgress; // orange — at limit
    return AppColors.error; // red — over
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final countColor = _wipColor(colors);
    final countText = wipLimit != null
        ? '$taskCount/$wipLimit'
        : '$taskCount';

    return GestureDetector(
      onLongPress: (spaceId != null && boardId != null)
          ? () => _showWipLimitPicker(context, ref)
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.headingSmall.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: countColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              countText,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: countColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWipLimitPicker(BuildContext context, WidgetRef ref) {
    final currentLimit = wipLimit ?? 0; // 0 = no limit
    int selectedLimit = currentLimit;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: 280,
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(ctx),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      Text(
                        'WIP Limit',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Save'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _saveWipLimit(ref, selectedLimit);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Picker
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 36,
                    scrollController: FixedExtentScrollController(
                      initialItem: currentLimit,
                    ),
                    onSelectedItemChanged: (index) {
                      selectedLimit = index;
                    },
                    children: [
                      const Center(child: Text('No limit')),
                      for (var i = 1; i <= 10; i++)
                        Center(child: Text('$i')),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveWipLimit(WidgetRef ref, int limit) {
    if (spaceId == null || boardId == null) return;
    final boardAsync = ref.read(boardStreamProvider(
        (spaceId: spaceId!, boardId: boardId!)));
    final currentLimits = Map<String, int>.from(
        boardAsync.valueOrNull?.wipLimits ?? {});

    if (limit == 0) {
      currentLimits.remove(status);
    } else {
      currentLimits[status] = limit;
    }

    ref.read(firestoreServiceProvider).updateBoardWipLimits(
      spaceId: spaceId!,
      boardId: boardId!,
      wipLimits: currentLimits,
    );
  }
}

class _QuickAddField extends StatelessWidget {
  const _QuickAddField({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ext.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Task title...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                fillColor: Colors.transparent,
                filled: true,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
