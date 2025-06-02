import 'dart:convert';
import 'dart:developer' as developer;
import 'package:calljmp/attestation.dart';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/users/auth.dart';
import 'package:calljmp/users/users.dart';
import 'package:calljmp/http.dart' as http;

class Apple {
  final Config _config;
  final Attestation _attestation;

  /// Creates a new Email authentication handler.
  ///
  /// This constructor is typically called internally by the Auth class
  /// and should not be used directly in application code.
  ///
  /// ## Parameters
  ///
  /// - [_config]: The SDK configuration containing API endpoints and settings
  /// - [_attestation]: The attestation service for device verification
  Apple(this._config, this._attestation);

  Future<User> authenticate({
    required String challengeToken,
    required String identityToken,
    bool? emailVerified,
    String? name,
    List<String>? tags,
    UserAuthenticationPolicy? policy,
    bool? doNotNotify,
  }) async {
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
        .request("${_config.serviceUrl}/users/auth/apple")
        .use(http.context(_config))
        .post({
          "challengeToken": challengeToken,
          "identityToken": identityToken,
          "attestationToken": attestationToken,
          if (emailVerified != null) "emailVerified": emailVerified,
          if (name != null) "name": name,
          if (tags != null) "tags": tags,
          if (policy != null) "policy": policy.value,
          "doNotNotify": doNotNotify ?? false,
        })
        .json(
          (json) => (
            accessToken: json["accessToken"],
            user: User.fromJson(json["user"]),
          ),
        );

    await CalljmpStore.instance.put(
      CalljmpStoreKey.accessToken,
      result.accessToken,
    );

    return result.user;
  }
}
