import 'package:flutter_bookmarks_app/features/bookmarks/domain/bookmark_formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatSavedDate', () {
    test('formats a timestamp as a short UTC date', () {
      expect(formatSavedDate(DateTime.utc(2026, 10, 3, 12)), '3 Oct 2026');
    });

    test('does not shift the day for a late-evening UTC timestamp', () {
      expect(formatSavedDate(DateTime.utc(2026, 10, 3, 23, 59)), '3 Oct 2026');
    });

    test('converts a local timestamp to UTC first', () {
      final local = DateTime.utc(2026, 1, 31, 23).toLocal();
      expect(formatSavedDate(local), '31 Jan 2026');
    });

    test('returns a placeholder when there is no date', () {
      expect(formatSavedDate(null), 'unknown date');
    });
  });

  group('hostnameOf', () {
    test('drops the www prefix', () {
      expect(hostnameOf('https://www.typescriptlang.org/docs/'), 'typescriptlang.org');
    });

    test('keeps other subdomains', () {
      expect(hostnameOf('https://docs.flutter.dev/get-started'), 'docs.flutter.dev');
    });

    test('returns the input when it is not a URL', () {
      expect(hostnameOf('not a url'), 'not a url');
    });
  });

  group('safeExternalUri', () {
    test('passes http and https links', () {
      expect(safeExternalUri('https://vitest.dev/guide/'), Uri.parse('https://vitest.dev/guide/'));
      expect(safeExternalUri('http://example.com'), Uri.parse('http://example.com'));
    });

    test('blocks javascript:, data: and file: links', () {
      expect(safeExternalUri('javascript:alert(1)'), isNull);
      expect(safeExternalUri('data:text/html,<script>1</script>'), isNull);
      expect(safeExternalUri('file:///etc/passwd'), isNull);
    });

    test('blocks values that are not absolute URLs', () {
      expect(safeExternalUri('/relative/path'), isNull);
      expect(safeExternalUri('https://'), isNull);
    });
  });
}
