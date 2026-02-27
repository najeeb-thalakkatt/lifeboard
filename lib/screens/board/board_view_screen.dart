import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/providers/board_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/providers/task_provider.dart';
import 'package:lifeboard/screens/board/compact_kanban_column.dart';
import 'package:lifeboard/screens/board/kanban_column.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/shared_app_bar.dart';

/// The statuses (columns) shown on the kanban board.
const _kanbanStatuses = ['todo', 'in_progress', 'done'];

/// Board view modes for mobile.
enum _BoardViewMode { tabs, columns }

/// Main kanban board screen displaying tasks in 3 columns.
class BoardViewScreen extends ConsumerStatefulWidget {
  const BoardViewScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<BoardViewScreen> createState() => _BoardViewScreenState();
}

class _BoardViewScreenState extends ConsumerState<BoardViewScreen> {
  @override
  Widget build(BuildContext context) {
    final defaultBoard = ref.watch(defaultBoardProvider(widget.spaceId));

    return defaultBoard.when(
      loading: () => Scaffold(
        appBar: const SharedAppBar(title: 'Board'),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: const SharedAppBar(title: 'Board'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load board', style: AppTextStyles.bodyLarge),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(defaultBoardProvider(widget.spaceId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (board) => _BoardContent(
        spaceId: widget.spaceId,
        boardId: board.id,
        boardName: board.name,
      ),
    );
  }
}

class _BoardContent extends ConsumerStatefulWidget {
  const _BoardContent({
    required this.spaceId,
    required this.boardId,
    required this.boardName,
  });

  final String spaceId;
  final String boardId;
  final String boardName;

  @override
  ConsumerState<_BoardContent> createState() => _BoardContentState();
}

class _BoardContentState extends ConsumerState<_BoardContent> {
  _BoardViewMode _viewMode = _BoardViewMode.tabs;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(
      boardTasksProvider((spaceId: widget.spaceId, boardId: widget.boardId)),
    );
    final membersAsync = ref.watch(spaceMembersProvider(widget.spaceId));

    // Build member names map for avatars
    final memberNames = <String, String>{};
    membersAsync.whenData((members) {
      // SpaceMember doesn't have displayName, so we use userId as fallback.
      // In a real app, you'd fetch user docs. For now, just use IDs.
      for (final userId in members.keys) {
        memberNames[userId] = userId;
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideLayout = screenWidth >= 600;

    return Scaffold(
      appBar: SharedAppBar(
        title: widget.boardName,
        actions: [
          if (!isWideLayout)
            IconButton(
              onPressed: () => setState(() {
                _viewMode = _viewMode == _BoardViewMode.tabs
                    ? _BoardViewMode.columns
                    : _BoardViewMode.tabs;
              }),
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
          // Group tasks by status
          final tasksByStatus = <String, List<TaskModel>>{};
          for (final status in _kanbanStatuses) {
            tasksByStatus[status] = allTasks
                .where((t) => t.status == status)
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));
          }

          if (isWideLayout) {
            return _WideKanbanLayout(
              spaceId: widget.spaceId,
              boardId: widget.boardId,
              tasksByStatus: tasksByStatus,
              memberNames: memberNames,
            );
          }

          if (_viewMode == _BoardViewMode.columns) {
            return _CompactKanbanLayout(
              spaceId: widget.spaceId,
              boardId: widget.boardId,
              tasksByStatus: tasksByStatus,
              memberNames: memberNames,
            );
          }

          return _MobileKanbanLayout(
            spaceId: widget.spaceId,
            boardId: widget.boardId,
            tasksByStatus: tasksByStatus,
            memberNames: memberNames,
          );
        },
      ),
    );
  }
}

/// Wide layout: side-by-side columns.
class _WideKanbanLayout extends ConsumerWidget {
  const _WideKanbanLayout({
    required this.spaceId,
    required this.boardId,
    required this.tasksByStatus,
    required this.memberNames,
  });

  final String spaceId;
  final String boardId;
  final Map<String, List<TaskModel>> tasksByStatus;
  final Map<String, String> memberNames;

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
                onTaskDropped: (task) => _onTaskDropped(
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
                  ref,
                  task,
                  'done',
                  tasksByStatus['done'] ?? [],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onTaskDropped(
    WidgetRef ref,
    TaskModel task,
    String targetStatus,
    List<TaskModel> targetTasks,
  ) {
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
  });

  final String spaceId;
  final String boardId;
  final Map<String, List<TaskModel>> tasksByStatus;
  final Map<String, String> memberNames;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [AppColors.darkGradientTop, AppColors.darkGradientBottom]
        : [AppColors.gradientTop, AppColors.gradientBottom];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
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
                    _onTaskDropped(
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
  });

  final String spaceId;
  final String boardId;
  final Map<String, List<TaskModel>> tasksByStatus;
  final Map<String, String> memberNames;

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
    'in_progress': 'Doing',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final gradientColors = isDark
        ? [AppColors.darkGradientTop, AppColors.darkGradientBottom]
        : [AppColors.gradientTop, AppColors.gradientBottom];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
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
                        onTaskDropped: (task) =>
                            _onTaskDropped(task, status, tasks),
                        onQuickAdd: (title) =>
                            _onQuickAdd(title, status, tasks),
                        onTaskTap: (task) => context.go(
                            '/spaces/${widget.spaceId}/task/${task.id}'),
                        onTaskCompleted: (task) =>
                            _onTaskDropped(task, 'done', []),
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
                                  isDark,
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
    bool isDark,
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
                : (isDark
                    ? colors.surface.withValues(alpha: 0.9)
                    : colors.surface.withValues(alpha: 0.95)),
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

  void _onTaskDropped(
      TaskModel task, String targetStatus, List<TaskModel> targetTasks) {
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
