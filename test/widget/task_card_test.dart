import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/theme/app_theme.dart';
import 'package:lifeboard/widgets/task_card.dart';

Widget _wrapWidget(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

final _now = DateTime(2025, 6, 15);

final _basicTask = TaskModel(
  id: 'task-1',
  title: 'Buy groceries',
  status: 'todo',
  boardId: 'board-1',
  createdBy: 'user-1',
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  group('TaskCard', () {
    testWidgets('renders task title', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(TaskCard(task: _basicTask)),
      );

      expect(find.text('Buy groceries'), findsOneWidget);
    });

    testWidgets('renders emoji tag when present', (tester) async {
      final task = _basicTask.copyWith(emojiTag: '\u{1F4B0}');
      await tester.pumpWidget(
        _wrapWidget(TaskCard(task: task)),
      );

      expect(find.text('\u{1F4B0}'), findsOneWidget);
    });

    testWidgets('does not render emoji tag when absent', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(TaskCard(task: _basicTask)),
      );

      // No emoji text should be present besides the title
      expect(find.text('\u{1F4B0}'), findsNothing);
    });

    testWidgets('renders due date when set', (tester) async {
      final task = _basicTask.copyWith(dueDate: DateTime(2025, 7, 20));
      await tester.pumpWidget(
        _wrapWidget(TaskCard(task: task)),
      );

      expect(find.text('Jul 20'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('does not render due date when not set', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(TaskCard(task: _basicTask)),
      );

      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });

    testWidgets('renders assignee avatars', (tester) async {
      final task = _basicTask.copyWith(assignees: ['user-1', 'user-2']);
      await tester.pumpWidget(
        _wrapWidget(TaskCard(
          task: task,
          memberNames: {
            'user-1': 'Alex Smith',
            'user-2': 'Jordan Lee',
          },
        )),
      );

      // Avatars should show initials
      expect(find.text('AS'), findsOneWidget);
      expect(find.text('JL'), findsOneWidget);
    });

    testWidgets('renders subtask progress', (tester) async {
      final task = _basicTask.copyWith(subtasks: [
        const Subtask(id: 's1', title: 'Milk', completed: true),
        const Subtask(id: 's2', title: 'Bread', completed: false),
        const Subtask(id: 's3', title: 'Eggs', completed: true),
      ]);
      await tester.pumpWidget(
        _wrapWidget(TaskCard(task: task)),
      );

      expect(find.text('2/3'), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsOneWidget);
    });

    testWidgets('calls onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrapWidget(TaskCard(
          task: _basicTask,
          onTap: () => tapped = true,
        )),
      );

      await tester.tap(find.text('Buy groceries'));
      expect(tapped, isTrue);
    });
  });
}
