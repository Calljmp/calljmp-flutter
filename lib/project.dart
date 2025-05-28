import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:calljmp/attestation.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;

class Project {
  final Config _config;
  final Attestation _attestation;

  Project(this._config, this._attestation);

  Future<void> connect() async {
    final attest = await _attestation
        .attest({'platform': Platform.operatingSystem})
        .catchError((error) {
          developer.log(
            "Failed to attest, this is fatal error unless it is in debug mode",
            name: "calljmp",
            error: error,
          );
          return Null;
        });
    final attestationToken = base64.encode(utf8.encode(jsonEncode(attest)));
    await http
        .request("${_config.projectUrl}/app/connect")
        .use(http.context(_config))
        .post({"attestationToken": attestationToken})
        .json();
  }
}
