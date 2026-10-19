import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../domain/bookmark.dart';
import '../domain/bookmark_filters.dart';

abstract interface class BookmarkRepository {
  Future<List<Bookmark>> list(BookmarkFilters filters);

  Future<Bookmark> create(NewBookmark bookmark);

  Future<Bookmark> setRead(String bookmarkId, {required bool isRead});

  Future<void> delete(String bookmarkId);
}

class ApiBookmarkRepository implements BookmarkRepository {
  ApiBookmarkRepository(this._api);

  final ApiClient _api;

  String _pathFor(String bookmarkId) =>
      '/bookmarks/${Uri.encodeComponent(bookmarkId)}';

  @override
  Future<List<Bookmark>> list(BookmarkFilters filters) async {
    final items =
        await _api.get('/bookmarks', query: filters.toQuery())
            as List<dynamic>;
    return [
      for (final item in items) Bookmark.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<Bookmark> create(NewBookmark bookmark) async {
    final body =
        await _api.post('/bookmarks', body: bookmark.toJson())
            as Map<String, dynamic>;
    return Bookmark.fromJson(body);
  }

  @override
  Future<Bookmark> setRead(String bookmarkId, {required bool isRead}) async {
    final body =
        await _api.patch(_pathFor(bookmarkId), body: {'is_read': isRead})
            as Map<String, dynamic>;
    return Bookmark.fromJson(body);
  }

  @override
  Future<void> delete(String bookmarkId) => _api.delete(_pathFor(bookmarkId));
}

final bookmarkRepositoryProvider = Provider<BookmarkRepository>(
  (ref) => ApiBookmarkRepository(ref.watch(apiClientProvider)),
);
