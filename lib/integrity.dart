import 'dart:convert';
import 'dart:developer' as developer;
import 'package:calljmp/access.dart';
import 'package:calljmp/attestation.dart';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;

/// Manages device integrity verification and access token lifecycle.
///
/// The Integrity class is responsible for coordinating device attestation
/// with the Calljmp service and managing access tokens for authenticated
/// API requests. It ensures that only verified, legitimate devices can
/// access your backend services.
///
/// ## Key Responsibilities
///
/// - Device attestation through platform-specific mechanisms
/// - Access token generation and management
/// - Challenge-response authentication flows
/// - Secure token storage and retrieval
///
/// ## Security Model
///
/// The integrity system works by:
/// 1. Requesting a challenge from the server
/// 2. Using device attestation to sign the challenge
/// 3. Exchanging the signed attestation for an access token
/// 4. Using the access token for subsequent API requests
///
/// ## Usage
///
/// Integrity verification typically happens automatically during authentication:
///
/// ```dart
/// // Integrity checks happen automatically
/// final user = await calljmp.users.auth.email.authenticate(
///   email: 'user@example.com',
///   password: 'password',
///   policy: UserAuthenticationPolicy.signInOrCreate,
/// );
///
/// // Manual integrity operations (rarely needed)
/// final isAuthenticated = await calljmp.integrity.authenticated();
/// if (!isAuthenticated) {
///   await calljmp.integrity.access();
/// }
/// ```
class Integrity {
  final Config _config;
  final Attestation _attestation;

  /// Creates a new Integrity instance.
  ///
  /// This constructor is typically called internally by the Calljmp client
  /// and should not be used directly in application code.
  ///
  /// ## Parameters
  ///
  /// - [_config]: The SDK configuration containing API endpoints and settings
  /// - [_attestation]: The attestation service for device verification
  Integrity(this._config, this._attestation);

  /// Retrieves a challenge token from the server.
  ///
  /// Challenge tokens are used to prevent replay attacks by ensuring that
  /// each attestation request includes fresh, server-generated data. The
  /// challenge must be signed during device attestation.
  ///
  /// ## Returns
  ///
  /// A Future that resolves to a record containing the challenge token
  ///
  /// ## Throws
  ///
  /// - [HttpException] if there's a network error
  /// - [CalljmpException] if the server returns an error
  ///
  /// ## Example
  ///
  /// ```dart
  /// final challenge = await calljmp.integrity.challenge();
  /// print('Challenge token: ${challenge.challengeToken}');
  /// ```
  Future<({String challengeToken})> challenge() => http
      .request("${_config.serviceUrl}/integrity/challenge")
      .use(http.context(_config))
      .get()
      .json((json) => (challengeToken: json["challengeToken"] as String));

  /// Checks if the current access token is valid.
  ///
  /// This method verifies whether there is a valid access token stored locally
  /// and whether that token has not expired. It does not make a network request
  /// to verify the token with the server.
  ///
  /// ## Returns
  ///
  /// A Future that resolves to true if there is a valid access token, false otherwise
  ///
  /// ## Example
  ///
  /// ```dart
  /// final isAuth = await calljmp.integrity.authenticated();
  /// if (isAuth) {
  ///   print('Device has valid access token');
  /// } else {
  ///   print('Device needs to perform attestation');
  /// }
  /// ```
  Future<bool> authenticated() async {
    final token = await CalljmpStore.instance.get(CalljmpStoreKey.accessToken);
    if (token != null) {
      final result = AccessToken.tryParse(token);
      if (result.data != null) {
        return result.data!.isValid;
      }
    }
    return false;
  }

  /// Clears the current access token from secure storage.
  ///
  /// This method removes the access token from local storage, effectively
  /// signing out the device. After calling this method, the device will need
  /// to perform attestation again to access protected resources.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await calljmp.integrity.clear();
  /// print('Access token cleared - device signed out');
  /// ```
  Future<void> clear() async {
    await CalljmpStore.instance.delete(CalljmpStoreKey.accessToken);
  }

  /// Performs device attestation and retrieves an access token.
  ///
  /// This method coordinates the complete device verification process:
  /// 1. Obtains a challenge token (if not provided)
  /// 2. Performs platform-specific device attestation
  /// 3. Exchanges the attestation for an access token
  /// 4. Stores the access token securely for future use
  ///
  /// ## Parameters
  ///
  /// - [challengeToken]: Optional challenge token (will be generated if not provided)
  ///
  /// ## Returns
  ///
  /// A Future that resolves to a record containing the access token
  ///
  /// ## Throws
  ///
  /// - [HttpException] if there's a network error
  /// - [CalljmpException] if attestation is rejected by the server
  /// - [AttestationException] if device attestation fails
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   final result = await calljmp.integrity.access();
  ///   print('Access granted: ${result.accessToken}');
  /// } catch (e) {
  ///   print('Integrity verification failed: $e');
  /// }
  /// ```
  ///
  /// ## Note
  ///
  /// In debug mode, attestation failures are logged but do not prevent
  /// access token generation. In production, attestation failures will
  /// cause the method to throw an exception.
  Future<({String accessToken})> access({String? challengeToken}) async {
    if (challengeToken == null) {
      final result = await challenge();
      challengeToken = result.challengeToken;
    }

    final attest = await _attestation
        .attest({"token": challengeToken})
        .catchError((error) {
          developer.log(
            "Failed to attest, this is fatal error unless it is in debug mode",
            name: "calljmp",
            error: error,
          );
          return Null;
        });
    final attestationToken = base64.encode(utf8.encode(jsonEncode(attest)));

    final result = await http
        .request("${_config.serviceUrl}/integrity/access")
        .use(http.context(_config))
        .post({"token": challengeToken, "attestationToken": attestationToken})
        .json((json) => (accessToken: json["accessToken"] as String));

    await CalljmpStore.instance.put(
      CalljmpStoreKey.accessToken,
      result.accessToken,
    );
    return result;
  }
}
