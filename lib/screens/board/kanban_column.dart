import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/models/task_model.dart';
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
    this.onTaskTap,
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

  /// Called when a task card is tapped.
  final void Function(TaskModel task)? onTaskTap;

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
            color: _isDragOver
                ? AppColors.primaryLight.withValues(alpha: 0.8)
                : AppColors.primaryLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: _isDragOver
                ? Border.all(color: AppColors.primaryDark, width: 2)
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header
              Row(
                children: [
                  Expanded(
                    child: Text(label, style: AppTextStyles.headingSmall),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.tasks.length}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Task list
              Expanded(
                child: widget.tasks.isEmpty && !_isDragOver
                    ? _EmptyColumnHint(status: widget.status)
                    : ListView.builder(
                        itemCount: widget.tasks.length,
                        itemBuilder: (context, index) {
                          final task = widget.tasks[index];
                          return LongPressDraggable<TaskModel>(
                            data: task,
                            hapticFeedbackOnStart: true,
                            feedback: Material(
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
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: TaskCard(
                                task: task,
                                memberNames: widget.memberNames,
                              ),
                            ),
                            child: TaskCard(
                              task: task,
                              memberNames: widget.memberNames,
                              onTap: widget.onTaskTap != null
                                  ? () => widget.onTaskTap!(task)
                                  : null,
                            ),
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
                GestureDetector(
                  onTap: () {
                    setState(() => _isAddingTask = true);
                    // Focus after build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _addFocusNode.requestFocus();
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 18,
                        color: AppColors.primaryDark.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add task',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryDark.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
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
    final messages = {
      'todo': 'Nothing here yet.\nTap + to add a task!',
      'in_progress': 'Start working on\nsomething!',
      'done': 'Complete tasks will\nshow up here.',
    };

    return Center(
      child: Text(
        messages[status] ?? 'Drop tasks here',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primaryDark.withValues(alpha: 0.4),
        ),
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
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
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Task title...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryDark.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
            color: AppColors.primaryDark.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
