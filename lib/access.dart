/// Access token utilities for JWT authentication in the Calljmp SDK.
///
/// This module provides functionality for parsing, validating, and managing
/// JWT access tokens used for API authentication.
///
/// ## Features
///
/// - JWT token parsing and validation
/// - Expiration checking
/// - User ID extraction
/// - Safe parsing with error handling
///
/// ## Example
///
/// ```dart
/// final token = AccessToken.parse(tokenString);
/// if (token.isValid) {
///   print('User ID: ${token.userId}');
/// }
/// ```
library;

import 'dart:convert';

/// Represents a parsed and validated access token (JWT) for API authentication.
///
/// AccessToken provides convenient access to JWT payload information
/// and validation methods for checking token expiration and validity.
///
/// ## Usage
///
/// ```dart
/// // Parse a token string
/// final token = AccessToken.parse(jwtString);
///
/// // Check validity
/// if (token.isValid) {
///   print('Token is valid for user: ${token.userId}');
/// }
///
/// // Safe parsing
/// final result = AccessToken.tryParse(tokenString);
/// if (result.data != null) {
///   print('Token parsed successfully');
/// } else {
///   print('Parse error: ${result.error}');
/// }
/// ```
class AccessToken {
  /// The raw JWT token string.
  final String _raw;

  /// Token expiration timestamp (Unix timestamp in seconds).
  final int _exp;

  /// The user ID extracted from the token payload, if present.
  final int? userId;

  /// Private constructor for creating AccessToken instances.
  ///
  /// [_raw] The raw JWT token string.
  /// [userId] The user ID from the token payload.
  /// [exp] The expiration timestamp.
  AccessToken._(this._raw, {required this.userId, required exp}) : _exp = exp;

  /// Parses a JWT access token string.
  ///
  /// This method validates the JWT structure and extracts the payload
  /// information including user ID and expiration time.
  ///
  /// [token] The JWT token string to parse.
  ///
  /// Returns an AccessToken instance with parsed information.
  ///
  /// Throws [FormatException] if the token format is invalid or cannot be parsed.
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   final accessToken = AccessToken.parse(tokenString);
  ///   print('User: ${accessToken.userId}');
  /// } catch (e) {
  ///   print('Invalid token: $e');
  /// }
  /// ```
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
  ///
  /// This method provides safe token parsing that returns both success
  /// and error information without throwing exceptions.
  ///
  /// [token] The JWT token string to parse.
  ///
  /// Returns a record with either the parsed AccessToken or error information.
  /// - data: The parsed AccessToken if successful, null if failed
  /// - error: The error that occurred during parsing, null if successful
  ///
  /// ## Example
  ///
  /// ```dart
  /// final result = AccessToken.tryParse(tokenString);
  /// if (result.data != null) {
  ///   print('Token is valid for user: ${result.data!.userId}');
  /// } else {
  ///   print('Parse failed: ${result.error}');
  /// }
  /// ```
  static ({AccessToken? data, Object? error}) tryParse(String token) {
    try {
      final accessToken = AccessToken.parse(token);
      return (data: accessToken, error: null);
    } catch (error) {
      return (data: null, error: error);
    }
  }

  /// Checks if the token is expired.
  ///
  /// Compares the token's expiration timestamp with the current time
  /// to determine if the token has expired.
  ///
  /// Returns true if the token has expired, false otherwise.
  bool get isExpired => _exp < DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Checks if the token is valid (not expired).
  ///
  /// This is a convenience getter that returns the opposite of [isExpired].
  ///
  /// Returns true if the token is still valid, false if expired.
  bool get isValid => !isExpired;

  /// Returns the raw token string.
  ///
  /// This allows the AccessToken to be used directly as a string
  /// when needed for API calls or storage.
  @override
  String toString() => _raw;

  /// Decodes the JWT payload from a Base64-encoded string.
  ///
  /// This private method handles the Base64 decoding and JSON parsing
  /// of the JWT payload section.
  ///
  /// [base64Payload] The Base64-encoded JWT payload.
  ///
  /// Returns a Map containing the decoded payload data.
  static Map<String, dynamic> _decodePayload(String base64Payload) {
    final decoded = base64.decode(base64Payload);
    final jsonStr = String.fromCharCodes(decoded);
    return json.decode(jsonStr) as Map<String, dynamic>;
  }
}
