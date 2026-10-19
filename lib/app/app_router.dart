import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/bookmarks/presentation/bookmarks_screen.dart';
import 'app_routes.dart';
import 'splash_screen.dart';

/// Decides where the current session allows the person to be. Returns the path
/// to redirect to, or null to stay on [location].
String? redirectFor(SessionState session, String location) {
  final onGuestPage =
      location == AppRoutes.login || location == AppRoutes.register;

  return switch (session) {
    SessionRestoring() => location == AppRoutes.splash ? null : AppRoutes.splash,
    SignedOut() => onGuestPage ? null : AppRoutes.login,
    SignedIn() =>
      (onGuestPage || location == AppRoutes.splash)
          ? AppRoutes.bookmarks
          : null,
  };
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // go_router re-evaluates `redirect` whenever this notifier fires.
  final sessionChanges = ValueNotifier<int>(0);
  ref.listen(
    sessionControllerProvider,
    (previous, next) => sessionChanges.value++,
  );

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: sessionChanges,
    redirect: (context, state) => redirectFor(
      ref.read(sessionControllerProvider),
      state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookmarks,
        builder: (context, state) => const BookmarksScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    sessionChanges.dispose();
  });
  return router;
});
