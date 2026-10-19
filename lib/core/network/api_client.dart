import 'package:dio/dio.dart';

import 'api_exception.dart';

typedef TokenReader = String? Function();

/// Thin wrapper over Dio that knows the API's error format and attaches the
/// bearer token. It never throws a DioException: every failure becomes an
/// [ApiException].
class ApiClient {
  ApiClient({
    required Dio dio,
    required TokenReader readToken,
    required void Function() onSessionRejected,
  }) : _dio = dio,
       _readToken = readToken,
       _onSessionRejected = onSessionRejected;

  final Dio _dio;
  final TokenReader _readToken;
  final void Function() _onSessionRejected;

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) => _send('GET', path, query: query, authenticated: authenticated);

  Future<dynamic> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('POST', path, body: body, authenticated: authenticated);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body, authenticated: true);

  Future<void> delete(String path) async {
    await _send('DELETE', path, authenticated: true);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    required bool authenticated,
    Map<String, String>? query,
    Object? body,
  }) async {
    final token = authenticated ? _readToken() : null;

    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          // Non-2xx answers are handled below so the API's `detail` is kept.
          validateStatus: (_) => true,
        ),
      );
    } on DioException {
      throw const ApiException.unreachable();
    }

    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return response.data;

    final sessionExpired = status == 401 && token != null;
    if (sessionExpired) _onSessionRejected();
    throw ApiException(
      status,
      _describeFailure(response.data, status),
      sessionExpired: sessionExpired,
    );
  }

  // Django Ninja answers {"detail": "..."} for handled errors and
  // {"detail": [...]} for 422 validation errors.
  String _describeFailure(dynamic payload, int status) {
    if (payload is Map<String, dynamic>) {
      final detail = payload['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        return 'The API rejected the submitted data.';
      }
    }
    return 'The API answered with status $status.';
  }
}
