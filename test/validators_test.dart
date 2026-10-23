import 'package:flutter_test/flutter_test.dart';
import 'package:loqta/core/utils/validators.dart';

void main() {
  group('AppValidators', () {
    test('email accepts a valid address', () {
      expect(AppValidators.email('user@example.com'), isNull);
    });

    test('email rejects empty and malformed values', () {
      expect(AppValidators.email(null), isNotNull);
      expect(AppValidators.email(''), isNotNull);
      expect(AppValidators.email('not-an-email'), isNotNull);
      expect(AppValidators.email('missing@tld'), isNotNull);
    });

    test('password enforces the 8-character minimum from the design', () {
      expect(AppValidators.password(null), isNotNull);
      expect(AppValidators.password('1234567'), isNotNull);
      expect(AppValidators.password('12345678'), isNull);
      expect(AppValidators.passwordMinLength, 8);
    });

    test('sign-in password only needs to be present', () {
      // Accounts created before the 8-character rule must still be able to
      // sign in, so the sign-in field does not apply the length rule.
      expect(AppValidators.passwordRequired(null), isNotNull);
      expect(AppValidators.passwordRequired(''), isNotNull);
      expect(AppValidators.passwordRequired('123456'), isNull);
    });

    test('confirmPassword requires a match', () {
      expect(AppValidators.confirmPassword('abc123', 'abc123'), isNull);
      expect(AppValidators.confirmPassword('abc123', 'abc456'), isNotNull);
      expect(AppValidators.confirmPassword(null, 'abc123'), isNotNull);
    });

    test('name requires at least two characters', () {
      expect(AppValidators.name(null, 'First name'), isNotNull);
      expect(AppValidators.name('A', 'First name'), isNotNull);
      expect(AppValidators.name('Sara', 'First name'), isNull);
    });

    test('otpCode requires exactly six digits', () {
      expect(AppValidators.otpCode('123456'), isNull);
      expect(AppValidators.otpCode('12345'), isNotNull);
      expect(AppValidators.otpCode('abcdef'), isNotNull);
      expect(AppValidators.otpCode(null), isNotNull);
    });
  });
}
