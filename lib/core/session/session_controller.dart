import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_expiry.dart';
import 'token_store.dart';

sealed class SessionState {
  const SessionState();

  String? get token => null;
}

/// The stored token is still being read from secure storage.
final class SessionRestoring extends SessionState {
  const SessionRestoring();
}

final class SignedOut extends SessionState {
  const SignedOut({this.expired = false});

  /// True when the person was signed out because the token ran out or was
  /// rejected, so the login screen can say why.
  final bool expired;
}

final class SignedIn extends SessionState {
  const SignedIn(this.token);

  @override
  final String token;
}

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

class SessionController extends Notifier<SessionState> {
  bool _disposed = false;

  TokenStore get _store => ref.read(tokenStoreProvider);

  @override
  SessionState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_restore());
    return const SessionRestoring();
  }

  Future<void> _restore() async {
    final storedToken = await _store.read();
    if (_disposed) return;

    if (storedToken == null) {
      state = const SignedOut();
      return;
    }
    if (isTokenExpired(storedToken, DateTime.now())) {
      await _store.clear();
      if (_disposed) return;
      state = const SignedOut(expired: true);
      return;
    }
    state = SignedIn(storedToken);
  }

  Future<void> signIn(String token) async {
    await _store.write(token);
    state = SignedIn(token);
  }

  Future<void> signOut() async {
    await _store.clear();
    state = const SignedOut();
  }

  /// Called when the API rejects the token of an authenticated request.
  void expire() {
    // A late 401 after a manual sign-out must not show an expiry notice.
    if (state is! SignedIn) return;
    unawaited(_store.clear());
    state = const SignedOut(expired: true);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
