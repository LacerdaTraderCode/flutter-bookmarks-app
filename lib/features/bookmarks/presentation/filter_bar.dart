import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/bookmarks_controller.dart';
import '../domain/bookmark_filters.dart';

class FilterBar extends ConsumerStatefulWidget {
  const FilterBar({super.key});

  @override
  ConsumerState<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<FilterBar> {
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the text field in step when the tag changes elsewhere, for example
    // by tapping a tag chip on a bookmark.
    ref.listen(bookmarksControllerProvider.select((state) => state.filters.tag), (
      previous,
      next,
    ) {
      final text = next ?? '';
      if (_tagController.text != text) _tagController.text = text;
    });

    final filters = ref.watch(
      bookmarksControllerProvider.select((state) => state.filters),
    );
    final controller = ref.read(bookmarksControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('tag-filter-field'),
            controller: _tagController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Filter by tag',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sell_outlined),
            ),
            onSubmitted: controller.setTag,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<ReadState>(
                  segments: [
                    for (final readState in ReadState.values)
                      ButtonSegment<ReadState>(
                        value: readState,
                        label: Text(readState.label),
                      ),
                  ],
                  selected: {filters.readState},
                  onSelectionChanged: (selection) =>
                      controller.setReadState(selection.first),
                ),
              ),
              if (filters.isActive)
                IconButton(
                  tooltip: 'Clear filters',
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  onPressed: controller.clearFilters,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
