import 'package:flutter/widgets.dart';
import 'package:flutter_bookmarks_app/app/app.dart';
import 'package:flutter_bookmarks_app/core/session/session_controller.dart';
import 'package:flutter_bookmarks_app/features/auth/data/auth_repository.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/application/link_opener.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/data/bookmark_repository.dart';
import 'package:flutter_bookmarks_app/features/bookmarks/domain/bookmark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Bundles the fakes the app is wired to in tests, so a test can both build the
/// widget tree (or a bare container) and inspect what the fakes recorded.
class TestEnvironment {
  TestEnvironment({String? storedToken, List<Bookmark>? bookmarks})
    : tokenStore = InMemoryTokenStore(storedToken),
      bookmarkRepository = FakeBookmarkRepository(
        bookmarks ??
            [
              sampleBookmark(),
              sampleBookmark(
                id: 'b2',
                title: 'TypeScript handbook',
                url: 'https://www.typescriptlang.org/docs/',
                tags: const ['typescript'],
                notes: 'Chapter on narrowing.',
                isRead: true,
              ),
            ],
      );

  final InMemoryTokenStore tokenStore;
  final FakeAuthRepository authRepository = FakeAuthRepository();
  final FakeBookmarkRepository bookmarkRepository;
  final FakeLinkOpener linkOpener = FakeLinkOpener();

  List<Override> get overrides => [
    tokenStoreProvider.overrideWithValue(tokenStore),
    authRepositoryProvider.overrideWithValue(authRepository),
    bookmarkRepositoryProvider.overrideWithValue(bookmarkRepository),
    linkOpenerProvider.overrideWithValue(linkOpener),
  ];

  /// The whole app, with the router and every screen, running on the fakes.
  Widget app() => ProviderScope(overrides: overrides, child: const BookmarksApp());

  /// A container without any widgets, for controller and service tests.
  ProviderContainer container() {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }

  /// The container behind the running app, to reach providers from a widget test.
  ProviderContainer appContainer(WidgetTester tester) {
    return ProviderScope.containerOf(tester.element(find.byType(BookmarksApp)));
  }
}

/// Lets queued microtasks run, such as the secure-storage read at start-up.
Future<void> settle() => Future<void>.delayed(Duration.zero);
