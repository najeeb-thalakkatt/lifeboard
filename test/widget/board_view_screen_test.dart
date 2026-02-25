import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifeboard/models/board_model.dart';
import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/providers/board_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/providers/task_provider.dart';
import 'package:lifeboard/screens/board/board_view_screen.dart';
import 'package:lifeboard/theme/app_theme.dart';
import 'package:lifeboard/models/space_model.dart';

// ── Test Data ─────────────────────────────────────────────────

final _testBoard = BoardModel(
  id: 'board-1',
  name: 'Home',
  createdBy: 'user-1',
  createdAt: DateTime(2025, 1, 1),
);

final _testTasks = [
  TaskModel(
    id: 'task-1',
    title: 'Buy groceries',
    status: 'todo',
    boardId: 'board-1',
    assignees: ['user-1'],
    order: 0,
    createdBy: 'user-1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  ),
  TaskModel(
    id: 'task-2',
    title: 'Clean kitchen',
    status: 'in_progress',
    boardId: 'board-1',
    assignees: ['user-2'],
    order: 0,
    createdBy: 'user-1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  ),
  TaskModel(
    id: 'task-3',
    title: 'Fix leaky faucet',
    status: 'done',
    boardId: 'board-1',
    assignees: ['user-1'],
    order: 0,
    createdBy: 'user-2',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  ),
];

final _testMembers = {
  'user-1': SpaceMember(role: 'owner', joinedAt: DateTime(2025, 1, 1)),
  'user-2': SpaceMember(role: 'member', joinedAt: DateTime(2025, 1, 2)),
};

// ── Helpers ─────────────────────────────────────────────────

Widget _buildTestApp({
  List<TaskModel>? tasks,
  bool loadingBoard = false,
  bool loadingTasks = false,
  String? boardError,
}) {
  return ProviderScope(
    overrides: [
      defaultBoardProvider('space-1').overrideWith((ref) {
        if (boardError != null) throw Exception(boardError);
        if (loadingBoard) return Completer<BoardModel>().future;
        return Future.value(_testBoard);
      }),
      boardTasksProvider(
        (spaceId: 'space-1', boardId: 'board-1'),
      ).overrideWith((ref) {
        if (loadingTasks) {
          return StreamController<List<TaskModel>>().stream;
        }
        return Stream.value(tasks ?? _testTasks);
      }),
      spaceMembersProvider('space-1').overrideWith((ref) {
        return Stream.value(_testMembers);
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const BoardViewScreen(spaceId: 'space-1'),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────

void main() {
  group('BoardViewScreen', () {
    testWidgets('shows loading indicator while board loads', (tester) async {
      await tester.pumpWidget(_buildTestApp(loadingBoard: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows all three column headers on wide layout',
        (tester) async {
      // Use a wide surface to trigger side-by-side layout
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('To Do'), findsOneWidget);
      expect(find.text('Working on it'), findsOneWidget);
      expect(find.text('We did it! \u{1F389}'), findsOneWidget);
    });

    testWidgets('displays task cards in correct columns (wide)',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Clean kitchen'), findsOneWidget);
      expect(find.text('Fix leaky faucet'), findsOneWidget);
    });

    testWidgets('shows task count badges (wide)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Each column has 1 task
      expect(find.text('1'), findsNWidgets(3));
    });

    testWidgets('shows mobile tab indicators on narrow layout',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // All three status labels should be visible as tab indicators
      expect(find.text('To Do'), findsWidgets);
      expect(find.text('Working on it'), findsWidgets);
    });

    testWidgets('shows empty column message when no tasks', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(tasks: []));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing here yet'), findsOneWidget);
    });

    testWidgets('shows Add task buttons (wide layout)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Each column should have an "Add task" prompt
      expect(find.text('Add task'), findsNWidgets(3));
    });

    testWidgets('tapping Add task shows text field', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tap the first "Add task" button
      await tester.tap(find.text('Add task').first);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Task title...'), findsOneWidget);
    });
  });
}
