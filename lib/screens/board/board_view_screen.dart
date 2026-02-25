import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/providers/board_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/providers/task_provider.dart';
import 'package:lifeboard/screens/board/kanban_column.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/shared_app_bar.dart';

/// The statuses (columns) shown on the kanban board.
const _kanbanStatuses = ['todo', 'in_progress', 'done'];

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

class _BoardContent extends ConsumerWidget {
  const _BoardContent({
    required this.spaceId,
    required this.boardId,
    required this.boardName,
  });

  final String spaceId;
  final String boardId;
  final String boardName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(
      boardTasksProvider((spaceId: spaceId, boardId: boardId)),
    );
    final membersAsync = ref.watch(spaceMembersProvider(spaceId));

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
      appBar: SharedAppBar(title: boardName),
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
                  boardTasksProvider((spaceId: spaceId, boardId: boardId)),
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
              spaceId: spaceId,
              boardId: boardId,
              tasksByStatus: tasksByStatus,
              memberNames: memberNames,
            );
          }

          return _MobileKanbanLayout(
            spaceId: spaceId,
            boardId: boardId,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < _kanbanStatuses.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        StatusDisplayName.fromStatus(_kanbanStatuses[i]),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _currentPage == i
                              ? AppColors.surface
                              : AppColors.primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Page view with columns
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _kanbanStatuses.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
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
                  onTaskDropped: (task) => _onTaskDropped(task, status, tasks),
                  onQuickAdd: (title) => _onQuickAdd(title, status, tasks),
                  onTaskTap: (task) => context.go('/spaces/${widget.spaceId}/task/${task.id}'),
                ),
              );
            },
          ),
        ),
      ],
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
