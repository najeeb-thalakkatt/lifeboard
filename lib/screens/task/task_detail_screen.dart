import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/models/user_model.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/providers/task_provider.dart';
import 'package:lifeboard/services/firestore_service.dart';
import 'package:lifeboard/services/storage_service.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/avatar_widget.dart';
import 'package:lifeboard/widgets/celebration_overlay.dart';
import 'package:lifeboard/widgets/comments_section.dart';
import 'package:lifeboard/widgets/emoji_tag_picker.dart';
import 'package:lifeboard/widgets/stagger_animation.dart';

/// Streams a single task by spaceId + taskId.
final taskDetailProvider = StreamProvider.family<TaskModel?,
    ({String spaceId, String taskId})>((ref, params) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamTask(
    spaceId: params.spaceId,
    taskId: params.taskId,
  );
});

/// Rich task editing screen — the shared note experience.
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.spaceId,
    required this.taskId,
  });

  final String spaceId;
  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtaskController = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _titleDebounce;
  Timer? _descriptionDebounce;
  bool _titleInitialized = false;
  bool _descriptionInitialized = false;
  bool _showTitleInAppBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _titleDebounce?.cancel();
    _descriptionDebounce?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show title in AppBar once user scrolls past the title field (~60px)
    final show = _scrollController.offset > 60;
    if (show != _showTitleInAppBar) {
      setState(() => _showTitleInAppBar = show);
    }
  }

  void _onTitleChanged(String value) {
    _titleDebounce?.cancel();
    _titleDebounce = Timer(const Duration(milliseconds: 800), () {
      if (value.trim().isNotEmpty) {
        _updateField({'title': value.trim()});
      }
    });
  }

  void _onDescriptionChanged(String value) {
    _descriptionDebounce?.cancel();
    _descriptionDebounce = Timer(const Duration(milliseconds: 800), () {
      _updateField({'description': value.isEmpty ? null : value});
    });
  }

  void _updateField(Map<String, dynamic> fields) {
    ref.read(taskActionProvider.notifier).updateTask(
          spaceId: widget.spaceId,
          taskId: widget.taskId,
          fields: fields,
        );
  }

  void _onStatusChanged(String newStatus, TaskModel task) {
    HapticFeedback.selectionClick();
    final fields = <String, dynamic>{'status': newStatus};
    if (newStatus == 'done') {
      fields['completedAt'] = Timestamp.fromDate(DateTime.now());
    } else {
      fields['completedAt'] = null;
    }
    _updateField(fields);
    if (newStatus == 'done' && task.status != 'done') {
      CelebrationOverlay.show(context);
    }
  }

  Future<void> _pickDueDate(TaskModel task) async {
    DateTime tempDate = task.dueDate ?? DateTime.now();
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _clearDueDate();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear',
                        style: TextStyle(color: AppColors.error)),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _updateField(
                          {'dueDate': Timestamp.fromDate(tempDate)});
                      Navigator.pop(context);
                    },
                    child: const Text('Done',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: task.dueDate ?? DateTime.now(),
                onDateTimeChanged: (date) => tempDate = date,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearDueDate() => _updateField({'dueDate': null});

  void _onAssigneesChanged(List<String> memberIds) {
    HapticFeedback.selectionClick();
    _updateField({'assignees': memberIds});
  }

  void _onEmojiTagChanged(String? emoji) {
    _updateField({'emojiTag': emoji});
  }

  void _addSubtask(TaskModel task) {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    HapticFeedback.lightImpact();
    final newSubtask = Subtask(id: const Uuid().v4(), title: title);
    final updated = [...task.subtasks, newSubtask];
    _updateField({
      'subtasks': updated
          .map((s) => {'id': s.id, 'title': s.title, 'completed': s.completed})
          .toList(),
    });
    _subtaskController.clear();
  }

  void _toggleSubtask(TaskModel task, int index) {
    HapticFeedback.selectionClick();
    final updated = List<Subtask>.from(task.subtasks);
    updated[index] =
        updated[index].copyWith(completed: !updated[index].completed);
    _updateField({
      'subtasks': updated
          .map((s) => {'id': s.id, 'title': s.title, 'completed': s.completed})
          .toList(),
    });
    if (updated.every((s) => s.completed) &&
        updated.isNotEmpty &&
        task.status != 'done') {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('All subtasks done!'),
          content: const Text('Mark the task as done too?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Not yet'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                _onStatusChanged('done', task);
              },
              child: const Text('Mark Done'),
            ),
          ],
        ),
      );
    }
  }

  void _deleteSubtask(TaskModel task, int index) {
    final updated = List<Subtask>.from(task.subtasks)..removeAt(index);
    _updateField({
      'subtasks': updated
          .map((s) => {'id': s.id, 'title': s.title, 'completed': s.completed})
          .toList(),
    });
  }

  Future<void> _addImageFromGallery(TaskModel task) async {
    final svc = ref.read(storageServiceProvider);
    final file = await svc.pickImageFromGallery();
    if (file == null) return;
    await _uploadAndAttach(task, () => svc.uploadImage(
          spaceId: widget.spaceId, taskId: widget.taskId, file: file));
  }

  Future<void> _addImageFromCamera(TaskModel task) async {
    final svc = ref.read(storageServiceProvider);
    final file = await svc.pickImageFromCamera();
    if (file == null) return;
    await _uploadAndAttach(task, () => svc.uploadImage(
          spaceId: widget.spaceId, taskId: widget.taskId, file: file));
  }

  Future<void> _addFile(TaskModel task) async {
    final svc = ref.read(storageServiceProvider);
    final file = await svc.pickFile();
    if (file == null) return;
    if (file.size > StorageService.maxFileSize) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File too large (max 10 MB)')));
      }
      return;
    }
    await _uploadAndAttach(task, () => svc.uploadFile(
          spaceId: widget.spaceId, taskId: widget.taskId, file: file));
  }

  Future<void> _uploadAndAttach(
      TaskModel task, Future<Attachment> Function() uploadFn) async {
    if (task.attachments.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Max 10 attachments per task')));
      return;
    }
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Uploading...'),
        ]),
        duration: Duration(seconds: 30),
      ));
      final attachment = await uploadFn();
      final updated = [...task.attachments, attachment];
      _updateField({
        'attachments': updated
            .map((a) => {'url': a.url, 'type': a.type, 'name': a.name})
            .toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Uploaded!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  void _deleteAttachment(TaskModel task, int index) {
    final attachment = task.attachments[index];
    ref.read(storageServiceProvider).deleteFile(attachment.url);
    final updated = List<Attachment>.from(task.attachments)..removeAt(index);
    _updateField({
      'attachments': updated
          .map((a) => {'url': a.url, 'type': a.type, 'name': a.name})
          .toList(),
    });
  }

  void _markDone(TaskModel task) => _onStatusChanged('done', task);

  void _reopenTask(TaskModel task) => _onStatusChanged('todo', task);

  
  Future<void> _confirmDelete() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(taskActionProvider.notifier)
          .deleteTask(spaceId: widget.spaceId, taskId: widget.taskId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(
        taskDetailProvider((spaceId: widget.spaceId, taskId: widget.taskId)));
    final membersAsync = ref.watch(spaceMembersProvider(widget.spaceId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ext.gradientTop, ext.gradientBottom],
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ext.gradientTop,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          title: AnimatedOpacity(
            opacity: _showTitleInAppBar ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              _titleController.text,
              style: AppTextStyles.bodyLarge
                  .copyWith(fontWeight: FontWeight.w600, color: colors.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(CupertinoIcons.ellipsis),
            onSelected: (value) {
              if (value == 'delete') _confirmDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.delete, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete task',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: taskAsync.when(
        loading: _buildShimmerLoading,
        error: (e, _) => Center(
            child: Text('Could not load task', style: AppTextStyles.bodyLarge.copyWith(color: colors.onSurface))),
        data: (task) {
          if (task == null) {
            return Center(
                child:
                    Text('Task not found', style: AppTextStyles.bodyLarge.copyWith(color: colors.onSurface)));
          }
          if (!_titleInitialized) {
            _titleController.text = task.title;
            _titleInitialized = true;
          }
          if (!_descriptionInitialized) {
            _descriptionController.text = task.description ?? '';
            _descriptionInitialized = true;
          }
          final memberMap = membersAsync.valueOrNull ?? {};

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ext.gradientTop, ext.gradientBottom],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title (no card, prominent) ──
                        _TitleField(
                            controller: _titleController,
                            onChanged: _onTitleChanged),
                        const SizedBox(height: 16),

                        // ── Card 1: Metadata ──
                        StaggeredListItem(
                          index: 0,
                          child: _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StatusSegmentedControl(
                                  status: task.status,
                                  onChanged: (s) => _onStatusChanged(s, task),
                                ),
                                const SizedBox(height: 12),
                                // Blocked toggle
                                _BlockedToggle(
                                  isBlocked: task.isBlocked,
                                  blockedReason: task.blockedReason,
                                  onToggle: (blocked) {
                                    ref.read(taskActionProvider.notifier)
                                        .updateTask(
                                      spaceId: widget.spaceId,
                                      taskId: widget.taskId,
                                      fields: {'isBlocked': blocked},
                                    );
                                  },
                                  onReasonChanged: (reason) {
                                    ref.read(taskActionProvider.notifier)
                                        .updateTask(
                                      spaceId: widget.spaceId,
                                      taskId: widget.taskId,
                                      fields: {'blockedReason': reason},
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _AssigneePicker(
                                  assignees: task.assignees,
                                  memberIds: memberMap.keys.toList(),
                                  currentUser: currentUser,
                                  onChanged: _onAssigneesChanged,
                                ),
                                const SizedBox(height: 16),
                                _DueDateRow(
                                  dueDate: task.dueDate,
                                  onPick: () => _pickDueDate(task),
                                  onClear: _clearDueDate,
                                ),
                                const SizedBox(height: 16),
                                _RecurrencePicker(
                                  rule: task.recurrenceRule,
                                  onChanged: (rule) {
                                    ref.read(taskActionProvider.notifier)
                                        .updateTask(
                                      spaceId: widget.spaceId,
                                      taskId: widget.taskId,
                                      fields: {'recurrenceRule': rule},
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Card 2: Tags ──
                        StaggeredListItem(
                          index: 1,
                          child: _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Tag', ctx: context),
                                const SizedBox(height: 10),
                                EmojiTagPicker(
                                    selected: task.emojiTag,
                                    onSelected: _onEmojiTagChanged),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Card 3: Description ──
                        StaggeredListItem(
                          index: 2,
                          child: _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Description', ctx: context),
                                const SizedBox(height: 10),
                                _DescriptionField(
                                  controller: _descriptionController,
                                  onChanged: _onDescriptionChanged,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Card 4: Subtasks ──
                        StaggeredListItem(
                          index: 3,
                          child: _SectionCard(
                            child: _SubtasksSection(
                              subtasks: task.subtasks,
                              controller: _subtaskController,
                              onAdd: () => _addSubtask(task),
                              onToggle: (i) => _toggleSubtask(task, i),
                              onDelete: (i) => _deleteSubtask(task, i),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Card 5: Attachments ──
                        StaggeredListItem(
                          index: 4,
                          child: _SectionCard(
                            child: _AttachmentsSection(
                              attachments: task.attachments,
                              onAddFromGallery: () =>
                                  _addImageFromGallery(task),
                              onAddFromCamera: () =>
                                  _addImageFromCamera(task),
                              onAddFile: () => _addFile(task),
                              onDelete: (i) => _deleteAttachment(task, i),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Card 6: Comments ──
                        StaggeredListItem(
                          index: 5,
                          child: _SectionCard(
                            child: CommentsSection(
                              spaceId: widget.spaceId,
                              taskId: widget.taskId,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Bottom action button ──
                if (task.status == 'done')
                  _ReopenButton(onPressed: () => _reopenTask(task))
                else
                  _MarkDoneButton(onPressed: () => _markDone(task)),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBar(width: 200, height: 28),
          const SizedBox(height: 20),
          _shimmerBar(width: double.infinity, height: 44),
          const SizedBox(height: 16),
          _shimmerBar(width: 160, height: 16),
          const SizedBox(height: 12),
          _shimmerBar(width: 120, height: 16),
          const SizedBox(height: 20),
          _shimmerBar(width: double.infinity, height: 80),
        ],
      ),
    );
  }

  Widget _shimmerBar({required double height, double? width}) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  static Widget _sectionLabel(String text, {BuildContext? ctx}) {
    final color = ctx != null
        ? Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6)
        : Colors.grey;
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Section Card wrapper ────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ext.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Sub-widgets ─────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.headingMedium.copyWith(color: colors.onSurface),
        decoration: const InputDecoration(
          hintText: 'Task title',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          fillColor: Colors.transparent,
          filled: true,
        ),
        maxLines: null,
        textInputAction: TextInputAction.done,
      ),
    );
  }
}

class _StatusSegmentedControl extends StatelessWidget {
  const _StatusSegmentedControl(
      {required this.status, required this.onChanged});
  final String status;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TaskDetailScreenState._sectionLabel('Status', ctx: context),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<String>(
            groupValue: status,
            thumbColor: _thumbColor(status, colors),
            backgroundColor: colors.primaryContainer.withValues(alpha: 0.5),
            children: {
              'todo': _segmentLabel('To Do', AppColors.statusTodo, status == 'todo', colors),
              'in_progress': _segmentLabel(
                  'Working on it', AppColors.statusInProgress, status == 'in_progress', colors),
              'done': _segmentLabel('Done', AppColors.statusDone, status == 'done', colors),
            },
            onValueChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      ],
    );
  }

  Color _thumbColor(String s, ColorScheme colors) => switch (s) {
        'in_progress' => AppColors.accentWarm.withValues(alpha: 0.15),
        'done' => AppColors.statusDone.withValues(alpha: 0.15),
        _ => colors.surface,
      };

  Widget _segmentLabel(String text, Color color, bool isActive, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? color : colors.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssigneePicker extends ConsumerWidget {
  const _AssigneePicker({
    required this.assignees,
    required this.memberIds,
    required this.currentUser,
    required this.onChanged,
  });
  final List<String> assignees;
  final List<String> memberIds;
  final UserModel? currentUser;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TaskDetailScreenState._sectionLabel('Assigned to', ctx: context),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _chip(
            label: 'Me',
            avatar: AvatarWidget(
                name: (currentUser != null && currentUser!.displayName.isNotEmpty)
                    ? currentUser!.displayName
                    : 'Me',
                imageUrl: currentUser?.photoUrl,
                radius: 12),
            selected: assignees.contains(uid),
            onTap: () {
              final u = List<String>.from(assignees);
              u.contains(uid) ? u.remove(uid) : u.add(uid);
              onChanged(u);
            },
            colors: colors,
            ctx: context,
          ),
          ...memberIds.where((id) => id != uid).map((mid) {
                final partnerAsync = ref.watch(userByIdProvider(mid));
                return partnerAsync.when(
                  loading: () => _chip(
                    label: 'Loading...',
                    avatar: const SizedBox(
                      width: 24,
                      height: 24,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    selected: assignees.contains(mid),
                    onTap: () {},
                    colors: colors,
                    ctx: context,
                  ),
                  error: (_, __) => _chip(
                    label: 'Team member',
                    avatar: const AvatarWidget(name: 'Team member', radius: 12),
                    selected: assignees.contains(mid),
                    onTap: () {
                      final u = List<String>.from(assignees);
                      u.contains(mid) ? u.remove(mid) : u.add(mid);
                      onChanged(u);
                    },
                    colors: colors,
                    ctx: context,
                  ),
                  data: (partnerUser) {
                    final partnerName =
                        (partnerUser != null && partnerUser.displayName.isNotEmpty)
                            ? partnerUser.displayName
                            : (partnerUser != null && partnerUser.email.isNotEmpty)
                                ? partnerUser.email.split('@').first
                                : 'Team member';
                    return _chip(
                      label: partnerName,
                      avatar: AvatarWidget(
                          name: partnerName,
                          imageUrl: partnerUser?.photoUrl,
                          radius: 12),
                      selected: assignees.contains(mid),
                      onTap: () {
                        final u = List<String>.from(assignees);
                        u.contains(mid) ? u.remove(mid) : u.add(mid);
                        onChanged(u);
                      },
                      colors: colors,
                      ctx: context,
                    );
                  },
                );
              }),
          if (memberIds.length > 1)
            _chip(
              label: 'Both',
              avatar: Icon(Icons.group, size: 18, color: colors.primary),
              selected: assignees.length == memberIds.length &&
                  memberIds.every(assignees.contains),
              onTap: () {
                final all = assignees.length == memberIds.length &&
                    memberIds.every(assignees.contains);
                onChanged(all ? [] : List<String>.from(memberIds));
              },
              colors: colors,
              ctx: context,
            ),
        ]),
      ],
    );
  }

  Widget _chip({
    required String label,
    required Widget avatar,
    required bool selected,
    required VoidCallback onTap,
    required ColorScheme colors,
    required BuildContext ctx,
  }) {
    final ext = Theme.of(ctx).extension<AppColorsExtension>()!;
    return Semantics(
      label: '$label assignee',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.12)
                : colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : ext.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            avatar,
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: colors.onSurface)),
          ]),
        ),
      ),
    );
  }
}

class _DueDateRow extends StatelessWidget {
  const _DueDateRow(
      {required this.dueDate, required this.onPick, required this.onClear});
  final DateTime? dueDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  bool get _overdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day));

  String _fmt(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final t = DateTime(d.year, d.month, d.day);
    final diff = t.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff <= 7) return 'In $diff days';
    if (diff < -1) return '${-diff} days ago';
    return DateFormat('MMM d, yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TaskDetailScreenState._sectionLabel('Due date', ctx: context),
        const SizedBox(height: 10),
        Semantics(
          label: dueDate != null
              ? 'Due date: ${_fmt(dueDate!)}'
              : 'Set due date',
          button: true,
          child: GestureDetector(
            onTap: onPick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: ext.divider),
              ),
              child: Row(children: [
                Icon(CupertinoIcons.calendar,
                    size: 18,
                    color: _overdue
                        ? AppColors.error
                        : colors.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dueDate != null ? _fmt(dueDate!) : 'Set due date',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: dueDate != null
                          ? (_overdue ? AppColors.error : colors.onSurface)
                          : colors.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                if (dueDate != null)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      icon: Icon(CupertinoIcons.xmark_circle_fill,
                          size: 18,
                          color:
                              colors.onSurface.withValues(alpha: 0.3)),
                      onPressed: onClear,
                      tooltip: 'Clear due date',
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField(
      {required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        hintText: 'Add notes or details...',
        hintStyle: AppTextStyles.bodyMedium
            .copyWith(color: colors.onSurface.withValues(alpha: 0.35)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.primary, width: 1.5)),
        filled: true,
        fillColor: colors.primaryContainer.withValues(alpha: 0.2),
        contentPadding: const EdgeInsets.all(12),
      ),
      maxLines: 5,
      minLines: 3,
      textInputAction: TextInputAction.newline,
    );
  }
}

class _SubtasksSection extends StatelessWidget {
  const _SubtasksSection({
    required this.subtasks,
    required this.controller,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });
  final List<Subtask> subtasks;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final done = subtasks.where((s) => s.completed).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _TaskDetailScreenState._sectionLabel('Subtasks', ctx: context),
          if (subtasks.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text('$done/${subtasks.length}',
                style: AppTextStyles.caption.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.5))),
          ],
        ]),
        // ── Progress bar ──
        if (subtasks.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: subtasks.isEmpty ? 0 : done / subtasks.length,
              minHeight: 3,
              backgroundColor: ext.divider.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation(
                done == subtasks.length
                    ? AppColors.statusDone
                    : colors.primary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        // ── Warm empty state ──
        if (subtasks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Break it into smaller steps',
              style: AppTextStyles.caption.copyWith(
                color: colors.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ),
        // ── Subtask list with swipe-to-delete ──
        ...List.generate(subtasks.length, (i) {
          final s = subtasks[i];
          return Dismissible(
            key: ValueKey(s.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(CupertinoIcons.delete, color: AppColors.error, size: 18),
            ),
            onDismissed: (_) => onDelete(i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Semantics(
                label: 'Subtask: ${s.title}',
                value: s.completed ? 'Completed' : 'Not completed',
                toggled: s.completed,
                child: GestureDetector(
                  onTap: () => onToggle(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: s.completed
                              ? colors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: s.completed
                                  ? colors.primary
                                  : ext.divider,
                              width: 2),
                        ),
                        child: s.completed
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              decoration: s.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: s.completed
                                  ? colors.onSurface
                                      .withValues(alpha: 0.4)
                                  : colors.onSurface,
                            )),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        Row(children: [
          GestureDetector(
            onTap: onAdd,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(Icons.add,
                    size: 18,
                    color: colors.onSurface.withValues(alpha: 0.4)),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
              decoration: InputDecoration(
                hintText: 'Add subtask',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.4)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                fillColor: Colors.transparent,
                filled: true,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onAdd(),
            ),
          ),
        ]),
      ],
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({
    required this.attachments,
    required this.onAddFromGallery,
    required this.onAddFromCamera,
    required this.onAddFile,
    required this.onDelete,
  });
  final List<Attachment> attachments;
  final VoidCallback onAddFromGallery;
  final VoidCallback onAddFromCamera;
  final VoidCallback onAddFile;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _TaskDetailScreenState._sectionLabel('Attachments', ctx: context),
          const Spacer(),
          PopupMenuButton<String>(
            icon: Icon(CupertinoIcons.plus_circle,
                size: 20,
                color: colors.onSurface.withValues(alpha: 0.6)),
            onSelected: (v) {
              switch (v) {
                case 'gallery':
                  onAddFromGallery();
                case 'camera':
                  onAddFromCamera();
                case 'file':
                  onAddFile();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'gallery',
                  child: Row(children: [
                    Icon(CupertinoIcons.photo, size: 18),
                    SizedBox(width: 8),
                    Text('From Gallery')
                  ])),
              PopupMenuItem(
                  value: 'camera',
                  child: Row(children: [
                    Icon(CupertinoIcons.camera, size: 18),
                    SizedBox(width: 8),
                    Text('Take Photo')
                  ])),
              PopupMenuItem(
                  value: 'file',
                  child: Row(children: [
                    Icon(CupertinoIcons.paperclip, size: 18),
                    SizedBox(width: 8),
                    Text('Attach File')
                  ])),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        if (attachments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('No attachments yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.35))),
            ),
          )
        else
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(attachments.length, (i) {
                final a = attachments[i];
                final isImg = a.type == 'image';
                return Stack(children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: colors.primaryContainer,
                      border: Border.all(
                          color: ext.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isImg
                        ? Image.network(a.url,
                            fit: BoxFit.cover,
                            cacheWidth: 160,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.broken_image,
                                color: colors.primary))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(Icons.insert_drive_file,
                                    color: colors.primary, size: 28),
                                const SizedBox(height: 2),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(a.name,
                                      style: AppTextStyles.caption
                                          .copyWith(fontSize: 9, color: colors.onSurface),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center),
                                ),
                              ]),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Semantics(
                      label: 'Delete attachment ${a.name}',
                      button: true,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: GestureDetector(
                            onTap: () => onDelete(i),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]);
              })),
      ],
    );
  }
}

class _MarkDoneButton extends StatelessWidget {
  const _MarkDoneButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final gradientBase = ext.gradientBottom;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gradientBase.withValues(alpha: 0.0),
            gradientBase.withValues(alpha: 0.9),
            gradientBase,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Text('\u{1F389}', style: TextStyle(fontSize: 18)),
        label:
            Text('Mark Done', style: AppTextStyles.button.copyWith(fontSize: 16)),
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _ReopenButton extends StatelessWidget {
  const _ReopenButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final gradientBase = ext.gradientBottom;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gradientBase.withValues(alpha: 0.0),
            gradientBase.withValues(alpha: 0.9),
            gradientBase,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(CupertinoIcons.refresh, size: 18, color: colors.primary),
        label: Text('Reopen Task',
            style: AppTextStyles.button
                .copyWith(fontSize: 16, color: colors.primary)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: colors.primary, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

/// Toggle for marking a task as blocked with an optional reason.
class _BlockedToggle extends StatefulWidget {
  const _BlockedToggle({
    required this.isBlocked,
    this.blockedReason,
    required this.onToggle,
    required this.onReasonChanged,
  });

  final bool isBlocked;
  final String? blockedReason;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onReasonChanged;

  @override
  State<_BlockedToggle> createState() => _BlockedToggleState();
}

class _BlockedToggleState extends State<_BlockedToggle> {
  late final TextEditingController _reasonController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.blockedReason ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.block,
              size: 16,
              color: widget.isBlocked
                  ? AppColors.error
                  : colors.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              'Blocked',
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.isBlocked ? AppColors.error : colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            CupertinoSwitch(
              value: widget.isBlocked,
              activeTrackColor: AppColors.error,
              onChanged: widget.onToggle,
            ),
          ],
        ),
        if (widget.isBlocked) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
            decoration: InputDecoration(
              hintText: 'Blocked by...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                widget.onReasonChanged(value);
              });
            },
          ),
        ],
      ],
    );
  }
}

// ── Recurrence Picker ───────────────────────────────────────────────

class _RecurrencePicker extends StatelessWidget {
  const _RecurrencePicker({required this.rule, required this.onChanged});
  final String rule;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('never', 'Never', Icons.block_outlined),
    ('daily', 'Daily', Icons.today),
    ('weekly', 'Weekly', Icons.view_week),
    ('biweekly', 'Every 2 weeks', Icons.date_range),
    ('monthly', 'Monthly', Icons.calendar_month),
  ];

  String _displayLabel(String rule) {
    switch (rule) {
      case 'daily':
        return 'Repeats daily';
      case 'weekly':
        return 'Repeats weekly';
      case 'biweekly':
        return 'Every 2 weeks';
      case 'monthly':
        return 'Repeats monthly';
      default:
        return 'No repeat';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isRecurring = rule != 'never';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TaskDetailScreenState._sectionLabel('Repeat', ctx: context),
        const SizedBox(height: 8),
        Semantics(
          label: _displayLabel(rule),
          child: GestureDetector(
            onTap: () => _showPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isRecurring
                    ? colors.primary.withValues(alpha: 0.08)
                    : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isRecurring
                      ? colors.primary.withValues(alpha: 0.3)
                      : colors.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isRecurring ? Icons.repeat : Icons.repeat,
                    size: 18,
                    color: isRecurring
                        ? colors.primary
                        : colors.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _displayLabel(rule),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isRecurring
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colors.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Repeat', style: AppTextStyles.headingSmall),
              ),
              ..._options.map((option) {
                final isSelected = rule == option.$1;
                return ListTile(
                  leading: Icon(
                    option.$3,
                    color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    option.$2,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? colors.primary : colors.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: colors.primary)
                      : null,
                  onTap: () {
                    onChanged(option.$1);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
