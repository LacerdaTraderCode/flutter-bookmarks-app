import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../domain/auth_models.dart';

abstract interface class AuthRepository {
  Future<String> login(Credentials credentials);

  Future<void> register(Registration registration);
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<String> login(Credentials credentials) async {
    final body =
        await _api.post(
              '/auth/login',
              body: {
                'email': credentials.email,
                'password': credentials.password,
              },
              authenticated: false,
            )
            as Map<String, dynamic>;
    return body['access_token'] as String;
  }

  @override
  Future<void> register(Registration registration) async {
    await _api.post(
      '/auth/register',
      body: {
        'email': registration.email,
        'password': registration.password,
        'full_name': registration.fullName,
      },
      authenticated: false,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(ref.watch(apiClientProvider)),
);
