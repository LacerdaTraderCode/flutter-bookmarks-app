class Bookmark {
  const Bookmark({
    required this.id,
    required this.url,
    required this.title,
    required this.tags,
    required this.isRead,
    this.notes,
    this.savedAt,
  });

  // The API's snake_case wire format is translated here and nowhere else.
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      notes: json['notes'] as String?,
      isRead: json['is_read'] as bool,
      savedAt: DateTime.tryParse(json['saved_at'] as String? ?? ''),
    );
  }

  final String id;
  final String url;
  final String title;
  final List<String> tags;
  final String? notes;
  final bool isRead;

  /// Null when the API sent a timestamp that cannot be parsed.
  final DateTime? savedAt;
}

class NewBookmark {
  const NewBookmark({
    required this.url,
    required this.title,
    this.tags = const [],
    this.notes,
  });

  final String url;
  final String title;
  final List<String> tags;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'tags': tags,
    'notes': notes,
  };
}
