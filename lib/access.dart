import 'dart:convert';

/// Represents a parsed and validated access token (JWT) for API authentication.
class AccessToken {
  final String _raw;
  final int _exp;
  final int? userId;

  AccessToken._(this._raw, {required this.userId, required exp}) : _exp = exp;

  /// Parses a JWT access token string.
  /// Throws [FormatException] if the token is invalid.
  static AccessToken parse(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      throw FormatException('Invalid JWT token: $token');
    }
    final base64Payload = base64.normalize(
      parts[1].replaceAll('-', '+').replaceAll('_', '/'),
    );
    final payloadMap = _decodePayload(base64Payload);
    return AccessToken._(
      token,
      userId: payloadMap['uid'],
      exp: payloadMap['exp'],
    );
  }

  /// Tries to parse a JWT access token string, returning error info if invalid.
  static ({AccessToken? data, Object? error}) tryParse(String token) {
    try {
      final accessToken = AccessToken.parse(token);
      return (data: accessToken, error: null);
    } catch (error) {
      return (data: null, error: error);
    }
  }

  /// Checks if the token is expired.
  bool get isExpired => _exp < DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Checks if the token is valid (not expired).
  bool get isValid => !isExpired;

  /// Returns the raw token string.
  @override
  String toString() => _raw;

  static Map<String, dynamic> _decodePayload(String base64Payload) {
    final decoded = base64.decode(base64Payload);
    final jsonStr = String.fromCharCodes(decoded);
    return json.decode(jsonStr) as Map<String, dynamic>;
  }
}
