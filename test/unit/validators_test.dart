import 'package:flutter_test/flutter_test.dart';
import 'package:lifeboard/core/utils/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns error for null', () {
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('returns error for invalid email', () {
      expect(Validators.validateEmail('notanemail'), isNotNull);
      expect(Validators.validateEmail('missing@tld'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(Validators.validateEmail('a.b+c@d.co'), isNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns error for null', () {
      expect(Validators.validatePassword(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('returns error for short password', () {
      expect(Validators.validatePassword('1234567'), isNotNull);
    });

    test('returns null for valid password', () {
      expect(Validators.validatePassword('12345678'), isNull);
      expect(Validators.validatePassword('a-strong-passw0rd!'), isNull);
    });
  });

  group('Validators.validateDisplayName', () {
    test('returns error for null', () {
      expect(Validators.validateDisplayName(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.validateDisplayName(''), isNotNull);
    });

    test('returns error for whitespace only', () {
      expect(Validators.validateDisplayName('   '), isNotNull);
    });

    test('returns null for valid name', () {
      expect(Validators.validateDisplayName('Alice'), isNull);
    });
  });
}
