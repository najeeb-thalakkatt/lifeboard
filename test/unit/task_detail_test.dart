import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  const spaceId = 'test-space';
  const userId = 'user-1';
  const boardId = 'board-1';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: fakeFirestore);
  });

  group('Task Detail CRUD', () {
    test('createTask creates a task with correct fields', () async {
      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: 'Test Task',
        description: 'A description',
        status: 'todo',
        boardId: boardId,
        assignees: [userId],
        emojiTag: '\u{1F4B0}',
        order: 0,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );

      final created = await service.createTask(spaceId: spaceId, task: task);
      expect(created.id, isNotEmpty);
      expect(created.title, 'Test Task');
      expect(created.description, 'A description');
      expect(created.emojiTag, '\u{1F4B0}');

      // Verify in Firestore
      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(created.id)
          .get();
      expect(doc.exists, true);
      expect(doc.data()!['title'], 'Test Task');
    });

    test('updateTask updates title', () async {
      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: 'Original',
        status: 'todo',
        boardId: boardId,
        order: 0,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      final created = await service.createTask(spaceId: spaceId, task: task);

      await service.updateTask(
        spaceId: spaceId,
        taskId: created.id,
        fields: {'title': 'Updated Title'},
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(created.id)
          .get();
      expect(doc.data()!['title'], 'Updated Title');
      expect(doc.data()!['updatedAt'], isA<Timestamp>());
    });

    test('updateTask updates status to done with completedAt', () async {
      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: 'Do this',
        status: 'todo',
        boardId: boardId,
        order: 0,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      final created = await service.createTask(spaceId: spaceId, task: task);

      await service.updateTask(
        spaceId: spaceId,
        taskId: created.id,
        fields: {
          'status': 'done',
          'completedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(created.id)
          .get();
      expect(doc.data()!['status'], 'done');
      expect(doc.data()!['completedAt'], isA<Timestamp>());
    });

    test('updateTask updates assignees', () async {
      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: 'Shared task',
        status: 'todo',
        boardId: boardId,
        assignees: [userId],
        order: 0,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      final created = await service.createTask(spaceId: spaceId, task: task);

      await service.updateTask(
        spaceId: spaceId,
        taskId: created.id,
        fields: {
          'assignees': [userId, 'user-2'],
        },
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(created.id)
          .get();
      expect(doc.data()!['assignees'], [userId, 'user-2']);
    });

    test('updateTask updates subtasks', () async {
      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: 'Task with subtasks',
        status: 'todo',
        boardId: boardId,
        order: 0,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      final created = await service.createTask(spaceId: spaceId, task: task);

      await service.updateTask(
        spaceId: spaceId,
        taskId: created.id,
        fields: {
          'subtasks': [
            {'id': 'st-1', 'title': 'Sub 1', 'completed': false},
            {'id': 'st-2', 'title': 'Sub 2', 'completed': true},
          ],
        },
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(created.id)
          .get();
      final subtasks = doc.data()!['subtasks'] as List;
      expect(subtasks.length, 2);
      expect(subtasks[0]['title'], 'Sub 1');
      expect(subtasks[1]['completed'], true);
    });

    test('updateTask updates emojiTag', () async {
      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: 'Tagged task',
        status: 'todo',
        boardId: boardId,
        order: 0,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      final created = await service.createTask(spaceId: spaceId, task: task);

      await service.updateTask(
        spaceId: spaceId,
        taskId: created.id,
        fields: {'emojiTag': '\u{1F3E1}'},
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(created.id)
          .get();
      expect(doc.data()!['emojiTag'], '\u{1F3E1}');
    });

    test('updateTask updates dueDate', () async {
      final now = DateTime.now();
      final dueDate = DateTime(2026, 3, 15);
      final task = TaskModel(
        id: '',
        title: 'Due task',
        status: 'todo',
        boardId: boardId,
        order: 0,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      final created = await service.createTask(spaceId: spaceId, task: task);

      await service.updateTask(
        spaceId: spaceId,
        taskId: created.id,
        fields: {'dueDate': Timestamp.fromDate(dueDate)},
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(created.id)
          .get();
      expect(doc.data()!['dueDate'], isA<Timestamp>());
    });

    test('updateTask clears dueDate with null', () async {
      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: 'Clear due date',
        status: 'todo',
        boardId: boardId,
        dueDate: DateTime(2026, 3, 15),
        order: 0,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      final created = await service.createTask(spaceId: spaceId, task: task);

      await service.updateTask(
        spaceId: spaceId,
        taskId: created.id,
        fields: {'dueDate': null},
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(created.id)
          .get();
      expect(doc.data()!['dueDate'], isNull);
    });

    test('updateTask updates description', () async {
      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: 'Desc task',
        status: 'todo',
        boardId: boardId,
        order: 0,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      final created = await service.createTask(spaceId: spaceId, task: task);

      await service.updateTask(
        spaceId: spaceId,
        taskId: created.id,
        fields: {'description': 'New detailed description'},
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(created.id)
          .get();
      expect(doc.data()!['description'], 'New detailed description');
    });

    test('deleteTask removes the task', () async {
      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: 'Delete me',
        status: 'todo',
        boardId: boardId,
        order: 0,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      final created = await service.createTask(spaceId: spaceId, task: task);

      await service.deleteTask(spaceId: spaceId, taskId: created.id);

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(created.id)
          .get();
      expect(doc.exists, false);
    });

    test('updateTask updates attachments', () async {
      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: 'Attachment task',
        status: 'todo',
        boardId: boardId,
        order: 0,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );
      final created = await service.createTask(spaceId: spaceId, task: task);

      await service.updateTask(
        spaceId: spaceId,
        taskId: created.id,
        fields: {
          'attachments': [
            {'url': 'https://example.com/photo.jpg', 'type': 'image', 'name': 'photo.jpg'},
          ],
        },
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(created.id)
          .get();
      final attachments = doc.data()!['attachments'] as List;
      expect(attachments.length, 1);
      expect(attachments[0]['type'], 'image');
    });
  });
}
