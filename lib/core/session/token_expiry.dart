import 'dart:convert';

/// Reads only the `exp` claim of a JWT. The signature is verified by the API,
/// never here, so an unreadable or claim-less token counts as "not expired" and
/// the API gets the final say.
bool isTokenExpired(String token, DateTime now) {
  final segments = token.split('.');
  if (segments.length < 2) return false;

  try {
    final payload =
        jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
            )
            as Map<String, dynamic>;
    final expiresAtSeconds = payload['exp'];
    if (expiresAtSeconds is! num) return false;
    return expiresAtSeconds * 1000 <= now.millisecondsSinceEpoch;
  } on FormatException {
    return false;
  } on TypeError {
    return false;
  }
}
