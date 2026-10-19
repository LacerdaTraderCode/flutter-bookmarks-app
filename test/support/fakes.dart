import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bookmarks_app/core/network/api_exception.dart';
import 'package:flutter_bookmarks_app/core/session/token_store.dart';
import 'package:flutter_bookmarks_app/features/auth/data/auth_repository.dart';
import 'package:flutter_bookmarks_app/features/auth/domain/auth_models.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/application/link_opener.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/data/bookmark_repository.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/domain/bookmark.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/domain/bookmark_filters.dart';

/// A JWT-shaped token. Only the `exp` claim matters to the app; the signature
/// is never checked on the device.
String fakeJwt({int? expiresAtSeconds}) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final claims = {'sub': 'user-1', 'exp': ?expiresAtSeconds};
  return '${encode({'alg': 'HS256'})}.${encode(claims)}.signature';
}

Bookmark sampleBookmark({
  String id = 'b1',
  String title = 'Next.js documentation',
  String url = 'https://nextjs.org/docs',
  List<String> tags = const ['nextjs', 'react'],
  String? notes,
  bool isRead = false,
  DateTime? savedAt,
}) {
  return Bookmark(
    id: id,
    url: url,
    title: title,
    tags: tags,
    notes: notes,
    isRead: isRead,
    savedAt: savedAt ?? DateTime.utc(2026, 10, 3, 12),
  );
}

class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

class FakeAuthRepository implements AuthRepository {
  String token = 'access-token';
  ApiException? loginFailure;
  ApiException? registerFailure;
  final List<Credentials> logins = [];
  final List<Registration> registrations = [];

  @override
  Future<String> login(Credentials credentials) async {
    logins.add(credentials);
    final failure = loginFailure;
    if (failure != null) throw failure;
    return token;
  }

  @override
  Future<void> register(Registration registration) async {
    registrations.add(registration);
    final failure = registerFailure;
    if (failure != null) throw failure;
  }
}

class FakeBookmarkRepository implements BookmarkRepository {
  FakeBookmarkRepository([List<Bookmark> initial = const []])
    : bookmarks = [...initial];

  List<Bookmark> bookmarks;

  /// When set, every call throws it.
  ApiException? failure;

  /// Replaces `list` entirely, for tests that control response timing.
  Future<List<Bookmark>> Function(BookmarkFilters filters)? listHandler;

  final List<BookmarkFilters> listCalls = [];
  final List<NewBookmark> created = [];
  final List<String> deletedIds = [];
  final Map<String, bool> readChanges = {};

  void _throwIfFailing() {
    final current = failure;
    if (current != null) throw current;
  }

  @override
  Future<List<Bookmark>> list(BookmarkFilters filters) async {
    listCalls.add(filters);
    final handler = listHandler;
    if (handler != null) return handler(filters);
    _throwIfFailing();

    return bookmarks.where((bookmark) {
      final tag = filters.tag;
      if (tag != null && !bookmark.tags.contains(tag)) return false;
      return switch (filters.readState) {
        ReadState.all => true,
        ReadState.read => bookmark.isRead,
        ReadState.unread => !bookmark.isRead,
      };
    }).toList();
  }

  @override
  Future<Bookmark> create(NewBookmark bookmark) async {
    _throwIfFailing();
    created.add(bookmark);
    final saved = Bookmark(
      id: 'created-${created.length}',
      url: bookmark.url,
      title: bookmark.title,
      tags: bookmark.tags,
      notes: bookmark.notes,
      isRead: false,
      savedAt: DateTime.utc(2026, 10, 18),
    );
    bookmarks = [saved, ...bookmarks];
    return saved;
  }

  @override
  Future<Bookmark> setRead(String bookmarkId, {required bool isRead}) async {
    _throwIfFailing();
    readChanges[bookmarkId] = isRead;
    final index = bookmarks.indexWhere((bookmark) => bookmark.id == bookmarkId);
    if (index == -1) throw const ApiException(404, 'Bookmark not found.');
    final current = bookmarks[index];
    final updated = Bookmark(
      id: current.id,
      url: current.url,
      title: current.title,
      tags: current.tags,
      notes: current.notes,
      isRead: isRead,
      savedAt: current.savedAt,
    );
    bookmarks = [...bookmarks]..[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String bookmarkId) async {
    _throwIfFailing();
    deletedIds.add(bookmarkId);
    final before = bookmarks.length;
    bookmarks = bookmarks.where((bookmark) => bookmark.id != bookmarkId).toList();
    if (bookmarks.length == before) {
      throw const ApiException(404, 'Bookmark not found.');
    }
  }
}

class FakeLinkOpener implements LinkOpener {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

/// Answers Dio requests from a function instead of the network.
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int statusCode, Object? payload) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
