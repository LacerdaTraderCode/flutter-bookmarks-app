import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../session/session_controller.dart';
import 'api_client.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
    ),
  );
});

// The token and the rejection handler are read lazily, at request time, so the
// client does not depend on the session being ready when it is created.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    dio: ref.watch(dioProvider),
    readToken: () => ref.read(sessionControllerProvider).token,
    onSessionRejected: () =>
        ref.read(sessionControllerProvider.notifier).expire(),
  );
});
