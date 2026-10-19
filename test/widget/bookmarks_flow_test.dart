import 'package:flutter/material.dart';
import 'package:flutter_bookmarks_app/core/network/api_exception.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/domain/bookmark_filters.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_environment.dart';

Future<TestEnvironment> openList(
  WidgetTester tester, {
  TestEnvironment? environment,
}) async {
  final env = environment ?? TestEnvironment(storedToken: 'stored-token');
  await tester.pumpWidget(env.app());
  await tester.pumpAndSettle();
  return env;
}

void main() {
  testWidgets('lists the bookmarks with their host, notes, tags and state', (tester) async {
    await openList(tester);

    expect(find.text('Next.js documentation'), findsOneWidget);
    expect(find.text('nextjs.org'), findsOneWidget);
    expect(find.text('typescriptlang.org'), findsOneWidget);
    expect(find.text('Chapter on narrowing.'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'typescript'), findsOneWidget);
    expect(find.textContaining('Saved 3 Oct 2026 · Unread'), findsOneWidget);
    expect(find.textContaining('Saved 3 Oct 2026 · Read'), findsOneWidget);
  });

  testWidgets('shows a friendly message when nothing is saved yet', (tester) async {
    await openList(tester, environment: TestEnvironment(storedToken: 'stored-token', bookmarks: []));

    expect(find.textContaining('Nothing saved yet'), findsOneWidget);
  });

  testWidgets('shows the error and a retry button when the API is unreachable', (tester) async {
    final environment = TestEnvironment(storedToken: 'stored-token');
    environment.bookmarkRepository.failure = const ApiException.unreachable();
    await openList(tester, environment: environment);

    expect(find.text('The bookmarks API is unreachable.'), findsOneWidget);
    expect(find.textContaining('Nothing saved yet'), findsNothing);

    environment.bookmarkRepository.failure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('The bookmarks API is unreachable.'), findsNothing);
    expect(find.text('Next.js documentation'), findsOneWidget);
  });

  group('filters', () {
    testWidgets('the read-state control reloads with that state', (tester) async {
      final environment = await openList(tester);

      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();

      expect(environment.bookmarkRepository.listCalls.last.readState, ReadState.unread);
      expect(find.text('Next.js documentation'), findsOneWidget);
      expect(find.text('TypeScript handbook'), findsNothing);
    });

    testWidgets('submitting a tag filters by it', (tester) async {
      final environment = await openList(tester);

      await tester.enterText(find.byKey(const Key('tag-filter-field')), 'TypeScript');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(environment.bookmarkRepository.listCalls.last.tag, 'typescript');
      expect(find.text('TypeScript handbook'), findsOneWidget);
      expect(find.text('Next.js documentation'), findsNothing);
    });

    testWidgets('tapping a tag chip filters by it and fills the field', (tester) async {
      final environment = await openList(tester);

      await tester.tap(find.widgetWithText(ActionChip, 'typescript'));
      await tester.pumpAndSettle();

      expect(environment.bookmarkRepository.listCalls.last.tag, 'typescript');
      final field = tester.widget<TextField>(find.byKey(const Key('tag-filter-field')));
      expect(field.controller?.text, 'typescript');
    });

    testWidgets('clearing the filters shows everything again', (tester) async {
      final environment = await openList(tester);
      await tester.tap(find.widgetWithText(ActionChip, 'typescript'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Clear filters'));
      await tester.pumpAndSettle();

      expect(environment.bookmarkRepository.listCalls.last.isActive, isFalse);
      expect(find.text('Next.js documentation'), findsOneWidget);
      final field = tester.widget<TextField>(find.byKey(const Key('tag-filter-field')));
      expect(field.controller?.text, isEmpty);
    });

    testWidgets('explains an empty filtered result', (tester) async {
      await openList(tester);

      await tester.enterText(find.byKey(const Key('tag-filter-field')), 'does-not-exist');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('No bookmarks match these filters.'), findsOneWidget);
    });
  });

  group('actions', () {
    testWidgets('marks an unread bookmark as read', (tester) async {
      final environment = await openList(tester);

      await tester.tap(find.byTooltip('Mark read'));
      await tester.pumpAndSettle();

      expect(environment.bookmarkRepository.readChanges['b1'], isTrue);
      expect(find.byTooltip('Mark read'), findsNothing);
      expect(find.byTooltip('Mark unread'), findsNWidgets(2));
    });

    testWidgets('asks for confirmation before deleting, and cancel keeps it', (tester) async {
      final environment = await openList(tester);

      await tester.tap(find.byTooltip('Delete bookmark').first);
      await tester.pumpAndSettle();
      expect(find.text('Delete bookmark?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(environment.bookmarkRepository.deletedIds, isEmpty);
      expect(find.text('Next.js documentation'), findsOneWidget);
    });

    testWidgets('confirming the dialog deletes the bookmark', (tester) async {
      final environment = await openList(tester);

      await tester.tap(find.byTooltip('Delete bookmark').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(environment.bookmarkRepository.deletedIds, ['b1']);
      expect(find.text('Next.js documentation'), findsNothing);
      expect(find.text('TypeScript handbook'), findsOneWidget);
    });

    testWidgets('a failed action shows the message in a snack bar', (tester) async {
      final environment = await openList(tester);
      environment.bookmarkRepository.failure = const ApiException(500, 'Something broke.');

      await tester.tap(find.byTooltip('Mark read'));
      await tester.pumpAndSettle();

      expect(find.text('Something broke.'), findsOneWidget);
    });

    testWidgets('tapping a bookmark opens its link', (tester) async {
      final environment = await openList(tester);

      await tester.tap(find.text('Next.js documentation'));
      await tester.pumpAndSettle();

      expect(environment.linkOpener.opened, [Uri.parse('https://nextjs.org/docs')]);
    });

    testWidgets('a stored link that is not http(s) is never opened', (tester) async {
      final environment = await openList(
        tester,
        environment: TestEnvironment(
          storedToken: 'stored-token',
          bookmarks: [sampleBookmark(title: 'Sneaky', url: 'javascript:alert(1)')],
        ),
      );

      await tester.tap(find.text('Sneaky'));
      await tester.pumpAndSettle();

      expect(environment.linkOpener.opened, isEmpty);
    });
  });

  group('saving a link', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.text('Save link'));
      await tester.pumpAndSettle();
    }

    testWidgets('saves a valid link, closes the sheet and shows it', (tester) async {
      final environment = await openList(tester);
      await openSheet(tester);

      await tester.enterText(find.byKey(const Key('url-field')), 'https://react.dev/');
      await tester.enterText(find.byKey(const Key('title-field')), 'React reference');
      await tester.enterText(find.byKey(const Key('tags-field')), 'React, Docs');
      await tester.tap(find.widgetWithText(FilledButton, 'Save bookmark'));
      await tester.pumpAndSettle();

      final created = environment.bookmarkRepository.created.single;
      expect(created.title, 'React reference');
      expect(created.tags, ['react', 'docs']);
      expect(find.text('Save a link'), findsNothing);
      expect(find.text('React reference'), findsOneWidget);
    });

    testWidgets('keeps the sheet open and explains an invalid URL', (tester) async {
      final environment = await openList(tester);
      await openSheet(tester);

      await tester.enterText(find.byKey(const Key('url-field')), 'not a url');
      await tester.enterText(find.byKey(const Key('title-field')), 'Broken');
      await tester.tap(find.widgetWithText(FilledButton, 'Save bookmark'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a full URL, including https://.'), findsOneWidget);
      expect(find.text('Save a link'), findsOneWidget);
      expect(environment.bookmarkRepository.created, isEmpty);
    });

    testWidgets('refuses a javascript: URL', (tester) async {
      await openList(tester);
      await openSheet(tester);

      await tester.enterText(find.byKey(const Key('url-field')), 'javascript:alert(1)');
      await tester.enterText(find.byKey(const Key('title-field')), 'Sneaky');
      await tester.tap(find.widgetWithText(FilledButton, 'Save bookmark'));
      await tester.pumpAndSettle();

      expect(find.text('Only http and https links can be saved.'), findsOneWidget);
    });

    testWidgets('shows the API message when saving fails', (tester) async {
      final environment = await openList(tester);
      await openSheet(tester);
      environment.bookmarkRepository.failure = const ApiException(
        422,
        'The API rejected the submitted data.',
      );

      await tester.enterText(find.byKey(const Key('url-field')), 'https://react.dev/');
      await tester.enterText(find.byKey(const Key('title-field')), 'React reference');
      await tester.tap(find.widgetWithText(FilledButton, 'Save bookmark'));
      await tester.pumpAndSettle();

      expect(find.text('The API rejected the submitted data.'), findsOneWidget);
      expect(find.text('Save a link'), findsOneWidget);
    });
  });
}
