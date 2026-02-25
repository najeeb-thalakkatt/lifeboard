import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/core/errors/app_exceptions.dart';
import 'package:lifeboard/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: fakeFirestore);
  });

  group('createSpace', () {
    test('creates a space with owner member and invite code', () async {
      final space = await service.createSpace(
        name: 'Our Home',
        userId: 'user1',
      );

      expect(space.name, 'Our Home');
      expect(space.inviteCode.length, 6);
      expect(space.members.containsKey('user1'), isTrue);
      expect(space.members['user1']?.role, 'owner');
      expect(space.themes, ['Home', 'Kids', 'Finances']);
      expect(space.id, isNotEmpty);
    });

    test('adds spaceId to user document', () async {
      // Create a user doc first
      await fakeFirestore.collection('users').doc('user1').set({
        'displayName': 'Alice',
        'email': 'alice@example.com',
        'spaceIds': [],
      });

      final space = await service.createSpace(
        name: 'Our Home',
        userId: 'user1',
      );

      final userDoc =
          await fakeFirestore.collection('users').doc('user1').get();
      final spaceIds = List<String>.from(userDoc.data()!['spaceIds'] as List);
      expect(spaceIds, contains(space.id));
    });

    test('generates unique invite codes', () async {
      final space1 = await service.createSpace(
        name: 'Space 1',
        userId: 'user1',
      );
      final space2 = await service.createSpace(
        name: 'Space 2',
        userId: 'user1',
      );

      expect(space1.inviteCode, isNot(equals(space2.inviteCode)));
    });
  });

  group('joinSpace', () {
    late SpaceModel createdSpace;

    setUp(() async {
      // Create a user doc for the owner
      await fakeFirestore.collection('users').doc('owner1').set({
        'displayName': 'Owner',
        'email': 'owner@example.com',
        'spaceIds': [],
      });

      // Create a user doc for the joiner
      await fakeFirestore.collection('users').doc('joiner1').set({
        'displayName': 'Joiner',
        'email': 'joiner@example.com',
        'spaceIds': [],
      });

      createdSpace = await service.createSpace(
        name: 'Our Home',
        userId: 'owner1',
      );
    });

    test('joins a space with valid invite code', () async {
      final joinedSpace = await service.joinSpace(
        inviteCode: createdSpace.inviteCode,
        userId: 'joiner1',
      );

      expect(joinedSpace.members.containsKey('joiner1'), isTrue);
      expect(joinedSpace.members['joiner1']?.role, 'member');
      expect(joinedSpace.members.containsKey('owner1'), isTrue);
    });

    test('adds spaceId to joiner user document', () async {
      await service.joinSpace(
        inviteCode: createdSpace.inviteCode,
        userId: 'joiner1',
      );

      final userDoc =
          await fakeFirestore.collection('users').doc('joiner1').get();
      final spaceIds = List<String>.from(userDoc.data()!['spaceIds'] as List);
      expect(spaceIds, contains(createdSpace.id));
    });

    test('throws SpaceNotFoundException for invalid code', () async {
      expect(
        () => service.joinSpace(
          inviteCode: 'ZZZZZZ',
          userId: 'joiner1',
        ),
        throwsA(isA<SpaceNotFoundException>()),
      );
    });

    test('throws AlreadyMemberException if already a member', () async {
      // Owner tries to join their own space
      expect(
        () => service.joinSpace(
          inviteCode: createdSpace.inviteCode,
          userId: 'owner1',
        ),
        throwsA(isA<AlreadyMemberException>()),
      );
    });
  });

  group('getSpacesForUser', () {
    test('returns stream of spaces for user', () async {
      await fakeFirestore.collection('users').doc('user1').set({
        'displayName': 'Alice',
        'email': 'alice@example.com',
        'spaceIds': [],
      });

      await service.createSpace(name: 'Space 1', userId: 'user1');
      await service.createSpace(name: 'Space 2', userId: 'user1');

      final spaces = await service.getSpacesForUser('user1').first;

      expect(spaces.length, 2);
      expect(spaces.map((s) => s.name), containsAll(['Space 1', 'Space 2']));
    });

    test('returns empty list for user with no spaces', () async {
      final spaces = await service.getSpacesForUser('nobody').first;
      expect(spaces, isEmpty);
    });
  });

  group('getSpaceMembers', () {
    test('returns stream of members for space', () async {
      await fakeFirestore.collection('users').doc('user1').set({
        'displayName': 'Alice',
        'email': 'alice@example.com',
        'spaceIds': [],
      });

      final space = await service.createSpace(
        name: 'Our Home',
        userId: 'user1',
      );

      final members = await service.getSpaceMembers(space.id).first;

      expect(members.length, 1);
      expect(members.containsKey('user1'), isTrue);
      expect(members['user1']?.role, 'owner');
    });

    test('returns empty map for non-existent space', () async {
      final members = await service.getSpaceMembers('nonexistent').first;
      expect(members, isEmpty);
    });
  });

  group('getSpace', () {
    test('returns space by id', () async {
      await fakeFirestore.collection('users').doc('user1').set({
        'displayName': 'Alice',
        'email': 'alice@example.com',
        'spaceIds': [],
      });

      final created = await service.createSpace(
        name: 'Our Home',
        userId: 'user1',
      );

      final fetched = await service.getSpace(created.id);

      expect(fetched, isNotNull);
      expect(fetched!.name, 'Our Home');
      expect(fetched.id, created.id);
    });

    test('returns null for non-existent space', () async {
      final fetched = await service.getSpace('nonexistent');
      expect(fetched, isNull);
    });
  });
}
