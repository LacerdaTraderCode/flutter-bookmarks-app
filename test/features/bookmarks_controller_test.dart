import 'dart:async';

import 'package:flutter_bookmarks_app/core/network/api_exception.dart';
import 'package:flutter_bookmarks_app/core/session/session_controller.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/application/bookmarks_controller.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/domain/bookmark.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/domain/bookmark_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_environment.dart';

void main() {
  late TestEnvironment environment;
  late ProviderContainer container;

  BookmarksController controller() =>
      container.read(bookmarksControllerProvider.notifier);
  BookmarksState state() => container.read(bookmarksControllerProvider);

  // The controller is scoped to the session token, so the stored session has to
  // be restored before the first read or the state would be rebuilt mid-test.
  setUp(() async {
    environment = TestEnvironment(storedToken: 'stored-token');
    container = environment.container();
    container.read(sessionControllerProvider);
    await settle();
  });

  group('load', () {
    test('starts empty and not loaded', () {
      expect(state().bookmarks, isEmpty);
      expect(state().hasLoaded, isFalse);
      expect(state().isLoading, isFalse);
    });

    test('fills the list from the repository', () async {
      await controller().load();

      expect(state().bookmarks.map((bookmark) => bookmark.id), ['b1', 'b2']);
      expect(state().hasLoaded, isTrue);
      expect(state().isLoading, isFalse);
      expect(state().errorMessage, isNull);
    });

    test('reports a failure and still counts as loaded', () async {
      environment.bookmarkRepository.failure = const ApiException.unreachable();

      await controller().load();

      expect(state().errorMessage, 'The bookmarks API is unreachable.');
      expect(state().hasLoaded, isTrue);
      expect(state().bookmarks, isEmpty);
    });

    test('stays quiet when the session was rejected', () async {
      environment.bookmarkRepository.failure = const ApiException(
        401,
        'Unauthorized',
        sessionExpired: true,
      );

      await controller().load();

      expect(state().errorMessage, isNull);
    });

    test('clears an earlier error when a retry succeeds', () async {
      environment.bookmarkRepository.failure = const ApiException.unreachable();
      await controller().load();

      environment.bookmarkRepository.failure = null;
      await controller().load();

      expect(state().errorMessage, isNull);
      expect(state().bookmarks, hasLength(2));
    });
  });

  group('filters', () {
    test('setTag normalizes the tag and reloads with it', () async {
      await controller().setTag('  TypeScript ');

      expect(environment.bookmarkRepository.listCalls.last.tag, 'typescript');
      expect(state().bookmarks.map((bookmark) => bookmark.id), ['b2']);
    });

    test('setReadState reloads with the read state', () async {
      await controller().setReadState(ReadState.unread);

      expect(
        environment.bookmarkRepository.listCalls.last.readState,
        ReadState.unread,
      );
      expect(state().bookmarks.map((bookmark) => bookmark.id), ['b1']);
    });

    test('clearFilters reloads without any filter', () async {
      await controller().setTag('typescript');

      await controller().clearFilters();

      expect(environment.bookmarkRepository.listCalls.last.isActive, isFalse);
      expect(state().bookmarks, hasLength(2));
    });

    test('a slow answer for an old filter cannot overwrite a newer one', () async {
      final pending = <Completer<List<Bookmark>>>[];
      environment.bookmarkRepository.listHandler = (filters) {
        final completer = Completer<List<Bookmark>>();
        pending.add(completer);
        return completer.future;
      };

      final firstLoad = controller().load();
      final secondLoad = controller().setTag('newer');

      pending[1].complete([sampleBookmark(id: 'newer', title: 'Newer result')]);
      await secondLoad;
      pending[0].complete([sampleBookmark(id: 'older', title: 'Older result')]);
      await firstLoad;

      expect(state().bookmarks.map((bookmark) => bookmark.id), ['newer']);
    });
  });

  group('mutations', () {
    setUp(() => controller().load());

    test('add saves the bookmark and shows it in the list', () async {
      final error = await controller().add(
        const NewBookmark(url: 'https://react.dev/', title: 'React reference'),
      );

      expect(error, isNull);
      expect(environment.bookmarkRepository.created.single.title, 'React reference');
      expect(state().bookmarks.first.title, 'React reference');
    });

    test('add returns the message and does not reload when it fails', () async {
      environment.bookmarkRepository.failure = const ApiException(
        422,
        'The API rejected the submitted data.',
      );
      final callsBefore = environment.bookmarkRepository.listCalls.length;

      final error = await controller().add(
        const NewBookmark(url: 'https://react.dev/', title: 'React reference'),
      );

      expect(error, 'The API rejected the submitted data.');
      expect(environment.bookmarkRepository.listCalls.length, callsBefore);
    });

    test('toggleRead flips the read flag and reloads', () async {
      final unread = state().bookmarks.firstWhere((bookmark) => !bookmark.isRead);

      final error = await controller().toggleRead(unread);

      expect(error, isNull);
      expect(environment.bookmarkRepository.readChanges[unread.id], isTrue);
      expect(
        state().bookmarks.firstWhere((bookmark) => bookmark.id == unread.id).isRead,
        isTrue,
      );
    });

    test('remove deletes the bookmark and reloads', () async {
      final target = state().bookmarks.first;

      final error = await controller().remove(target);

      expect(error, isNull);
      expect(environment.bookmarkRepository.deletedIds, [target.id]);
      expect(state().bookmarks.any((bookmark) => bookmark.id == target.id), isFalse);
    });

    test('remove treats an already deleted bookmark as done', () async {
      final target = state().bookmarks.first;
      environment.bookmarkRepository.bookmarks = [];

      final error = await controller().remove(target);

      expect(error, isNull);
      expect(state().bookmarks, isEmpty);
    });

    test('toggleRead reports a missing bookmark instead of hiding it', () async {
      final target = state().bookmarks.first;
      environment.bookmarkRepository.bookmarks = [];

      final error = await controller().toggleRead(target);

      expect(error, 'Bookmark not found.');
    });

    test('a rejected session returns no message', () async {
      environment.bookmarkRepository.failure = const ApiException(
        401,
        'Unauthorized',
        sessionExpired: true,
      );

      final error = await controller().remove(state().bookmarks.first);

      expect(error, isNull);
    });
  });

  test('the list is thrown away when the person signs out', () async {
    await controller().load();
    expect(state().bookmarks, isNotEmpty);

    await container.read(sessionControllerProvider.notifier).signOut();

    expect(state().bookmarks, isEmpty);
    expect(state().hasLoaded, isFalse);
  });
}
