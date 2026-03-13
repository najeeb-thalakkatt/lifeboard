import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/models/chore_model.dart';
import 'package:lifeboard/providers/chore_provider.dart';
import 'package:lifeboard/providers/homepad_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/providers/weekly_provider.dart';
import 'package:lifeboard/services/widget_service.dart';

/// Pushes weekly task data to the iOS widget whenever it changes.
final widgetWeeklyUpdater = Provider<void>((ref) {
  final weeklyTasks = ref.watch(weeklyTasksProvider);
  final summary = ref.watch(weeklySummaryProvider);

  final inProgress =
      weeklyTasks.where((e) => e.task.status == 'in_progress').length;

  final taskEntries = weeklyTasks
      .where((e) => e.task.archivedAt == null)
      .map((e) => WidgetService.buildTaskEntry(
            title: e.task.title,
            status: e.task.status,
            emoji: e.task.emojiTag,
            dueDate: e.task.dueDate,
          ))
      .toList();

  WidgetService.updateWeeklyData(
    total: summary.total,
    completed: summary.completed,
    inProgress: inProgress,
    tasks: taskEntries,
  );
});

/// Pushes chore data to the iOS widget whenever it changes.
final widgetChoresUpdater = Provider<void>((ref) {
  final spaceId = ref.watch(selectedSpaceProvider);
  if (spaceId == null) return;

  final todayChores = ref.watch(todayChoresProvider(spaceId));
  final memberNames = ref.watch(spaceMemberProfilesProvider(spaceId));

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final overdue = todayChores.where((c) => c.nextDueDate.isBefore(today)).length;

  String? assigneeInitial(Chore chore) {
    if (chore.assigneeId == null) return null;
    final name = memberNames[chore.assigneeId!];
    if (name == null || name.isEmpty) return null;
    return name[0].toUpperCase();
  }

  final choreEntries = todayChores
      .map((c) => WidgetService.buildChoreEntry(
            title: c.name,
            emoji: c.emoji,
            assignee: assigneeInitial(c),
            isOverdue: c.nextDueDate.isBefore(today),
          ))
      .toList();

  WidgetService.updateChoresData(
    todayDue: todayChores.length,
    overdue: overdue,
    items: choreEntries,
  );
});

/// Pushes buy list data to the iOS widget whenever it changes.
final widgetBuyListUpdater = Provider<void>((ref) {
  final spaceId = ref.watch(selectedSpaceProvider);
  if (spaceId == null) return;

  final toBuyItems = ref.watch(toBuyItemsProvider(spaceId));

  final itemEntries = toBuyItems
      .map((i) => WidgetService.buildBuyListEntry(
            title: i.name,
            category: i.category,
            emoji: i.emoji,
          ))
      .toList();

  WidgetService.updateBuyListData(
    totalItems: toBuyItems.length,
    items: itemEntries,
  );
});

/// Pushes user/space context to the widget.
final widgetUserContextUpdater = Provider<void>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  final spaces = ref.watch(userSpacesProvider).valueOrNull ?? [];
  final spaceId = ref.watch(selectedSpaceProvider);

  final userName = user?.displayName ?? user?.email?.split('@').first ?? '';
  final spaceName = spaceId != null
      ? spaces.where((s) => s.id == spaceId).map((s) => s.name).firstOrNull ??
          'Our Home'
      : 'Our Home';

  WidgetService.updateUserContext(
    userName: userName,
    spaceName: spaceName,
  );
});

/// Master provider that watches all widget updaters.
/// Watch this once from the app shell to keep widgets in sync.
final widgetSyncProvider = Provider<void>((ref) {
  ref.watch(widgetWeeklyUpdater);
  ref.watch(widgetChoresUpdater);
  ref.watch(widgetBuyListUpdater);
  ref.watch(widgetUserContextUpdater);
});
