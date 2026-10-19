import 'bookmark.dart';

sealed class Validated<Value> {
  const Validated();
}

final class Valid<Value> extends Validated<Value> {
  const Valid(this.value);

  final Value value;
}

final class Invalid<Value> extends Validated<Value> {
  const Invalid(this.message);

  final String message;
}

const int maxTagsPerBookmark = 10;
const int maxTagLength = 32;

/// Splits a comma separated string into lowercase tags without blanks or
/// duplicates, keeping the order in which they first appear.
List<String> normalizeTags(String rawTags) {
  final seen = <String>{};
  for (final candidate in rawTags.split(',')) {
    final tag = candidate.trim().toLowerCase();
    if (tag.isNotEmpty) seen.add(tag);
  }
  return seen.toList();
}

Validated<NewBookmark> parseNewBookmark({
  required String url,
  required String title,
  String tags = '',
  String notes = '',
}) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) {
    return const Invalid('Enter a full URL, including https://.');
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return const Invalid('Only http and https links can be saved.');
  }
  if (uri.host.isEmpty) {
    return const Invalid('Enter a full URL, including https://.');
  }

  final trimmedTitle = title.trim();
  if (trimmedTitle.isEmpty) return const Invalid('Give the bookmark a title.');

  final tagList = normalizeTags(tags);
  if (tagList.length > maxTagsPerBookmark) {
    return const Invalid('Use at most $maxTagsPerBookmark tags per bookmark.');
  }
  if (tagList.any((tag) => tag.length > maxTagLength)) {
    return const Invalid('Tags can have at most $maxTagLength characters.');
  }

  final trimmedNotes = notes.trim();
  return Valid(
    NewBookmark(
      url: uri.toString(),
      title: trimmedTitle,
      tags: tagList,
      notes: trimmedNotes.isEmpty ? null : trimmedNotes,
    ),
  );
}
