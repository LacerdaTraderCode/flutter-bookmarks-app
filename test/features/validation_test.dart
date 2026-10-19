import 'package:flutter_bookmarks_app/features/auth/domain/auth_validation.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/domain/bookmark.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/domain/bookmark_validation.dart';
import 'package:flutter_test/flutter_test.dart';

NewBookmark _expectValid(Validated<NewBookmark> result) {
  expect(result, isA<Valid<NewBookmark>>());
  return (result as Valid<NewBookmark>).value;
}

String _expectInvalid(Validated<NewBookmark> result) {
  expect(result, isA<Invalid<NewBookmark>>());
  return (result as Invalid<NewBookmark>).message;
}

void main() {
  group('normalizeTags', () {
    test('lowercases, trims and drops empty entries', () {
      expect(normalizeTags(' TypeScript , ,React,'), ['typescript', 'react']);
    });

    test('removes duplicates while keeping first-seen order', () {
      expect(normalizeTags('api, Python, API, python'), ['api', 'python']);
    });

    test('returns an empty list for blank input', () {
      expect(normalizeTags('   '), isEmpty);
    });
  });

  group('parseNewBookmark', () {
    test('accepts a complete bookmark and normalizes it', () {
      final bookmark = _expectValid(
        parseNewBookmark(
          url: ' https://nextjs.org/docs ',
          title: '  Next.js docs ',
          tags: 'React, SSR',
          notes: '  caching chapter ',
        ),
      );

      expect(bookmark.url, 'https://nextjs.org/docs');
      expect(bookmark.title, 'Next.js docs');
      expect(bookmark.tags, ['react', 'ssr']);
      expect(bookmark.notes, 'caching chapter');
    });

    test('turns blank notes into null', () {
      final bookmark = _expectValid(
        parseNewBookmark(url: 'https://react.dev', title: 'React', notes: '  '),
      );
      expect(bookmark.notes, isNull);
    });

    test('rejects a value that is not a URL', () {
      final message = _expectInvalid(
        parseNewBookmark(url: 'not a url', title: 'x'),
      );
      expect(message, 'Enter a full URL, including https://.');
    });

    test('rejects a URL without a host', () {
      final message = _expectInvalid(parseNewBookmark(url: 'https://', title: 'x'));
      expect(message, 'Enter a full URL, including https://.');
    });

    test('rejects non-http schemes such as javascript:', () {
      final message = _expectInvalid(
        parseNewBookmark(url: 'javascript:alert(1)', title: 'x'),
      );
      expect(message, 'Only http and https links can be saved.');
    });

    test('requires a title', () {
      final message = _expectInvalid(
        parseNewBookmark(url: 'https://react.dev', title: '   '),
      );
      expect(message, 'Give the bookmark a title.');
    });

    test('limits the number of tags', () {
      final manyTags = List.generate(maxTagsPerBookmark + 1, (index) => 'tag$index').join(',');

      final message = _expectInvalid(
        parseNewBookmark(url: 'https://react.dev', title: 'React', tags: manyTags),
      );
      expect(message, 'Use at most $maxTagsPerBookmark tags per bookmark.');
    });

    test('limits the length of a single tag', () {
      final message = _expectInvalid(
        parseNewBookmark(
          url: 'https://react.dev',
          title: 'React',
          tags: 'x' * (maxTagLength + 1),
        ),
      );
      expect(message, 'Tags can have at most $maxTagLength characters.');
    });
  });

  group('auth validators', () {
    test('validateEmail accepts a normal address and trims it', () {
      expect(validateEmail('  demo@example.com '), isNull);
    });

    test('validateEmail rejects malformed addresses', () {
      expect(validateEmail('demo'), 'Enter a valid email address.');
      expect(validateEmail('demo@example'), 'Enter a valid email address.');
      expect(validateEmail(null), 'Enter a valid email address.');
    });

    test('validateLoginPassword only requires something to be typed', () {
      expect(validateLoginPassword('x'), isNull);
      expect(validateLoginPassword(''), 'Enter your password.');
      expect(validateLoginPassword(null), 'Enter your password.');
    });

    test('validateFullName requires a non-blank name', () {
      expect(validateFullName('Ada Lovelace'), isNull);
      expect(validateFullName('  '), 'Enter your name.');
    });

    test('validateNewPassword requires the minimum length', () {
      expect(validateNewPassword('analytical-engine'), isNull);
      expect(
        validateNewPassword('short'),
        'Use a password with at least $minimumPasswordLength characters.',
      );
    });
  });
}
