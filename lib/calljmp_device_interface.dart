import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'calljmp_device_method_channel.dart';

class AppleAttestationResult {
  final String keyId;
  final String bundleId;
  final String attestation;

  AppleAttestationResult({
    required this.keyId,
    required this.bundleId,
    required this.attestation,
  });

  Map<String, dynamic> toJson() => {
    'keyId': keyId,
    'bundleId': bundleId,
    'attestation': attestation,
  };

  factory AppleAttestationResult.fromJson(Map<String, dynamic> json) =>
      AppleAttestationResult(
        keyId: json['keyId'],
        bundleId: json['bundleId'],
        attestation: json['attestation'],
      );

  @override
  String toString() {
    return 'AppleAttestationResult(keyId: $keyId, bundleId: $bundleId, attestation: $attestation)';
  }
}

class AndroidIntegrityResult {
  final String integrityToken;
  final String packageName;

  AndroidIntegrityResult({
    required this.integrityToken,
    required this.packageName,
  });

  Map<String, dynamic> toJson() => {
    'integrityToken': integrityToken,
    'packageName': packageName,
  };

  factory AndroidIntegrityResult.fromJson(Map<String, dynamic> json) =>
      AndroidIntegrityResult(
        integrityToken: json['integrityToken'],
        packageName: json['packageName'],
      );

  @override
  String toString() {
    return 'AndroidIntegrityResult(integrityToken: $integrityToken, packageName: $packageName)';
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

  Future<String> appleGenerateAttestationKey() {
    throw UnimplementedError(
      'appleGenerateAttestationKey() has not been implemented.',
    );
  }

  Future<AppleAttestationResult> appleAttestKey(String keyId, String data) {
    throw UnimplementedError('appleAttestKey() has not been implemented.');
  }

  Future<AndroidIntegrityResult> androidRequestIntegrityToken(
    int? cloudProjectNumber,
    String data,
  ) {
    throw UnimplementedError(
      'androidRequestIntegrityToken() has not been implemented.',
    );
  }
}
