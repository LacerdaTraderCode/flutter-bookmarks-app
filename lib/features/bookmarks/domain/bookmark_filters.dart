enum ReadState {
  all('All'),
  unread('Unread'),
  read('Read');

  const ReadState(this.label);

  final String label;
}

class BookmarkFilters {
  const BookmarkFilters({this.tag, this.readState = ReadState.all});

  final String? tag;
  final ReadState readState;

  bool get isActive => tag != null || readState != ReadState.all;

  /// A blank value means "no tag filter"; tags are matched lowercase.
  static String? normalizeTag(String raw) {
    final tag = raw.trim().toLowerCase();
    return tag.isEmpty ? null : tag;
  }

  BookmarkFilters withTag(String? newTag) =>
      BookmarkFilters(tag: newTag, readState: readState);

  BookmarkFilters withReadState(ReadState newReadState) =>
      BookmarkFilters(tag: tag, readState: newReadState);

  /// Query parameters understood by `GET /bookmarks`.
  Map<String, String> toQuery() {
    final currentTag = tag;
    return {
      if (currentTag != null) 'tag': currentTag,
      if (readState == ReadState.read) 'is_read': 'true',
      if (readState == ReadState.unread) 'is_read': 'false',
    };
  }

  @override
  bool operator ==(Object other) =>
      other is BookmarkFilters &&
      other.tag == tag &&
      other.readState == readState;

  @override
  int get hashCode => Object.hash(tag, readState);
}
