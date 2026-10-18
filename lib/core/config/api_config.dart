abstract final class ApiConfig {
  // 10.0.2.2 is how the Android emulator reaches the host machine's localhost.
  static const String _configuredBaseUrl = String.fromEnvironment(
    'BOOKMARKS_API_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static String get baseUrl =>
      _configuredBaseUrl.replaceAll(RegExp(r'/+$'), '');
}
