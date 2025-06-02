import 'dart:convert';
import 'dart:developer' as developer;
import 'package:calljmp/attestation.dart';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/users/auth.dart';
import 'package:calljmp/users/users.dart';
import 'package:crypto/crypto.dart';
import 'package:calljmp/http.dart' as http;

class Provider {
  final UserAuthenticationProvider _provider;
  final Config _config;
  final Attestation _attestation;
  final Auth _auth;

  Provider(this._provider, this._config, this._attestation, this._auth);

  Future<User> authenticate({
    required String identityToken,
    String? challengeToken,
    bool? emailVerified,
    String? name,
    List<String>? tags,
    UserAuthenticationPolicy? policy,
    bool? doNotNotify,
  }) async {
    if (challengeToken == null) {
      final result = await _auth.challenge();
      challengeToken = result.challengeToken;
    }

    final attestationHash = base64.encode(
      sha256.convert(utf8.encode("$identityToken:$challengeToken")).bytes,
    );
    final attest = await _attestation
        .attest({"hash": attestationHash})
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
        .request("${_config.serviceUrl}/users/auth/provider/${_provider.value}")
        .use(http.context(_config))
        .post({
          "challengeToken": challengeToken,
          "attestationToken": attestationToken,
          "identityToken": identityToken,
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
