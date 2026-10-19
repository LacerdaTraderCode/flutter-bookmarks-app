import 'package:flutter_bookmarks_app/features/bookmarks/domain/bookmark.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/domain/bookmark_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bookmark.fromJson', () {
    final wire = {
      'id': 'b1',
      'url': 'https://nextjs.org/docs',
      'title': 'Next.js docs',
      'tags': ['react', 'ssr'],
      'notes': 'read the caching chapter',
      'is_read': true,
      'saved_at': '2026-10-03T12:00:00+00:00',
    };

    test('maps the snake_case wire fields', () {
      final bookmark = Bookmark.fromJson(wire);

      expect(bookmark.id, 'b1');
      expect(bookmark.url, 'https://nextjs.org/docs');
      expect(bookmark.title, 'Next.js docs');
      expect(bookmark.tags, ['react', 'ssr']);
      expect(bookmark.notes, 'read the caching chapter');
      expect(bookmark.isRead, isTrue);
      expect(bookmark.savedAt, DateTime.utc(2026, 10, 3, 12));
    });

    test('keeps missing notes as null', () {
      final bookmark = Bookmark.fromJson({...wire, 'notes': null});
      expect(bookmark.notes, isNull);
    });

    test('keeps an unparseable timestamp as null instead of failing', () {
      final bookmark = Bookmark.fromJson({...wire, 'saved_at': 'yesterday'});
      expect(bookmark.savedAt, isNull);
    });
  });

  group('NewBookmark.toJson', () {
    test('uses the API field names', () {
      const bookmark = NewBookmark(
        url: 'https://react.dev/',
        title: 'React',
        tags: ['react'],
        notes: 'hooks',
      );

      expect(bookmark.toJson(), {
        'url': 'https://react.dev/',
        'title': 'React',
        'tags': ['react'],
        'notes': 'hooks',
      });
    });
  });

  group('BookmarkFilters', () {
    test('has no query and is inactive by default', () {
      const filters = BookmarkFilters();

      expect(filters.toQuery(), isEmpty);
      expect(filters.isActive, isFalse);
    });

    test('maps the read state to the API is_read flag', () {
      expect(
        const BookmarkFilters(readState: ReadState.read).toQuery(),
        {'is_read': 'true'},
      );
      expect(
        const BookmarkFilters(readState: ReadState.unread).toQuery(),
        {'is_read': 'false'},
      );
    });

    test('combines the tag and the read state', () {
      const filters = BookmarkFilters(tag: 'api', readState: ReadState.unread);

      expect(filters.toQuery(), {'tag': 'api', 'is_read': 'false'});
      expect(filters.isActive, isTrue);
    });

    test('normalizes a typed tag and treats a blank one as no filter', () {
      expect(BookmarkFilters.normalizeTag('  TypeScript '), 'typescript');
      expect(BookmarkFilters.normalizeTag('   '), isNull);
    });

    test('changing one filter keeps the other', () {
      const filters = BookmarkFilters(tag: 'api', readState: ReadState.read);

      expect(filters.withTag('python').readState, ReadState.read);
      expect(filters.withReadState(ReadState.all).tag, 'api');
    });

    test('compares by value', () {
      expect(
        const BookmarkFilters(tag: 'api', readState: ReadState.read),
        const BookmarkFilters(tag: 'api', readState: ReadState.read),
      );
      expect(
        const BookmarkFilters(tag: 'api'),
        isNot(const BookmarkFilters(tag: 'python')),
      );
    });
  });
}
