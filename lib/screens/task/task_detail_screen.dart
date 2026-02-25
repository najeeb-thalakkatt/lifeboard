import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/models/user_model.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/providers/task_provider.dart';
import 'package:lifeboard/services/storage_service.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/avatar_widget.dart';
import 'package:lifeboard/widgets/celebration_overlay.dart';
import 'package:lifeboard/widgets/comments_section.dart';
import 'package:lifeboard/widgets/emoji_tag_picker.dart';

/// Streams a single task by spaceId + taskId.
final taskDetailProvider = StreamProvider.family<TaskModel?,
    ({String spaceId, String taskId})>((ref, params) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('spaces')
      .doc(params.spaceId)
      .collection('tasks')
      .doc(params.taskId)
      .snapshots()
      .map((doc) => doc.exists ? TaskModel.fromFirestore(doc) : null);
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

  Timer? _titleDebounce;
  Timer? _descriptionDebounce;
  bool _titleInitialized = false;
  bool _descriptionInitialized = false;

  @override
  void dispose() {
    _titleDebounce?.cancel();
    _descriptionDebounce?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
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
    final picked = await showDatePicker(
      context: context,
      initialDate: task.dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryDark,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _updateField({'dueDate': Timestamp.fromDate(picked)});
    }
  }

  void _clearDueDate() => _updateField({'dueDate': null});

  void _onAssigneesChanged(List<String> memberIds) {
    _updateField({'assignees': memberIds});
  }

  void _onEmojiTagChanged(String? emoji) {
    _updateField({'emojiTag': emoji});
  }

  void _addSubtask(TaskModel task) {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
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
    final updated = List<Subtask>.from(task.subtasks);
    updated[index] = updated[index].copyWith(completed: !updated[index].completed);
    _updateField({
      'subtasks': updated
          .map((s) => {'id': s.id, 'title': s.title, 'completed': s.completed})
          .toList(),
    });
    if (updated.every((s) => s.completed) && updated.isNotEmpty && task.status != 'done') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All subtasks done! Mark task as done?'),
          action: SnackBarAction(
            label: 'Mark Done',
            textColor: AppColors.accentWarm,
            onPressed: () => _onStatusChanged('done', task),
          ),
          duration: const Duration(seconds: 4),
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
          SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Uploading...'),
        ]),
        duration: Duration(seconds: 30),
      ));
      final attachment = await uploadFn();
      final updated = [...task.attachments, attachment];
      _updateField({
        'attachments':
            updated.map((a) => {'url': a.url, 'type': a.type, 'name': a.name}).toList(),
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
      'attachments':
          updated.map((a) => {'url': a.url, 'type': a.type, 'name': a.name}).toList(),
    });
  }

  void _markDone(TaskModel task) => _onStatusChanged('done', task);

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(taskActionProvider.notifier)
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete task',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Could not load task', style: AppTextStyles.bodyLarge)),
        data: (task) {
          if (task == null) {
            return Center(
                child: Text('Task not found', style: AppTextStyles.bodyLarge));
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

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleField(controller: _titleController, onChanged: _onTitleChanged),
                      const SizedBox(height: 16),
                      _StatusDropdown(
                          status: task.status,
                          onChanged: (s) => _onStatusChanged(s, task)),
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
                          onClear: _clearDueDate),
                      const SizedBox(height: 16),
                      _label('Tag'),
                      const SizedBox(height: 8),
                      EmojiTagPicker(selected: task.emojiTag, onSelected: _onEmojiTagChanged),
                      const SizedBox(height: 20),
                      _label('Description'),
                      const SizedBox(height: 8),
                      _DescriptionField(
                          controller: _descriptionController,
                          onChanged: _onDescriptionChanged),
                      const SizedBox(height: 20),
                      _SubtasksSection(
                        subtasks: task.subtasks,
                        controller: _subtaskController,
                        onAdd: () => _addSubtask(task),
                        onToggle: (i) => _toggleSubtask(task, i),
                        onDelete: (i) => _deleteSubtask(task, i),
                      ),
                      const SizedBox(height: 20),
                      _AttachmentsSection(
                        attachments: task.attachments,
                        onAddFromGallery: () => _addImageFromGallery(task),
                        onAddFromCamera: () => _addImageFromCamera(task),
                        onAddFile: () => _addFile(task),
                        onDelete: (i) => _deleteAttachment(task, i),
                      ),
                      const SizedBox(height: 20),
                      CommentsSection(
                        spaceId: widget.spaceId,
                        taskId: widget.taskId,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (task.status != 'done') _MarkDoneButton(onPressed: () => _markDone(task)),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark.withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      );
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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.headingMedium,
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
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.status, required this.onChanged});
  final String status;
  final ValueChanged<String> onChanged;

  Color _color(String s) => switch (s) {
        'in_progress' => AppColors.accentWarm,
        'done' => const Color(0xFF4CAF50),
        _ => AppColors.primaryDark,
      };

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('Status',
          style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark.withValues(alpha: 0.6))),
      const SizedBox(width: 12),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _color(status).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _color(status).withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: status,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: _color(status)),
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600, color: _color(status)),
              items: AppConstants.taskStatuses
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text(StatusDisplayName.fromStatus(s))))
                  .toList(),
              onChanged: (v) { if (v != null) onChanged(v); },
            ),
          ),
        ),
      ),
    ]);
  }
}

class _AssigneePicker extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assigned to',
            style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark.withValues(alpha: 0.6))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _chip(
            label: 'Me',
            avatar: AvatarWidget(
                name: currentUser?.displayName ?? 'Me',
                imageUrl: currentUser?.photoUrl,
                radius: 12),
            selected: assignees.contains(uid),
            onTap: () {
              final u = List<String>.from(assignees);
              u.contains(uid) ? u.remove(uid) : u.add(uid);
              onChanged(u);
            },
          ),
          ...memberIds.where((id) => id != uid).map((mid) => _chip(
                label: 'Partner',
                avatar: AvatarWidget(name: mid, radius: 12),
                selected: assignees.contains(mid),
                onTap: () {
                  final u = List<String>.from(assignees);
                  u.contains(mid) ? u.remove(mid) : u.add(mid);
                  onChanged(u);
                },
              )),
          if (memberIds.length > 1)
            _chip(
              label: 'Both',
              avatar: const Icon(Icons.group, size: 18, color: AppColors.primaryDark),
              selected: assignees.length == memberIds.length &&
                  memberIds.every(assignees.contains),
              onTap: () {
                final all = assignees.length == memberIds.length &&
                    memberIds.every(assignees.contains);
                onChanged(all ? [] : List<String>.from(memberIds));
              },
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryDark.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          avatar,
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: AppColors.primaryDark)),
        ]),
      ),
    );
  }
}

class _DueDateRow extends StatelessWidget {
  const _DueDateRow({required this.dueDate, required this.onPick, required this.onClear});
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
    return Row(children: [
      Text('Due date',
          style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark.withValues(alpha: 0.6))),
      const SizedBox(width: 12),
      Expanded(
        child: GestureDetector(
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(children: [
              Icon(Icons.calendar_today,
                  size: 16,
                  color: _overdue
                      ? AppColors.error
                      : AppColors.primaryDark.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dueDate != null ? _fmt(dueDate!) : 'Set due date',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: dueDate != null
                        ? (_overdue ? AppColors.error : AppColors.primaryDark)
                        : AppColors.primaryDark.withValues(alpha: 0.4),
                  ),
                ),
              ),
              if (dueDate != null)
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close,
                      size: 16, color: AppColors.primaryDark.withValues(alpha: 0.4)),
                ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Add description...',
        hintStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.primaryDark.withValues(alpha: 0.4)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
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
    final done = subtasks.where((s) => s.completed).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Subtasks',
              style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark.withValues(alpha: 0.6),
                  letterSpacing: 0.5)),
          if (subtasks.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text('$done/${subtasks.length}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.primaryDark.withValues(alpha: 0.5))),
          ],
        ]),
        const SizedBox(height: 8),
        ...List.generate(subtasks.length, (i) {
          final s = subtasks[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              GestureDetector(
                onTap: () => onToggle(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: s.completed ? AppColors.primaryDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: s.completed ? AppColors.primaryDark : AppColors.divider,
                        width: 2),
                  ),
                  child: s.completed
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      decoration: s.completed ? TextDecoration.lineThrough : null,
                      color: s.completed
                          ? AppColors.primaryDark.withValues(alpha: 0.4)
                          : AppColors.primaryDark,
                    )),
              ),
              GestureDetector(
                onTap: () => onDelete(i),
                child: Icon(Icons.close,
                    size: 16, color: AppColors.primaryDark.withValues(alpha: 0.3)),
              ),
            ]),
          );
        }),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.add, size: 18, color: AppColors.primaryDark.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Add subtask',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.primaryDark.withValues(alpha: 0.4)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Attachments',
              style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark.withValues(alpha: 0.6),
                  letterSpacing: 0.5)),
          const Spacer(),
          PopupMenuButton<String>(
            icon: Icon(Icons.add_circle_outline,
                size: 20, color: AppColors.primaryDark.withValues(alpha: 0.6)),
            onSelected: (v) {
              switch (v) {
                case 'gallery': onAddFromGallery();
                case 'camera': onAddFromCamera();
                case 'file': onAddFile();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'gallery',
                  child: Row(children: [Icon(Icons.photo_library, size: 18), SizedBox(width: 8), Text('From Gallery')])),
              PopupMenuItem(value: 'camera',
                  child: Row(children: [Icon(Icons.camera_alt, size: 18), SizedBox(width: 8), Text('Take Photo')])),
              PopupMenuItem(value: 'file',
                  child: Row(children: [Icon(Icons.attach_file, size: 18), SizedBox(width: 8), Text('Attach File')])),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        if (attachments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(
              child: Text('No attachments yet',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.primaryDark.withValues(alpha: 0.4))),
            ),
          )
        else
          Wrap(spacing: 8, runSpacing: 8, children: List.generate(attachments.length, (i) {
            final a = attachments[i];
            final isImg = a.type == 'image';
            return Stack(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primaryLight,
                  border: Border.all(color: AppColors.divider),
                ),
                clipBehavior: Clip.antiAlias,
                child: isImg
                    ? Image.network(a.url, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, color: AppColors.primaryDark))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.insert_drive_file, color: AppColors.primaryDark, size: 28),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(a.name,
                              style: AppTextStyles.caption.copyWith(fontSize: 9),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center),
                        ),
                      ]),
              ),
              Positioned(top: 2, right: 2,
                child: GestureDetector(
                  onTap: () => onDelete(i),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Text('\u{1F389}', style: TextStyle(fontSize: 18)),
        label: Text('Mark Done', style: AppTextStyles.button.copyWith(fontSize: 16)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
