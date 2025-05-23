import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'calljmp_device_method_channel.dart';

class AttestationResult {
  final String keyId;
  final String bundleId;
  final String attestation;

  AttestationResult({
    required this.keyId,
    required this.bundleId,
    required this.attestation,
  });

  factory AttestationResult.fromJson(Map<String, dynamic> map) {
    return AttestationResult(
      keyId: map['keyId'] as String,
      bundleId: map['bundleId'] as String,
      attestation: map['attestation'] as String,
    );
  }
}

abstract class CalljmpDevice extends PlatformInterface {
  /// Constructs a CalljmpPlatform.
  CalljmpDevice() : super(token: _token);

  static final Object _token = Object();

  static CalljmpDevice _instance = MethodChannelCalljmpDevice();

  /// The default instance of [CalljmpDevice] to use.
  ///
  /// Defaults to [MethodChannelCalljmpDevice].
  static CalljmpDevice get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CalljmpDevice] when
  /// they register themselves.
  static set instance(CalljmpDevice instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> generateAttestationKey() {
    throw UnimplementedError(
      'generateAttestationKey() has not been implemented.',
    );
  }

  Future<AttestationResult> attest(String keyId, String data) {
    throw UnimplementedError('attest() has not been implemented.');
  }
}
