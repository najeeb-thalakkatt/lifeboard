import 'package:flutter_test/flutter_test.dart';
import 'package:lifeboard/models/space_model.dart';

void main() {
  group('SpaceMember', () {
    test('creates with required fields', () {
      final member = SpaceMember(
        role: 'owner',
        joinedAt: DateTime(2025, 1, 1),
      );

      expect(member.role, 'owner');
      expect(member.joinedAt, DateTime(2025, 1, 1));
    });

    test('serializes to/from JSON', () {
      final member = SpaceMember(
        role: 'member',
        joinedAt: DateTime(2025, 6, 15),
      );

      final json = member.toJson();
      final restored = SpaceMember.fromJson(json);

      expect(restored.role, 'member');
      expect(restored.joinedAt, DateTime(2025, 6, 15));
    });
  });

  group('SpaceModel', () {
    test('creates with required fields', () {
      final space = SpaceModel(
        id: 'space1',
        name: 'Our Home',
        members: {
          'user1': SpaceMember(role: 'owner', joinedAt: DateTime(2025, 1, 1)),
        },
        inviteCode: 'ABC123',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(space.id, 'space1');
      expect(space.name, 'Our Home');
      expect(space.inviteCode, 'ABC123');
      expect(space.members.length, 1);
      expect(space.members['user1']?.role, 'owner');
      expect(space.themes, isEmpty);
    });

    test('creates with themes', () {
      final space = SpaceModel(
        id: 'space1',
        name: 'Our Home',
        members: {
          'user1': SpaceMember(role: 'owner', joinedAt: DateTime(2025, 1, 1)),
        },
        inviteCode: 'ABC123',
        themes: ['Home', 'Kids', 'Finances'],
        createdAt: DateTime(2025, 1, 1),
      );

      expect(space.themes, ['Home', 'Kids', 'Finances']);
    });

    test('toFirestore produces correct map', () {
      final space = SpaceModel(
        id: 'space1',
        name: 'Our Home',
        members: {
          'user1': SpaceMember(role: 'owner', joinedAt: DateTime(2025, 1, 1)),
        },
        inviteCode: 'ABC123',
        themes: ['Home'],
        createdAt: DateTime(2025, 1, 1),
      );

      final map = SpaceModel.toFirestore(space);

      expect(map['name'], 'Our Home');
      expect(map['inviteCode'], 'ABC123');
      expect(map['themes'], ['Home']);
      expect(map.containsKey('id'), isFalse); // id is the doc key
      expect((map['members'] as Map)['user1']['role'], 'owner');
    });

    test('copyWith works correctly', () {
      final space = SpaceModel(
        id: 'space1',
        name: 'Our Home',
        members: {
          'user1': SpaceMember(role: 'owner', joinedAt: DateTime(2025, 1, 1)),
        },
        inviteCode: 'ABC123',
        createdAt: DateTime(2025, 1, 1),
      );

      final updated = space.copyWith(name: 'Family HQ');
      expect(updated.name, 'Family HQ');
      expect(updated.id, 'space1'); // Unchanged fields preserved
      expect(updated.inviteCode, 'ABC123');
    });

    test('copyWith adds new member', () {
      final space = SpaceModel(
        id: 'space1',
        name: 'Our Home',
        members: {
          'user1': SpaceMember(role: 'owner', joinedAt: DateTime(2025, 1, 1)),
        },
        inviteCode: 'ABC123',
        createdAt: DateTime(2025, 1, 1),
      );

      final updated = space.copyWith(
        members: {
          ...space.members,
          'user2': SpaceMember(role: 'member', joinedAt: DateTime(2025, 2, 1)),
        },
      );

      expect(updated.members.length, 2);
      expect(updated.members['user2']?.role, 'member');
    });
  });
}
