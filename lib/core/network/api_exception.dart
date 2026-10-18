class ApiException implements Exception {
  const ApiException(
    this.statusCode,
    this.message, {
    this.sessionExpired = false,
  });

  const ApiException.unreachable()
    : statusCode = 503,
      message = 'The bookmarks API is unreachable.',
      sessionExpired = false;

  final int statusCode;
  final String message;

  /// True only when an authenticated request was rejected with 401. A wrong
  /// password on the login form is also a 401, but it is not an expired session.
  final bool sessionExpired;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
