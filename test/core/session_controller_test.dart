import 'package:flutter_bookmarks_app/core/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_environment.dart';

void main() {
  group('restoring the session', () {
    test('starts in the restoring state', () {
      final container = TestEnvironment().container();

      expect(container.read(sessionControllerProvider), isA<SessionRestoring>());
    });

    test('is signed out when nothing is stored', () async {
      final container = TestEnvironment().container();
      container.read(sessionControllerProvider);

      await settle();

      final session = container.read(sessionControllerProvider);
      expect(session, isA<SignedOut>().having((state) => state.expired, 'expired', isFalse));
    });

    test('is signed in when a usable token is stored', () async {
      final environment = TestEnvironment(storedToken: fakeJwt());
      final container = environment.container();
      container.read(sessionControllerProvider);

      await settle();

      expect(
        container.read(sessionControllerProvider),
        isA<SignedIn>().having((state) => state.token, 'token', environment.tokenStore.token),
      );
    });

    test('drops a stored token that already expired and says so', () async {
      final expiredToken = fakeJwt(
        expiresAtSeconds: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60,
      );
      final environment = TestEnvironment(storedToken: expiredToken);
      final container = environment.container();
      container.read(sessionControllerProvider);

      await settle();

      expect(
        container.read(sessionControllerProvider),
        isA<SignedOut>().having((state) => state.expired, 'expired', isTrue),
      );
      expect(environment.tokenStore.token, isNull);
    });
  });

  group('changing the session', () {
    test('signIn keeps the token and signs in', () async {
      final environment = TestEnvironment();
      final container = environment.container();
      container.read(sessionControllerProvider);
      await settle();

      await container.read(sessionControllerProvider.notifier).signIn('fresh-token');

      expect(
        container.read(sessionControllerProvider),
        isA<SignedIn>().having((state) => state.token, 'token', 'fresh-token'),
      );
      expect(environment.tokenStore.token, 'fresh-token');
    });

    test('signOut clears the token', () async {
      final environment = TestEnvironment(storedToken: 'stored-token');
      final container = environment.container();
      container.read(sessionControllerProvider);
      await settle();

      await container.read(sessionControllerProvider.notifier).signOut();

      expect(
        container.read(sessionControllerProvider),
        isA<SignedOut>().having((state) => state.expired, 'expired', isFalse),
      );
      expect(environment.tokenStore.token, isNull);
    });

    test('expire signs out with an explanation and clears the token', () async {
      final environment = TestEnvironment(storedToken: 'stored-token');
      final container = environment.container();
      container.read(sessionControllerProvider);
      await settle();

      container.read(sessionControllerProvider.notifier).expire();
      await settle();

      expect(
        container.read(sessionControllerProvider),
        isA<SignedOut>().having((state) => state.expired, 'expired', isTrue),
      );
      expect(environment.tokenStore.token, isNull);
    });

    test('a late expire after a manual sign-out shows no notice', () async {
      final container = TestEnvironment(storedToken: 'stored-token').container();
      container.read(sessionControllerProvider);
      await settle();
      final notifier = container.read(sessionControllerProvider.notifier);
      await notifier.signOut();

      notifier.expire();

      expect(
        container.read(sessionControllerProvider),
        isA<SignedOut>().having((state) => state.expired, 'expired', isFalse),
      );
    });
  });
}
