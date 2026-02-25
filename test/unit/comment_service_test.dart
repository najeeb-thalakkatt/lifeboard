import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifeboard/models/comment_model.dart';
import 'package:lifeboard/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  const spaceId = 'space1';
  const taskId = 'task1';

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: fakeFirestore);

    // Seed a space + task so the subcollection path is valid.
    await fakeFirestore
        .collection('spaces')
        .doc(spaceId)
        .collection('tasks')
        .doc(taskId)
        .set({'title': 'Test task', 'status': 'todo'});
  });

  group('addComment', () {
    test('creates a comment in the subcollection', () async {
      final comment = await service.addComment(
        spaceId: spaceId,
        taskId: taskId,
        text: 'Hello!',
        authorId: 'user1',
      );

      expect(comment.id, isNotEmpty);
      expect(comment.text, 'Hello!');
      expect(comment.authorId, 'user1');
      expect(comment.reactions, isEmpty);

      // Verify it was persisted
      final snap = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(taskId)
          .collection('comments')
          .get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['text'], 'Hello!');
    });

    test('multiple comments are stored independently', () async {
      await service.addComment(
        spaceId: spaceId,
        taskId: taskId,
        text: 'First',
        authorId: 'user1',
      );
      await service.addComment(
        spaceId: spaceId,
        taskId: taskId,
        text: 'Second',
        authorId: 'user2',
      );

      final snap = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(taskId)
          .collection('comments')
          .get();
      expect(snap.docs.length, 2);
    });
  });

  group('getComments', () {
    test('streams comments ordered by createdAt', () async {
      final ref = fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(taskId)
          .collection('comments');

      await ref.doc('c1').set({
        'text': 'First',
        'authorId': 'user1',
        'reactions': {},
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      await ref.doc('c2').set({
        'text': 'Second',
        'authorId': 'user2',
        'reactions': {},
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
      });

      final comments = await service
          .getComments(spaceId: spaceId, taskId: taskId)
          .first;

      expect(comments.length, 2);
      expect(comments[0].text, 'First');
      expect(comments[1].text, 'Second');
      expect(comments[0].id, 'c1');
      expect(comments[1].id, 'c2');
    });

    test('returns empty list when no comments', () async {
      final comments = await service
          .getComments(spaceId: spaceId, taskId: taskId)
          .first;
      expect(comments, isEmpty);
    });
  });

  group('toggleReaction', () {
    late String commentId;

    setUp(() async {
      final comment = await service.addComment(
        spaceId: spaceId,
        taskId: taskId,
        text: 'React to me',
        authorId: 'user1',
      );
      commentId = comment.id;
    });

    test('adds a reaction when user has not reacted', () async {
      await service.toggleReaction(
        spaceId: spaceId,
        taskId: taskId,
        commentId: commentId,
        emoji: '❤️',
        userId: 'user1',
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(taskId)
          .collection('comments')
          .doc(commentId)
          .get();

      final comment = CommentModel.fromFirestore(doc);
      expect(comment.reactions['❤️'], contains('user1'));
    });

    test('removes a reaction when user already reacted (toggle off)', () async {
      // Add reaction
      await service.toggleReaction(
        spaceId: spaceId,
        taskId: taskId,
        commentId: commentId,
        emoji: '👍',
        userId: 'user1',
      );

      // Toggle off
      await service.toggleReaction(
        spaceId: spaceId,
        taskId: taskId,
        commentId: commentId,
        emoji: '👍',
        userId: 'user1',
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(taskId)
          .collection('comments')
          .doc(commentId)
          .get();

      final comment = CommentModel.fromFirestore(doc);
      expect(comment.reactions.containsKey('👍'), isFalse);
    });

    test('multiple users can react with same emoji', () async {
      await service.toggleReaction(
        spaceId: spaceId,
        taskId: taskId,
        commentId: commentId,
        emoji: '❤️',
        userId: 'user1',
      );
      await service.toggleReaction(
        spaceId: spaceId,
        taskId: taskId,
        commentId: commentId,
        emoji: '❤️',
        userId: 'user2',
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(taskId)
          .collection('comments')
          .doc(commentId)
          .get();

      final comment = CommentModel.fromFirestore(doc);
      expect(comment.reactions['❤️']!.length, 2);
      expect(comment.reactions['❤️'], containsAll(['user1', 'user2']));
    });

    test('different emojis are tracked independently', () async {
      await service.toggleReaction(
        spaceId: spaceId,
        taskId: taskId,
        commentId: commentId,
        emoji: '❤️',
        userId: 'user1',
      );
      await service.toggleReaction(
        spaceId: spaceId,
        taskId: taskId,
        commentId: commentId,
        emoji: '😂',
        userId: 'user1',
      );

      final doc = await fakeFirestore
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .doc(taskId)
          .collection('comments')
          .doc(commentId)
          .get();

      final comment = CommentModel.fromFirestore(doc);
      expect(comment.reactions.keys, containsAll(['❤️', '😂']));
      expect(comment.reactions['❤️'], ['user1']);
      expect(comment.reactions['😂'], ['user1']);
    });

    test('does nothing for non-existent comment', () async {
      // Should not throw
      await service.toggleReaction(
        spaceId: spaceId,
        taskId: taskId,
        commentId: 'nonexistent',
        emoji: '❤️',
        userId: 'user1',
      );
    });
  });
}
