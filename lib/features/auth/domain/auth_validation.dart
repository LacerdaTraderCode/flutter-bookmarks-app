const int minimumPasswordLength = 8;

final RegExp _emailShape = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

// Each validator returns an error message, or null when the value is fine, so
// it can be passed straight to a FormField.

String? validateEmail(String? value) {
  final email = (value ?? '').trim();
  return _emailShape.hasMatch(email) ? null : 'Enter a valid email address.';
}

String? validateLoginPassword(String? value) {
  return (value == null || value.isEmpty) ? 'Enter your password.' : null;
}

String? validateFullName(String? value) {
  return (value ?? '').trim().isEmpty ? 'Enter your name.' : null;
}

String? validateNewPassword(String? value) {
  return (value ?? '').length < minimumPasswordLength
      ? 'Use a password with at least $minimumPasswordLength characters.'
      : null;
}
