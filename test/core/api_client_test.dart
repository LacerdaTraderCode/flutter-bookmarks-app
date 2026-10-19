import 'package:dio/dio.dart';
import 'package:flutter_bookmarks_app/core/network/api_client.dart';
import 'package:flutter_bookmarks_app/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late int rejectedCount;
  late String? token;

  ApiClient buildClient() {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api'));
    dio.httpClientAdapter = adapter;
    return ApiClient(
      dio: dio,
      readToken: () => token,
      onSessionRejected: () => rejectedCount++,
    );
  }

  setUp(() {
    rejectedCount = 0;
    token = 'token-1';
    adapter = FakeHttpClientAdapter((options) => jsonResponse(200, <String>[]));
  });

  group('requests', () {
    test('attaches the bearer token and the query to an authenticated call', () async {
      final client = buildClient();

      await client.get('/bookmarks', query: {'tag': 'react', 'is_read': 'true'});

      final request = adapter.requests.single;
      expect(
        request.uri.toString(),
        'http://api.test/api/bookmarks?tag=react&is_read=true',
      );
      expect(request.headers['Authorization'], 'Bearer token-1');
      expect(request.method, 'GET');
    });

    test('leaves the token out when the call is not authenticated', () async {
      adapter = FakeHttpClientAdapter(
        (options) => jsonResponse(200, {'access_token': 'jwt'}),
      );
      final client = buildClient();

      await client.post('/auth/login', body: {'email': 'a@b.co'}, authenticated: false);

      expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('sends the JSON body of a patch', () async {
      adapter = FakeHttpClientAdapter(
        (options) => jsonResponse(200, {'id': 'b1'}),
      );
      final client = buildClient();

      await client.patch('/bookmarks/b1', body: {'is_read': false});

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.data, {'is_read': false});
    });

    test('returns the decoded JSON body of a successful call', () async {
      adapter = FakeHttpClientAdapter(
        (options) => jsonResponse(200, [
          {'id': 'b1'},
        ]),
      );

      final body = await buildClient().get('/bookmarks');

      expect(body, [
        {'id': 'b1'},
      ]);
    });

    test('treats 204 on delete as success', () async {
      adapter = FakeHttpClientAdapter((options) => ResponseBody.fromString('', 204));

      await buildClient().delete('/bookmarks/b1');

      expect(adapter.requests.single.method, 'DELETE');
    });
  });

  group('failures', () {
    test('exposes the status and the detail string of a handled error', () async {
      adapter = FakeHttpClientAdapter(
        (options) => jsonResponse(404, {'detail': 'Bookmark not found.'}),
      );

      await expectLater(
        buildClient().get('/bookmarks/gone'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 404)
              .having((error) => error.message, 'message', 'Bookmark not found.')
              .having((error) => error.isNotFound, 'isNotFound', isTrue),
        ),
      );
    });

    test('summarizes a 422 validation list instead of leaking its structure', () async {
      adapter = FakeHttpClientAdapter(
        (options) => jsonResponse(422, {
          'detail': [
            {'loc': ['body', 'url'], 'msg': 'Field required'},
          ],
        }),
      );

      await expectLater(
        buildClient().post('/bookmarks', body: <String, Object>{}),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'The API rejected the submitted data.',
          ),
        ),
      );
    });

    test('falls back to a status message when the body is not JSON', () async {
      adapter = FakeHttpClientAdapter(
        (options) => ResponseBody.fromString('<html>Bad gateway</html>', 502),
      );

      await expectLater(
        buildClient().get('/bookmarks'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 502)
              .having(
                (error) => error.message,
                'message',
                'The API answered with status 502.',
              ),
        ),
      );
    });

    test('reports a network failure as an unreachable API', () async {
      adapter = FakeHttpClientAdapter(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        buildClient().get('/bookmarks'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 503)
              .having(
                (error) => error.message,
                'message',
                'The bookmarks API is unreachable.',
              ),
        ),
      );
    });
  });

  group('session rejection', () {
    test('a 401 on an authenticated call notifies the handler once', () async {
      adapter = FakeHttpClientAdapter(
        (options) => jsonResponse(401, {'detail': 'Unauthorized'}),
      );

      await expectLater(
        buildClient().get('/bookmarks'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.sessionExpired,
            'sessionExpired',
            isTrue,
          ),
        ),
      );
      expect(rejectedCount, 1);
    });

    test('a 401 on login is a wrong password, not an expired session', () async {
      adapter = FakeHttpClientAdapter(
        (options) => jsonResponse(401, {'detail': 'Invalid email or password.'}),
      );

      await expectLater(
        buildClient().post('/auth/login', body: {'email': 'a@b.co'}, authenticated: false),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having((error) => error.sessionExpired, 'sessionExpired', isFalse),
        ),
      );
      expect(rejectedCount, 0);
    });

    test('a 401 without a stored token is not treated as an expired session', () async {
      token = null;
      adapter = FakeHttpClientAdapter(
        (options) => jsonResponse(401, {'detail': 'Unauthorized'}),
      );

      await expectLater(buildClient().get('/bookmarks'), throwsA(isA<ApiException>()));
      expect(rejectedCount, 0);
    });
  });
}
