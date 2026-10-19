import 'package:flutter_bookmarks_app/core/session/token_expiry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  final now = DateTime.utc(2026, 10, 18, 12);
  final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;

  group('isTokenExpired', () {
    test('is false while the exp claim is in the future', () {
      final token = fakeJwt(expiresAtSeconds: nowSeconds + 1800);
      expect(isTokenExpired(token, now), isFalse);
    });

    test('is true once the exp claim has passed', () {
      final token = fakeJwt(expiresAtSeconds: nowSeconds - 60);
      expect(isTokenExpired(token, now), isTrue);
    });

    test('is true at the exact expiry second', () {
      final token = fakeJwt(expiresAtSeconds: nowSeconds);
      expect(isTokenExpired(token, now), isTrue);
    });

    test('is false when the token has no exp claim', () {
      expect(isTokenExpired(fakeJwt(), now), isFalse);
    });

    test('is false for a token that is not a JWT', () {
      expect(isTokenExpired('opaque-token', now), isFalse);
    });

    test('is false when the payload is not valid base64 JSON', () {
      expect(isTokenExpired('a.%%%.c', now), isFalse);
    });
  });
}
