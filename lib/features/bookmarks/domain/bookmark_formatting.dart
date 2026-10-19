const List<String> _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats in UTC so the day never shifts with the device's time zone.
String formatSavedDate(DateTime? savedAt) {
  if (savedAt == null) return 'unknown date';
  final utc = savedAt.toUtc();
  return '${utc.day} ${_monthAbbreviations[utc.month - 1]} ${utc.year}';
}

String hostnameOf(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  if (host.isEmpty) return url;
  return host.startsWith('www.') ? host.substring(4) : host;
}

/// Bookmark URLs come from the API, so a stored `javascript:` or `file:` value
/// must never be opened. Only http and https links are returned.
Uri? safeExternalUri(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return null;
  return (uri.scheme == 'http' || uri.scheme == 'https') ? uri : null;
}
