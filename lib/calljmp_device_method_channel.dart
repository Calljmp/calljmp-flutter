import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'calljmp_device_interface.dart';

/// An implementation of [CalljmpDevice] that uses method channels.
class MethodChannelCalljmpDevice extends CalljmpDevice {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('calljmp_device');

  @override
  Future<AppleAttestationResult> appleAttestKey(
    String keyId,
    String data,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      "appleAttestKey",
      {"keyId": keyId, "data": data},
    );
    return AppleAttestationResult.fromJson(result!);
  }

  @override
  Future<String> appleGenerateAttestationKey() async {
    final result = await methodChannel.invokeMethod(
      "appleGenerateAttestationKey",
    );
    return result as String;
  }

  @override
  Future<AndroidIntegrityResult> androidRequestIntegrityToken(
    int? cloudProjectNumber,
    String data,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      "androidRequestIntegrityToken",
      {"cloudProjectNumber": cloudProjectNumber, "data": data},
    );
    return AndroidIntegrityResult.fromJson(result!);
  }
}
