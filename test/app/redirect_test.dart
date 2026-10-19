import 'package:flutter_bookmarks_app/app/app_router.dart';
import 'package:flutter_bookmarks_app/app/app_routes.dart';
import 'package:flutter_bookmarks_app/core/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('while the session is being restored', () {
    const session = SessionRestoring();

    test('every page waits on the splash screen', () {
      expect(redirectFor(session, AppRoutes.bookmarks), AppRoutes.splash);
      expect(redirectFor(session, AppRoutes.login), AppRoutes.splash);
    });

    test('the splash screen stays put', () {
      expect(redirectFor(session, AppRoutes.splash), isNull);
    });
  });

  group('when signed out', () {
    const session = SignedOut();

    test('protected and splash pages lead to the login screen', () {
      expect(redirectFor(session, AppRoutes.bookmarks), AppRoutes.login);
      expect(redirectFor(session, AppRoutes.splash), AppRoutes.login);
    });

    test('the login and register screens stay put', () {
      expect(redirectFor(session, AppRoutes.login), isNull);
      expect(redirectFor(session, AppRoutes.register), isNull);
    });
  });

  group('when signed in', () {
    const session = SignedIn('token');

    test('guest pages and the splash screen lead to the list', () {
      expect(redirectFor(session, AppRoutes.login), AppRoutes.bookmarks);
      expect(redirectFor(session, AppRoutes.register), AppRoutes.bookmarks);
      expect(redirectFor(session, AppRoutes.splash), AppRoutes.bookmarks);
    });

    test('the list stays put', () {
      expect(redirectFor(session, AppRoutes.bookmarks), isNull);
    });
  });
}
