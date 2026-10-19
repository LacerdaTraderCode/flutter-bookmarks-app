import 'package:flutter_bookmarks_app/core/network/api_exception.dart';
import 'package:flutter_bookmarks_app/core/session/session_controller.dart';
import 'package:flutter_bookmarks_app/features/auth/application/auth_service.dart';
import 'package:flutter_bookmarks_app/features/auth/domain/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_environment.dart';

void main() {
  late TestEnvironment environment;
  late ProviderContainer container;
  late AuthService service;

  setUp(() async {
    environment = TestEnvironment();
    container = environment.container();
    container.read(sessionControllerProvider);
    await settle();
    service = AuthService(
      repository: environment.authRepository,
      session: container.read(sessionControllerProvider.notifier),
    );
  });

  const credentials = Credentials(email: 'demo@example.com', password: 'correct-horse');
  const registration = Registration(
    fullName: 'Ada Lovelace',
    email: 'ada@example.com',
    password: 'analytical-engine',
  );

  group('signIn', () {
    test('stores the token and signs in', () async {
      environment.authRepository.token = 'issued-token';

      final error = await service.signIn(credentials);

      expect(error, isNull);
      expect(
        container.read(sessionControllerProvider),
        isA<SignedIn>().having((state) => state.token, 'token', 'issued-token'),
      );
      expect(environment.tokenStore.token, 'issued-token');
    });

    test('explains a wrong password and stays signed out', () async {
      environment.authRepository.loginFailure = const ApiException(
        401,
        'Invalid email or password.',
      );

      final error = await service.signIn(credentials);

      expect(error, 'Invalid email or password.');
      expect(container.read(sessionControllerProvider), isA<SignedOut>());
      expect(environment.tokenStore.token, isNull);
    });

    test('explains an unreachable API', () async {
      environment.authRepository.loginFailure = const ApiException.unreachable();

      final error = await service.signIn(credentials);

      expect(error, 'The bookmarks API is unreachable. Try again in a moment.');
    });
  });

  group('register', () {
    test('creates the account and then signs in with the same credentials', () async {
      final error = await service.register(registration);

      expect(error, isNull);
      expect(environment.authRepository.registrations.single.email, 'ada@example.com');
      expect(environment.authRepository.logins.single.email, 'ada@example.com');
      expect(environment.authRepository.logins.single.password, 'analytical-engine');
      expect(container.read(sessionControllerProvider), isA<SignedIn>());
    });

    test('explains a duplicate account and does not sign in', () async {
      environment.authRepository.registerFailure = const ApiException(
        409,
        'An account with this email already exists.',
      );

      final error = await service.register(registration);

      expect(error, 'An account with this email already exists.');
      expect(environment.authRepository.logins, isEmpty);
      expect(container.read(sessionControllerProvider), isA<SignedOut>());
    });
  });

  test('signOut clears the session', () async {
    await service.signIn(credentials);

    await service.signOut();

    expect(container.read(sessionControllerProvider), isA<SignedOut>());
    expect(environment.tokenStore.token, isNull);
  });

  group('messageForAuthFailure', () {
    test('keeps the API message for other statuses', () {
      expect(
        messageForAuthFailure(const ApiException(422, 'The API rejected the submitted data.')),
        'The API rejected the submitted data.',
      );
    });
  });
}
