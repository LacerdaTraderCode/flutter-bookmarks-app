import 'package:flutter/material.dart';

import '../domain/bookmark.dart';
import '../domain/bookmark_formatting.dart';

class BookmarkTile extends StatelessWidget {
  const BookmarkTile({
    super.key,
    required this.bookmark,
    required this.onOpen,
    required this.onToggleRead,
    required this.onDelete,
    required this.onTagSelected,
  });

  final Bookmark bookmark;

  /// Null when the stored URL is not an http(s) link and must not be opened.
  final VoidCallback? onOpen;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final notes = bookmark.notes;

    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: bookmark.isRead ? mutedColor : null,
                      ),
                    ),
                    Text(
                      hostnameOf(bookmark.url),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                      ),
                    ),
                    if (notes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(notes),
                      ),
                    if (bookmark.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final tag in bookmark.tags)
                              ActionChip(
                                label: Text(tag),
                                onPressed: () => onTagSelected(tag),
                              ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Saved ${formatSavedDate(bookmark.savedAt)} · '
                        '${bookmark.isRead ? 'Read' : 'Unread'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: bookmark.isRead ? 'Mark unread' : 'Mark read',
                    icon: Icon(bookmark.isRead ? Icons.undo : Icons.check),
                    onPressed: onToggleRead,
                  ),
                  IconButton(
                    tooltip: 'Delete bookmark',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
