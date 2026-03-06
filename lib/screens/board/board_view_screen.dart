import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/core/errors/app_exceptions.dart';
import 'package:lifeboard/models/board_model.dart';
import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/providers/board_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/providers/task_provider.dart';
import 'package:lifeboard/screens/board/compact_kanban_column.dart';
import 'package:lifeboard/screens/board/kanban_column.dart';
import 'package:lifeboard/screens/home/home_dashboard_screen.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/shared_app_bar.dart';

/// The statuses (columns) shown on the kanban board.
const _kanbanStatuses = ['todo', 'in_progress', 'done'];

/// Board view modes for mobile.
enum _BoardViewMode { tabs, columns }

/// Checks if the WIP limit for [targetStatus] would be exceeded and shows a
/// confirmation toast. Returns true if the move should proceed.
Future<bool> _checkWipLimit(
  BuildContext context,
  Map<String, int> wipLimits,
  String targetStatus,
  List<TaskModel> targetTasks,
  TaskModel task,
) async {
  final limit = wipLimits[targetStatus];
  if (limit == null) return true;

  // Count tasks already in target (excluding the task being moved if it's already there)
  final currentCount = targetTasks.where((t) => t.id != task.id).length;
  if (currentCount < limit) return true;

  // At or over limit — show warning
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Column is full'),
      content: Text(
        '${StatusDisplayName.fromStatus(targetStatus)} has $currentCount/$limit tasks. Still want to add more?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Add anyway'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Main kanban board screen displaying tasks in 3 columns.
class BoardViewScreen extends ConsumerStatefulWidget {
  const BoardViewScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<BoardViewScreen> createState() => _BoardViewScreenState();
}

class _BoardViewScreenState extends ConsumerState<BoardViewScreen> {
  String? _selectedBoardId;

  @override
  Widget build(BuildContext context) {
    final boardsAsync = ref.watch(boardsProvider(widget.spaceId));
    final defaultBoard = ref.watch(defaultBoardProvider(widget.spaceId));
    final spacesAsync = ref.watch(userSpacesProvider);
    final allSpaces = spacesAsync.valueOrNull ?? [];

    // Determine which board to show
    return boardsAsync.when(
      loading: () => defaultBoard.when(
        loading: () => Scaffold(
          appBar: const SharedAppBar(title: 'Board'),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _buildError(),
        data: (board) => _BoardContent(
          spaceId: widget.spaceId,
          boardId: board.id,
          boardName: board.name,
          allSpaces: allSpaces,
        ),
      ),
      error: (error, _) => _buildError(),
      data: (boards) {
        if (boards.isEmpty) {
          // Trigger default board creation
          return defaultBoard.when(
            loading: () => Scaffold(
              appBar: const SharedAppBar(title: 'Board'),
              body: const Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => _buildError(),
            data: (board) => _BoardContent(
              spaceId: widget.spaceId,
              boardId: board.id,
              boardName: board.name,
              allBoards: [board],
              onBoardSelected: (id) => setState(() => _selectedBoardId = id),
              onCreateBoard: () => _createBoard(context),
              allSpaces: allSpaces,
            ),
          );
        }

        // Use selected board or first board
        final activeBoard = _selectedBoardId != null
            ? boards.firstWhere(
                (b) => b.id == _selectedBoardId,
                orElse: () => boards.first,
              )
            : boards.first;

        return _BoardContent(
          spaceId: widget.spaceId,
          boardId: activeBoard.id,
          boardName: activeBoard.name,
          allBoards: boards,
          onBoardSelected: (id) => setState(() => _selectedBoardId = id),
          onCreateBoard: () => _createBoard(context),
          allSpaces: allSpaces,
        );
      },
    );
  }

  Widget _buildError() {
    return Scaffold(
      appBar: const SharedAppBar(title: 'Board'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load board', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                ref.invalidate(boardsProvider(widget.spaceId));
                ref.invalidate(defaultBoardProvider(widget.spaceId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBoard(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('New Board'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Board name'),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final board = await ref.read(firestoreServiceProvider).createBoard(
        spaceId: widget.spaceId,
        name: name,
        userId: userId,
      );
      setState(() => _selectedBoardId = board.id);
    }
  }
}

class _BoardContent extends ConsumerStatefulWidget {
  const _BoardContent({
    required this.spaceId,
    required this.boardId,
    required this.boardName,
    this.allBoards,
    this.onBoardSelected,
    this.onCreateBoard,
    this.allSpaces,
  });

  final String spaceId;
  final String boardId;
  final String boardName;
  final List<BoardModel>? allBoards;
  final ValueChanged<String>? onBoardSelected;
  final VoidCallback? onCreateBoard;
  final List<SpaceModel>? allSpaces;

  @override
  ConsumerState<_BoardContent> createState() => _BoardContentState();
}

class _BoardContentState extends ConsumerState<_BoardContent> {
  _BoardViewMode _viewMode = _BoardViewMode.tabs;

  static const _viewModeKey = 'board_view_mode';

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    // Persist last visited space
    saveLastSpaceId(widget.spaceId);
  }

  @override
  void didUpdateWidget(covariant _BoardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId != widget.spaceId) {
      saveLastSpaceId(widget.spaceId);
    }
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_viewModeKey);
    if (saved == 'columns' && mounted) {
      setState(() => _viewMode = _BoardViewMode.columns);
    }
  }

  Future<void> _saveViewMode(_BoardViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModeKey, mode == _BoardViewMode.columns ? 'columns' : 'tabs');
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(
      boardTasksProvider((spaceId: widget.spaceId, boardId: widget.boardId)),
    );
    final memberNames = ref.watch(spaceMemberProfilesProvider(widget.spaceId));
    final boardAsync = ref.watch(boardStreamProvider(
        (spaceId: widget.spaceId, boardId: widget.boardId)));
    final wipLimits = boardAsync.valueOrNull?.wipLimits ?? {};

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideLayout = screenWidth >= 600;

    // Resolve space name for the header
    final allSpaces = widget.allSpaces ?? [];
    final currentSpace = allSpaces.where((s) => s.id == widget.spaceId).firstOrNull;
    final spaceName = currentSpace?.name ?? 'Board';

    return Scaffold(
      appBar: SharedAppBar(
        title: spaceName,
        leading: const SizedBox.shrink(),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _showSpacePicker(context, allSpaces),
            icon: const Icon(Icons.dashboard_outlined, size: 22),
            tooltip: 'Switch space',
          ),
          if (!isWideLayout)
            IconButton(
              onPressed: () {
                final newMode = _viewMode == _BoardViewMode.tabs
                    ? _BoardViewMode.columns
                    : _BoardViewMode.tabs;
                setState(() => _viewMode = newMode);
                _saveViewMode(newMode);
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  _viewMode == _BoardViewMode.tabs
                      ? Icons.view_column_rounded
                      : Icons.tab_rounded,
                  key: ValueKey(_viewMode),
                  size: 22,
                ),
              ),
              tooltip: _viewMode == _BoardViewMode.tabs
                  ? 'All columns'
                  : 'Tab view',
            ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load tasks', style: AppTextStyles.bodyLarge),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(
                  boardTasksProvider(
                      (spaceId: widget.spaceId, boardId: widget.boardId)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allTasks) {
          // Apply active filters
          final filter = ref.watch(boardFilterProvider);
          final filteredTasks = filter.isActive
              ? allTasks.where((t) => filter.matches(t)).toList()
              : allTasks;

          // Hide recurring tasks whose due date is in the future
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final visibleTasks = filteredTasks.where((t) {
            if (t.recurrenceRule == 'never') return true;
            if (t.dueDate == null) return true;
            final taskDate = DateTime(
                t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
            return !taskDate.isAfter(today);
          }).toList();

          // Group tasks by status
          final tasksByStatus = <String, List<TaskModel>>{};
          for (final status in _kanbanStatuses) {
            tasksByStatus[status] = visibleTasks
                .where((t) => t.status == status)
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));
          }

          // Collect unique emoji tags for filter picker
          final allEmojiTags = allTasks
              .map((t) => t.emojiTag)
              .whereType<String>()
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList();

          Widget boardView;
          if (isWideLayout) {
            boardView = _WideKanbanLayout(
              spaceId: widget.spaceId,
              boardId: widget.boardId,
              tasksByStatus: tasksByStatus,
              memberNames: memberNames,
              wipLimits: wipLimits,
            );
          } else if (_viewMode == _BoardViewMode.columns) {
            boardView = _CompactKanbanLayout(
              spaceId: widget.spaceId,
              boardId: widget.boardId,
              tasksByStatus: tasksByStatus,
              memberNames: memberNames,
              wipLimits: wipLimits,
            );
          } else {
            boardView = _MobileKanbanLayout(
              spaceId: widget.spaceId,
              boardId: widget.boardId,
              tasksByStatus: tasksByStatus,
              memberNames: memberNames,
              wipLimits: wipLimits,
            );
          }

          return Column(
            children: [
              _BoardFilterBar(
                memberNames: memberNames,
                emojiTags: allEmojiTags,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: () async {
                    ref.invalidate(boardTasksProvider(
                        (spaceId: widget.spaceId, boardId: widget.boardId)));
                    ref.invalidate(boardStreamProvider(
                        (spaceId: widget.spaceId, boardId: widget.boardId)));
                    await Future<void>.delayed(
                        const Duration(milliseconds: 500));
                  },
                  child: boardView,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSpacePicker(BuildContext context, List<SpaceModel> allSpaces) {
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
                child: Text('Switch Space',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: colors.onSurface)),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final space in allSpaces)
                      ListTile(
                        title: Text(space.name),
                        leading: Icon(Icons.workspaces_outlined,
                            color: space.id == widget.spaceId
                                ? colors.primary
                                : colors.onSurface.withValues(alpha: 0.5)),
                        trailing: space.id == widget.spaceId
                            ? Icon(Icons.check, color: colors.primary)
                            : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          GoRouter.of(context).go('/spaces/${space.id}');
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.add_rounded, color: colors.primary),
                title: Text('Create new space...',
                    style: TextStyle(color: colors.primary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showCreateSpaceDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.group_add_rounded, color: colors.primary),
                title: Text('Join a space...',
                    style: TextStyle(color: colors.primary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showJoinSpaceDialog(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCreateSpaceDialog(BuildContext context) {
    final controller = TextEditingController();
    final colors = Theme.of(context).colorScheme;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Create Space',
            style: AppTextStyles.headingSmall
                .copyWith(color: colors.onSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Our Home, Family, Vacation...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final space = await ref
                    .read(spaceActionProvider.notifier)
                    .createSpace(name: name, userId: userId);
                if (context.mounted) {
                  GoRouter.of(context).go('/spaces/${space.id}');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create space: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinSpaceDialog(BuildContext context) {
    final controller = TextEditingController();
    final colors = Theme.of(context).colorScheme;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Join a Space',
            style: AppTextStyles.headingSmall
                .copyWith(color: colors.onSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: AppTextStyles.headingSmall.copyWith(letterSpacing: 4),
          decoration: const InputDecoration(
            hintText: 'Enter invite code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final space = await ref
                    .read(spaceActionProvider.notifier)
                    .joinSpace(inviteCode: code, userId: userId);
                if (context.mounted) {
                  GoRouter.of(context).go('/spaces/${space.id}');
                }
              } on SpaceNotFoundException {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('No space found with that invite code')),
                  );
                }
              } on AlreadyMemberException {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('You are already a member of this space')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to join space: $e')),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class _WideKanbanLayout extends ConsumerWidget {
  const _WideKanbanLayout({
    required this.spaceId,
    required this.boardId,
    required this.tasksByStatus,
    required this.memberNames,
    required this.wipLimits,
  });

  final String spaceId;
  final String boardId;
  final Map<String, List<TaskModel>> tasksByStatus;
  final Map<String, String> memberNames;
  final Map<String, int> wipLimits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _kanbanStatuses.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: KanbanColumn(
                status: _kanbanStatuses[i],
                tasks: tasksByStatus[_kanbanStatuses[i]] ?? [],
                memberNames: memberNames,
                wipLimit: wipLimits[_kanbanStatuses[i]],
                spaceId: spaceId,
                boardId: boardId,
                onTaskDropped: (task) => _onTaskDropped(
                  context,
                  ref,
                  task,
                  _kanbanStatuses[i],
                  tasksByStatus[_kanbanStatuses[i]] ?? [],
                ),
                onQuickAdd: (title) => _onQuickAdd(
                  ref,
                  title,
                  _kanbanStatuses[i],
                  tasksByStatus[_kanbanStatuses[i]] ?? [],
                ),
                onTaskTap: (task) => context.go('/spaces/$spaceId/task/${task.id}'),
                onTaskCompleted: (task) => _onTaskDropped(
                  context,
                  ref,
                  task,
                  'done',
                  tasksByStatus['done'] ?? [],
                ),
                onArchiveCompleted: _kanbanStatuses[i] == 'done'
                    ? () => _archiveCompleted(context, ref)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _archiveCompleted(BuildContext context, WidgetRef ref) async {
    final count = await ref.read(firestoreServiceProvider).archiveCompletedTasks(
      spaceId: spaceId,
      boardId: boardId,
    );
    if (context.mounted && count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archived $count completed tasks')),
      );
    }
  }

  Future<void> _onTaskDropped(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    String targetStatus,
    List<TaskModel> targetTasks,
  ) async {
    final allowed = await _checkWipLimit(
        context, wipLimits, targetStatus, targetTasks, task);
    if (!allowed) return;

    final newOrder = targetTasks.isEmpty
        ? 0
        : targetTasks.last.order + 1;
    ref.read(taskActionProvider.notifier).moveTask(
          spaceId: spaceId,
          taskId: task.id,
          newStatus: targetStatus,
          newOrder: newOrder,
        );
  }

  void _onQuickAdd(
    WidgetRef ref,
    String title,
    String status,
    List<TaskModel> currentTasks,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final order = currentTasks.isEmpty ? 0 : currentTasks.last.order + 1;
    ref.read(taskActionProvider.notifier).createTask(
          spaceId: spaceId,
          boardId: boardId,
          title: title,
          status: status,
          userId: userId,
          order: order,
        );
  }
}

/// Compact layout: all 3 columns stacked vertically on one screen.
class _CompactKanbanLayout extends ConsumerStatefulWidget {
  const _CompactKanbanLayout({
    required this.spaceId,
    required this.boardId,
    required this.tasksByStatus,
    required this.memberNames,
    required this.wipLimits,
  });

  final String spaceId;
  final String boardId;
  final Map<String, List<TaskModel>> tasksByStatus;
  final Map<String, String> memberNames;
  final Map<String, int> wipLimits;

  @override
  ConsumerState<_CompactKanbanLayout> createState() =>
      _CompactKanbanLayoutState();
}

class _CompactKanbanLayoutState extends ConsumerState<_CompactKanbanLayout> {
  /// Track which column the drag is currently hovering over.
  String? _dragOverStatus;

  /// True while any task is being dragged — used to disable
  /// ListView scroll inside columns so the drag gesture can
  /// escape the source column and reach other DragTargets.
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ext.gradientTop, ext.gradientBottom],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < _kanbanStatuses.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Expanded(
                child: DragTarget<TaskModel>(
                  hitTestBehavior: HitTestBehavior.translucent,
                  onWillAcceptWithDetails: (details) {
                    if (details.data.status != _kanbanStatuses[i]) {
                      setState(() => _dragOverStatus = _kanbanStatuses[i]);
                    }
                    return true;
                  },
                  onLeave: (_) {
                    if (_dragOverStatus == _kanbanStatuses[i]) {
                      setState(() => _dragOverStatus = null);
                    }
                  },
                  onAcceptWithDetails: (details) {
                    setState(() {
                      _dragOverStatus = null;
                      _isDragging = false;
                    });
                    HapticFeedback.lightImpact();
                    _onTaskDroppedWithCheck(
                      details.data,
                      _kanbanStatuses[i],
                      widget.tasksByStatus[_kanbanStatuses[i]] ?? [],
                    );
                  },
                  builder: (context, candidateData, rejectedData) {
                    return CompactKanbanColumn(
                      status: _kanbanStatuses[i],
                      tasks:
                          widget.tasksByStatus[_kanbanStatuses[i]] ?? [],
                      memberNames: widget.memberNames,
                      wipLimit: widget.wipLimits[_kanbanStatuses[i]],
                      isDragOver: _dragOverStatus == _kanbanStatuses[i],
                      isDragging: _isDragging,
                      onDragStarted: () {
                        setState(() => _isDragging = true);
                      },
                      onDragEnd: () {
                        setState(() {
                          _isDragging = false;
                          _dragOverStatus = null;
                        });
                      },
                      onQuickAdd: (title) => _onQuickAdd(
                        title,
                        _kanbanStatuses[i],
                        widget.tasksByStatus[_kanbanStatuses[i]] ?? [],
                      ),
                      onTaskTap: (task) => context.go(
                          '/spaces/${widget.spaceId}/task/${task.id}'),
                      onTaskCompleted: (task) => _onTaskDropped(
                        task,
                        'done',
                        widget.tasksByStatus['done'] ?? [],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onTaskDropped(
    TaskModel task,
    String targetStatus,
    List<TaskModel> targetTasks,
  ) {
    final newOrder = targetTasks.isEmpty ? 0 : targetTasks.last.order + 1;
    ref.read(taskActionProvider.notifier).moveTask(
          spaceId: widget.spaceId,
          taskId: task.id,
          newStatus: targetStatus,
          newOrder: newOrder,
        );
  }

  Future<void> _onTaskDroppedWithCheck(
    TaskModel task,
    String targetStatus,
    List<TaskModel> targetTasks,
  ) async {
    final allowed = await _checkWipLimit(
        context, widget.wipLimits, targetStatus, targetTasks, task);
    if (!allowed) return;
    _onTaskDropped(task, targetStatus, targetTasks);
  }

  void _onQuickAdd(
    String title,
    String status,
    List<TaskModel> currentTasks,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final order = currentTasks.isEmpty ? 0 : currentTasks.last.order + 1;
    ref.read(taskActionProvider.notifier).createTask(
          spaceId: widget.spaceId,
          boardId: widget.boardId,
          title: title,
          status: status,
          userId: userId,
          order: order,
        );
  }
}

/// Mobile layout: horizontal page view for swiping between columns.
class _MobileKanbanLayout extends ConsumerStatefulWidget {
  const _MobileKanbanLayout({
    required this.spaceId,
    required this.boardId,
    required this.tasksByStatus,
    required this.memberNames,
    required this.wipLimits,
  });

  final String spaceId;
  final String boardId;
  final Map<String, List<TaskModel>> tasksByStatus;
  final Map<String, String> memberNames;
  final Map<String, int> wipLimits;

  @override
  ConsumerState<_MobileKanbanLayout> createState() =>
      _MobileKanbanLayoutState();
}

class _MobileKanbanLayoutState extends ConsumerState<_MobileKanbanLayout> {
  int _currentPage = 0;
  late final PageController _pageController;

  /// True while a task card is being dragged – used to show drop-zone overlays.
  bool _isDragging = false;

  /// Which overlay drop-zone is currently hovered.
  String? _hoverDropZone;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Short mobile labels for the segmented control.
  static const _mobileLabels = {
    'todo': 'To Do',
    'in_progress': 'Working on it',
    'done': 'Done!',
  };

  /// Icons for each status used in the drop-zone overlays.
  static const _statusIcons = {
    'todo': Icons.inbox_rounded,
    'in_progress': Icons.play_circle_outline_rounded,
    'done': Icons.check_circle_outline_rounded,
  };

  /// Returns the two statuses that are NOT the current page.
  List<String> get _otherStatuses =>
      _kanbanStatuses.where((s) => s != _kanbanStatuses[_currentPage]).toList();

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          // Cupertino segmented control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _currentPage,
                backgroundColor: colors.primaryContainer,
                thumbColor: colors.primary,
                children: {
                  for (var i = 0; i < _kanbanStatuses.length; i++)
                    i: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      child: Text(
                        _mobileLabels[_kanbanStatuses[i]] ??
                            _kanbanStatuses[i],
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _currentPage == i
                              ? Colors.white
                              : colors.onSurface,
                        ),
                      ),
                    ),
                },
                onValueChanged: (value) {
                  if (value != null) {
                    _pageController.animateToPage(
                      value,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ),

          // Page view with columns + drop-zone overlays
          Expanded(
            child: Stack(
              children: [
                // ── Main page view ──
                PageView.builder(
                  controller: _pageController,
                  physics: _isDragging
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  itemCount: _kanbanStatuses.length,
                  onPageChanged: (page) =>
                      setState(() => _currentPage = page),
                  itemBuilder: (context, index) {
                    final status = _kanbanStatuses[index];
                    final tasks = widget.tasksByStatus[status] ?? [];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16)
                          .copyWith(bottom: 12),
                      child: KanbanColumn(
                        status: status,
                        tasks: tasks,
                        memberNames: widget.memberNames,
                        wipLimit: widget.wipLimits[status],
                        spaceId: widget.spaceId,
                        boardId: widget.boardId,
                        onTaskDropped: (task) =>
                            _onTaskDropped(task, status, tasks),
                        onQuickAdd: (title) =>
                            _onQuickAdd(title, status, tasks),
                        onTaskTap: (task) => context.go(
                            '/spaces/${widget.spaceId}/task/${task.id}'),
                        onTaskCompleted: (task) =>
                            _onTaskDropped(task, 'done', []),
                        onArchiveCompleted: status == 'done'
                            ? () => _archiveCompleted()
                            : null,
                        onDragStarted: () =>
                            setState(() => _isDragging = true),
                        onDragEnd: () => setState(() {
                          _isDragging = false;
                          _hoverDropZone = null;
                        }),
                      ),
                    );
                  },
                ),

                // ── Floating drop-zone overlays ──
                if (_isDragging)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            for (var i = 0;
                                i < _otherStatuses.length;
                                i++) ...[
                              if (i > 0) const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropZone(
                                  _otherStatuses[i],
                                  colors,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single floating drop-zone for [targetStatus].
  Widget _buildDropZone(
    String targetStatus,
    ColorScheme colors,
  ) {
    final isHovered = _hoverDropZone == targetStatus;
    final accent = AppColors.statusAccent(targetStatus);
    final label =
        _mobileLabels[targetStatus] ?? targetStatus;
    final icon = _statusIcons[targetStatus] ?? Icons.move_down_rounded;

    return DragTarget<TaskModel>(
      hitTestBehavior: HitTestBehavior.translucent,
      onWillAcceptWithDetails: (details) {
        if (details.data.status != targetStatus) {
          setState(() => _hoverDropZone = targetStatus);
        }
        return true;
      },
      onLeave: (_) {
        if (_hoverDropZone == targetStatus) {
          setState(() => _hoverDropZone = null);
        }
      },
      onAcceptWithDetails: (details) {
        setState(() {
          _hoverDropZone = null;
          _isDragging = false;
        });
        HapticFeedback.lightImpact();
        _onTaskDropped(
          details.data,
          targetStatus,
          widget.tasksByStatus[targetStatus] ?? [],
        );
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isHovered
                ? accent.withValues(alpha: 0.25)
                : colors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? accent : colors.outline.withValues(alpha: 0.3),
              width: isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isHovered ? accent : colors.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _archiveCompleted() async {
    final count = await ref.read(firestoreServiceProvider).archiveCompletedTasks(
      spaceId: widget.spaceId,
      boardId: widget.boardId,
    );
    if (mounted && count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archived $count completed tasks')),
      );
    }
  }

  Future<void> _onTaskDropped(
      TaskModel task, String targetStatus, List<TaskModel> targetTasks) async {
    final allowed = await _checkWipLimit(
        context, widget.wipLimits, targetStatus, targetTasks, task);
    if (!allowed) return;

    final newOrder =
        targetTasks.isEmpty ? 0 : targetTasks.last.order + 1;
    ref.read(taskActionProvider.notifier).moveTask(
          spaceId: widget.spaceId,
          taskId: task.id,
          newStatus: targetStatus,
          newOrder: newOrder,
        );
  }

  void _onQuickAdd(
      String title, String status, List<TaskModel> currentTasks) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final order =
        currentTasks.isEmpty ? 0 : currentTasks.last.order + 1;
    ref.read(taskActionProvider.notifier).createTask(
          spaceId: widget.spaceId,
          boardId: widget.boardId,
          title: title,
          status: status,
          userId: userId,
          order: order,
        );
  }
}

// ── Board Filter Chip Bar ───────────────────────────────────────────

class _BoardFilterBar extends ConsumerWidget {
  const _BoardFilterBar({
    required this.memberNames,
    required this.emojiTags,
  });

  final Map<String, String> memberNames;
  final List<String> emojiTags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(boardFilterProvider);
    final colors = Theme.of(context).colorScheme;

    if (!filter.isActive &&
        memberNames.length <= 1 &&
        emojiTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          // Assignee filter
          if (memberNames.length > 1)
            _FilterChip(
              label: filter.assigneeId != null
                  ? memberNames[filter.assigneeId] ?? 'Member'
                  : 'Assignee',
              icon: Icons.person_outline,
              isActive: filter.assigneeId != null,
              onTap: () => _showAssigneePicker(context, ref),
              onClear: filter.assigneeId != null
                  ? () => ref.read(boardFilterProvider.notifier).state =
                      filter.copyWith(assigneeId: () => null)
                  : null,
            ),

          // Emoji tag filter
          if (emojiTags.isNotEmpty) ...[
            const SizedBox(width: 6),
            _FilterChip(
              label: filter.emojiTag ?? 'Tag',
              icon: filter.emojiTag != null ? null : Icons.sell_outlined,
              isActive: filter.emojiTag != null,
              onTap: () => _showTagPicker(context, ref),
              onClear: filter.emojiTag != null
                  ? () => ref.read(boardFilterProvider.notifier).state =
                      filter.copyWith(emojiTag: () => null)
                  : null,
            ),
          ],

          // Due date filter
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Has due date',
            icon: Icons.calendar_today,
            isActive: filter.hasDueDate == true,
            onTap: () => ref.read(boardFilterProvider.notifier).state =
                filter.copyWith(
                    hasDueDate: () =>
                        filter.hasDueDate == true ? null : true),
          ),

          // Blocked filter
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Blocked',
            icon: Icons.block,
            isActive: filter.isBlocked == true,
            onTap: () => ref.read(boardFilterProvider.notifier).state =
                filter.copyWith(
                    isBlocked: () =>
                        filter.isBlocked == true ? null : true),
          ),

          // Clear all
          if (filter.isActive) ...[
            const SizedBox(width: 6),
            ActionChip(
              avatar: Icon(Icons.clear, size: 16, color: colors.error),
              label: Text(
                'Clear',
                style: TextStyle(fontSize: 12, color: colors.error),
              ),
              onPressed: () => ref.read(boardFilterProvider.notifier).state =
                  const BoardFilter(),
              side: BorderSide(color: colors.error.withValues(alpha: 0.3)),
              backgroundColor: colors.error.withValues(alpha: 0.06),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  void _showAssigneePicker(BuildContext context, WidgetRef ref) {
    final filter = ref.read(boardFilterProvider);
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
                child: Text(
                  'Filter by assignee',
                  style: AppTextStyles.headingSmall,
                ),
              ),
              ...memberNames.entries.map((entry) {
                final isSelected = filter.assigneeId == entry.key;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Text(
                      entry.value.isNotEmpty
                          ? entry.value[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(entry.value),
                  trailing: isSelected
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(boardFilterProvider.notifier).state =
                        filter.copyWith(
                      assigneeId: () =>
                          isSelected ? null : entry.key,
                    );
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

  void _showTagPicker(BuildContext context, WidgetRef ref) {
    final filter = ref.read(boardFilterProvider);
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
                child: Text(
                  'Filter by tag',
                  style: AppTextStyles.headingSmall,
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: emojiTags.map((tag) {
                  final isSelected = filter.emojiTag == tag;
                  return GestureDetector(
                    onTap: () {
                      ref.read(boardFilterProvider.notifier).state =
                          filter.copyWith(
                        emojiTag: () => isSelected ? null : tag,
                      );
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(tag, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? colors.primary.withValues(alpha: 0.12)
              : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? colors.primary.withValues(alpha: 0.4)
                : colors.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  icon,
                  size: 14,
                  color: isActive ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? colors.primary : colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: colors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
