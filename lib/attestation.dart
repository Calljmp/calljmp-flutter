import 'dart:convert';
import 'dart:io';
import 'package:calljmp/calljmp_device_interface.dart';

class Attestation {
  final int? _cloudProjectNumber;
  String? _keyId;

  Attestation({String? keyId, int? cloudProjectNumber})
    : _keyId = keyId,
      _cloudProjectNumber = cloudProjectNumber;

  Future<Object> attest(dynamic data) async {
    final attestationData = data is String ? data : jsonEncode(data);

    if (Platform.isIOS) {
      _keyId ??= await CalljmpDevice.instance.appleGenerateAttestationKey();
      return CalljmpDevice.instance.appleAttestKey(_keyId!, attestationData);
    }

    if (Platform.isAndroid) {
      return CalljmpDevice.instance.androidRequestIntegrityToken(
        _cloudProjectNumber,
        attestationData,
      );
    }

    throw Exception("Unsupported platform: ${Platform.operatingSystem}");
  }
}
