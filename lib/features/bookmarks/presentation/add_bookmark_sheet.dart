import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_page.dart';
import '../application/bookmarks_controller.dart';
import '../domain/bookmark_validation.dart';

class AddBookmarkSheet extends ConsumerStatefulWidget {
  const AddBookmarkSheet({super.key});

  @override
  ConsumerState<AddBookmarkSheet> createState() => _AddBookmarkSheetState();
}

class _AddBookmarkSheetState extends ConsumerState<AddBookmarkSheet> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _tagsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsed = parseNewBookmark(
      url: _urlController.text,
      title: _titleController.text,
      tags: _tagsController.text,
      notes: _notesController.text,
    );

    switch (parsed) {
      case Invalid(:final message):
        setState(() => _errorMessage = message);
      case Valid(:final value):
        setState(() {
          _isSaving = true;
          _errorMessage = null;
        });
        final error = await ref
            .read(bookmarksControllerProvider.notifier)
            .add(value);
        if (!mounted) return;
        if (error == null) {
          Navigator.of(context).pop();
          return;
        }
        setState(() {
          _isSaving = false;
          _errorMessage = error;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Save a link', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              key: const Key('url-field'),
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('title-field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('tags-field'),
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('notes-field'),
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              FormErrorText(_errorMessage!),
            ],
            const SizedBox(height: 16),
            SubmitButton(
              label: 'Save bookmark',
              isSubmitting: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
