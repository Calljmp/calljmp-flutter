import 'dart:convert';
import 'dart:developer' as developer;
import 'package:calljmp/access.dart';
import 'package:calljmp/attestation.dart';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;

/// The [Integrity] class is responsible for managing the integrity of the
/// application by providing methods for device attestation and access token
/// management. It interacts with the Calljmp service to perform these
/// operations.
class Integrity {
  final Config _config;
  final Attestation _attestation;

  Integrity(this._config, this._attestation);

  /// Retrieves a challenge token from the server.
  Future<({String challengeToken})> challenge() => http
      .request("${_config.serviceUrl}/integrity/challenge")
      .use(http.context(_config))
      .get()
      .json((json) => (challengeToken: json["challengeToken"] as String));

  /// Checks if the current access token is valid.
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
  Future<void> clear() async {
    await CalljmpStore.instance.delete(CalljmpStoreKey.accessToken);
  }

  /// Performs device attestation and retrieves an access token.
  ///
  /// If a [challengeToken] is provided, it will be used during attestation.
  ///
  /// Returns a [Future] containing an object with the access token as [accessToken].
  /// Throws an error if attestation fails.
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
        .json({"token": challengeToken, "attestationToken": attestationToken})
        .post()
        .json((json) => (accessToken: json["accessToken"] as String));

    await CalljmpStore.instance.put(
      CalljmpStoreKey.accessToken,
      result.accessToken,
    );
    return result;
  }
}
