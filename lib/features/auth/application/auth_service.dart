import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/session_controller.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

String messageForAuthFailure(ApiException error) {
  return switch (error.statusCode) {
    401 => 'Invalid email or password.',
    409 => 'An account with this email already exists.',
    503 => 'The bookmarks API is unreachable. Try again in a moment.',
    _ => error.message,
  };
}

/// Orchestrates the API calls and the session. The sign-in and register methods
/// return an error message to show, or null on success; navigation is not their
/// job because the router reacts to the session changing.
class AuthService {
  AuthService({
    required AuthRepository repository,
    required SessionController session,
  }) : _repository = repository,
       _session = session;

  final AuthRepository _repository;
  final SessionController _session;

  Future<String?> signIn(Credentials credentials) async {
    try {
      final token = await _repository.login(credentials);
      await _session.signIn(token);
      return null;
    } on ApiException catch (error) {
      return messageForAuthFailure(error);
    }
  }

  Future<String?> register(Registration registration) async {
    try {
      await _repository.register(registration);
      final token = await _repository.login(
        Credentials(
          email: registration.email,
          password: registration.password,
        ),
      );
      await _session.signIn(token);
      return null;
    } on ApiException catch (error) {
      return messageForAuthFailure(error);
    }
  }

  Future<void> signOut() => _session.signOut();
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    repository: ref.watch(authRepositoryProvider),
    session: ref.read(sessionControllerProvider.notifier),
  ),
);
