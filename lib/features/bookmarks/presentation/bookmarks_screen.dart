import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_service.dart';
import '../application/bookmarks_controller.dart';
import '../application/link_opener.dart';
import '../domain/bookmark.dart';
import '../domain/bookmark_formatting.dart';
import 'add_bookmark_sheet.dart';
import 'bookmark_tile.dart';
import 'filter_bar.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(bookmarksControllerProvider.notifier).load(),
    );
  }

  void _showError(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openAddSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddBookmarkSheet(),
    );
  }

  Future<void> _toggleRead(Bookmark bookmark) async {
    final error = await ref
        .read(bookmarksControllerProvider.notifier)
        .toggleRead(bookmark);
    _showError(error);
  }

  Future<void> _confirmDelete(Bookmark bookmark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete bookmark?'),
        content: Text('"${bookmark.title}" will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(bookmarksControllerProvider.notifier)
        .remove(bookmark);
    _showError(error);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookmarksControllerProvider);
    final controller = ref.read(bookmarksControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading list'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Save link'),
      ),
      body: Column(
        children: [
          if (state.isLoading && state.hasLoaded)
            const LinearProgressIndicator(),
          const FilterBar(),
          if (state.errorMessage != null)
            _ErrorBanner(message: state.errorMessage!, onRetry: controller.load),
          Expanded(child: _buildContent(state, controller)),
        ],
      ),
    );
  }

  Widget _buildContent(BookmarksState state, BookmarksController controller) {
    if (!state.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.bookmarks.isEmpty) {
      // After a failed request the banner above already explains the problem.
      if (state.errorMessage != null) return const SizedBox.shrink();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.filters.isActive
                ? 'No bookmarks match these filters.'
                : 'Nothing saved yet. Tap "Save link" to add your first one.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        itemCount: state.bookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = state.bookmarks[index];
          final link = safeExternalUri(bookmark.url);
          return BookmarkTile(
            key: ValueKey(bookmark.id),
            bookmark: bookmark,
            onOpen: link == null
                ? null
                : () => ref.read(linkOpenerProvider).open(link),
            onToggleRead: () => _toggleRead(bookmark),
            onDelete: () => _confirmDelete(bookmark),
            onTagSelected: controller.setTag,
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
