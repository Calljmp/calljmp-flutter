import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'calljmp_device_interface.dart';

/// An implementation of [CalljmpDevice] that uses method channels.
class MethodChannelCalljmpDevice extends CalljmpDevice {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('calljmp_device');

  @override
  Future<String> generateAttestationKey() {
    // TODO: implement generateAttestationKey
    return super.generateAttestationKey();
  }

  @override
  Future<AttestationResult> attest(String keyId, String data) {
    // TODO: implement attest
    return super.attest(keyId, data);
  }
}
