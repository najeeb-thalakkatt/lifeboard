import 'package:flutter_test/flutter_test.dart';
import 'package:lifeboard/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('creates with required fields', () {
      final user = UserModel(
        id: 'uid1',
        displayName: 'Alice',
        email: 'alice@example.com',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(user.id, 'uid1');
      expect(user.displayName, 'Alice');
      expect(user.email, 'alice@example.com');
      expect(user.spaceIds, isEmpty);
      expect(user.notificationPrefs.pushEnabled, isTrue);
      expect(user.notificationPrefs.emailEnabled, isTrue);
      expect(user.photoUrl, isNull);
      expect(user.moodEmoji, isNull);
    });

    test('toFirestore produces correct map', () {
      final user = UserModel(
        id: 'uid1',
        displayName: 'Alice',
        email: 'alice@example.com',
        spaceIds: ['space1'],
        createdAt: DateTime(2025, 1, 1),
      );

      final map = UserModel.toFirestore(user);

      expect(map['displayName'], 'Alice');
      expect(map['email'], 'alice@example.com');
      expect(map['spaceIds'], ['space1']);
      expect(map['notificationPrefs']['pushEnabled'], isTrue);
      expect(map.containsKey('id'), isFalse); // id is the doc key, not a field
    });

    test('copyWith works correctly', () {
      final user = UserModel(
        id: 'uid1',
        displayName: 'Alice',
        email: 'alice@example.com',
        createdAt: DateTime(2025, 1, 1),
      );

      final updated = user.copyWith(displayName: 'Bob');
      expect(updated.displayName, 'Bob');
      expect(updated.id, 'uid1'); // Unchanged fields preserved
    });
  });

  group('NotificationPrefs', () {
    test('defaults to enabled', () {
      const prefs = NotificationPrefs();
      expect(prefs.pushEnabled, isTrue);
      expect(prefs.emailEnabled, isTrue);
    });

    test('serializes to/from JSON', () {
      const prefs = NotificationPrefs(pushEnabled: false, emailEnabled: true);
      final json = prefs.toJson();
      final restored = NotificationPrefs.fromJson(json);
      expect(restored.pushEnabled, isFalse);
      expect(restored.emailEnabled, isTrue);
    });
  });
}
