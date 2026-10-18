import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/session_controller.dart';
import '../data/bookmark_repository.dart';
import '../domain/bookmark.dart';
import '../domain/bookmark_filters.dart';

class BookmarksState {
  const BookmarksState({
    this.bookmarks = const [],
    this.filters = const BookmarkFilters(),
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final List<Bookmark> bookmarks;
  final BookmarkFilters filters;
  final bool isLoading;

  /// False until the first request has finished, successfully or not.
  final bool hasLoaded;
  final String? errorMessage;

  BookmarksState copyWith({
    List<Bookmark>? bookmarks,
    BookmarkFilters? filters,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BookmarksState(
      bookmarks: bookmarks ?? this.bookmarks,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BookmarksController extends Notifier<BookmarksState> {
  // Bumped when this state is discarded (a different session, or disposal), so
  // an answer that arrives afterwards is dropped instead of shown.
  int _sessionEpoch = 0;

  // Bumped by every load, so only the newest request may update the list.
  int _loadSerial = 0;

  BookmarkRepository get _repository => ref.read(bookmarkRepositoryProvider);

  @override
  BookmarksState build() {
    // The list belongs to one signed-in person: when the token changes, this
    // state is thrown away and rebuilt empty.
    ref.watch(sessionControllerProvider.select((session) => session.token));
    _sessionEpoch++;
    ref.onDispose(() => _sessionEpoch++);
    return const BookmarksState();
  }

  Future<void> load() async {
    final epoch = _sessionEpoch;
    final serial = ++_loadSerial;
    bool isStale() => epoch != _sessionEpoch || serial != _loadSerial;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bookmarks = await _repository.list(state.filters);
      if (isStale()) return;
      state = state.copyWith(
        bookmarks: bookmarks,
        isLoading: false,
        hasLoaded: true,
      );
    } on ApiException catch (error) {
      if (isStale()) return;
      // A rejected session already signed the person out; the screen is about
      // to be replaced, so there is nothing to explain here.
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: error.sessionExpired ? null : error.message,
      );
    }
  }

  Future<void> setTag(String rawTag) {
    state = state.copyWith(
      filters: state.filters.withTag(BookmarkFilters.normalizeTag(rawTag)),
    );
    return load();
  }

  Future<void> setReadState(ReadState readState) {
    state = state.copyWith(filters: state.filters.withReadState(readState));
    return load();
  }

  Future<void> clearFilters() {
    state = state.copyWith(filters: const BookmarkFilters());
    return load();
  }

  /// Each mutation returns an error message to show, or null on success.
  Future<String?> add(NewBookmark bookmark) {
    return _mutate(() async {
      await _repository.create(bookmark);
    });
  }

  Future<String?> toggleRead(Bookmark bookmark) {
    return _mutate(() async {
      await _repository.setRead(bookmark.id, isRead: !bookmark.isRead);
    });
  }

  Future<String?> remove(Bookmark bookmark) {
    // A 404 means it was already deleted elsewhere; the refreshed list is the
    // outcome the person wanted.
    return _mutate(() => _repository.delete(bookmark.id), tolerateMissing: true);
  }

  Future<String?> _mutate(
    Future<void> Function() action, {
    bool tolerateMissing = false,
  }) async {
    final epoch = _sessionEpoch;
    try {
      await action();
    } on ApiException catch (error) {
      if (error.sessionExpired) return null;
      if (!(tolerateMissing && error.isNotFound)) return error.message;
    }
    if (epoch != _sessionEpoch) return null;
    await load();
    return null;
  }
}

final bookmarksControllerProvider =
    NotifierProvider<BookmarksController, BookmarksState>(
      BookmarksController.new,
    );
