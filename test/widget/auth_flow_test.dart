import 'package:flutter/material.dart';
import 'package:flutter_bookmarks_app/core/network/api_exception.dart';
import 'package:flutter_bookmarks_app/core/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_environment.dart';

Future<void> signInWith(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byKey(const Key('email-field')), email);
  await tester.enterText(find.byKey(const Key('password-field')), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the sign-in screen when no session is stored', (tester) async {
    final environment = TestEnvironment();

    await tester.pumpWidget(environment.app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email-field')), findsOneWidget);
    expect(find.byKey(const Key('password-field')), findsOneWidget);
    expect(find.text('Reading list'), findsNothing);
  });

  testWidgets('goes straight to the list when a session is stored', (tester) async {
    final environment = TestEnvironment(storedToken: 'stored-token');

    await tester.pumpWidget(environment.app());
    await tester.pumpAndSettle();

    expect(find.text('Reading list'), findsOneWidget);
    expect(find.text('Next.js documentation'), findsOneWidget);
    expect(find.byKey(const Key('email-field')), findsNothing);
  });

  testWidgets('rejects a malformed email without calling the API', (tester) async {
    final environment = TestEnvironment();
    await tester.pumpWidget(environment.app());
    await tester.pumpAndSettle();

    await signInWith(tester, 'not-an-email', 'whatever');

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(environment.authRepository.logins, isEmpty);
  });

  testWidgets('signs in and shows the list', (tester) async {
    final environment = TestEnvironment();
    await tester.pumpWidget(environment.app());
    await tester.pumpAndSettle();

    await signInWith(tester, 'Demo@Example.com', 'correct-horse');

    expect(environment.authRepository.logins.single.email, 'demo@example.com');
    expect(environment.tokenStore.token, environment.authRepository.token);
    expect(find.text('Reading list'), findsOneWidget);
    expect(find.text('TypeScript handbook'), findsOneWidget);
  });

  testWidgets('shows the API message for a wrong password', (tester) async {
    final environment = TestEnvironment();
    environment.authRepository.loginFailure = const ApiException(
      401,
      'Invalid email or password.',
    );
    await tester.pumpWidget(environment.app());
    await tester.pumpAndSettle();

    await signInWith(tester, 'demo@example.com', 'wrong');

    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(find.text('Reading list'), findsNothing);
    expect(environment.tokenStore.token, isNull);
  });

  testWidgets('registers a new account and lands on the list', (tester) async {
    final environment = TestEnvironment();
    await tester.pumpWidget(environment.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name-field')), 'Ada Lovelace');
    await tester.enterText(find.byKey(const Key('email-field')), 'ada@example.com');
    await tester.enterText(find.byKey(const Key('password-field')), 'analytical-engine');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(environment.authRepository.registrations.single.fullName, 'Ada Lovelace');
    expect(find.text('Reading list'), findsOneWidget);
  });

  testWidgets('a short password is refused on the registration screen', (tester) async {
    final environment = TestEnvironment();
    await tester.pumpWidget(environment.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('name-field')), 'Ada');
    await tester.enterText(find.byKey(const Key('email-field')), 'ada@example.com');
    await tester.enterText(find.byKey(const Key('password-field')), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.textContaining('at least 8 characters'), findsOneWidget);
    expect(environment.authRepository.registrations, isEmpty);
  });

  testWidgets('signing out returns to the sign-in screen and clears the token', (tester) async {
    final environment = TestEnvironment(storedToken: 'stored-token');
    await tester.pumpWidget(environment.app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email-field')), findsOneWidget);
    expect(find.text('Your session expired. Sign in again to continue.'), findsNothing);
    expect(environment.tokenStore.token, isNull);
  });

  testWidgets('a rejected session returns to sign-in and explains why', (tester) async {
    final environment = TestEnvironment(storedToken: 'stored-token');
    await tester.pumpWidget(environment.app());
    await tester.pumpAndSettle();
    expect(find.text('Reading list'), findsOneWidget);

    environment.appContainer(tester).read(sessionControllerProvider.notifier).expire();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email-field')), findsOneWidget);
    expect(find.text('Your session expired. Sign in again to continue.'), findsOneWidget);
    expect(find.text('Next.js documentation'), findsNothing);
  });
}
