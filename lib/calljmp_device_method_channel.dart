import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'calljmp_device_interface.dart';

/// Method channel implementation of [CalljmpDevice] for cross-platform device operations.
///
/// This class provides a concrete implementation of device-specific operations
/// including Apple App Attestation and Android Play Integrity checks through
/// Flutter's method channel communication system.
///
/// The implementation bridges Dart code with native platform implementations
/// on iOS and Android, enabling secure device attestation and integrity verification.
///
/// Example usage:
/// ```dart
/// final device = MethodChannelCalljmpDevice();
///
/// // Generate Apple attestation key
/// final keyId = await device.appleGenerateAttestationKey();
///
/// // Attest the key with challenge data
/// final result = await device.appleAttestKey(keyId, challengeData);
///
/// // Request Android integrity token
/// final integrityResult = await device.androidRequestIntegrityToken(
///   12345, // Cloud project number
///   challengeData,
/// );
/// ```
class MethodChannelCalljmpDevice extends CalljmpDevice {
  /// The method channel used to interact with the native platform.
  ///
  /// This channel facilitates communication between the Dart layer and
  /// native platform implementations for device-specific operations.
  /// The channel name 'calljmp_device' must match the native implementation.
  @visibleForTesting
  final methodChannel = const MethodChannel('calljmp_device');

  /// Generates a UUID using native platform implementation.
  ///
  /// This method creates a universally unique identifier (UUID) using the
  /// platform's native UUID generation capabilities. On iOS, it uses NSUUID,
  /// and on Android, it uses java.util.UUID.
  ///
  /// Returns a [Future] that completes with a [String] representing the
  /// generated UUID in standard format (e.g., "123e4567-e89b-12d3-a456-426614174000").
  ///
  /// Throws:
  /// - [PlatformException] if UUID generation fails
  /// - [MissingPluginException] if the platform implementation is not available
  ///
  /// Example:
  /// ```dart
  /// final uuid = await device.generateUuid();
  /// print('Generated UUID: $uuid');
  /// ```
  @override
  Future<String> generateUuid() async {
    final result = await methodChannel.invokeMethod<String>('generateUuid');
    return result!;
  }

  /// Generates an Apple App Attestation for a given key and challenge data.
  ///
  /// This method creates an attestation statement for the specified [keyId]
  /// using the provided [data] as challenge material. The attestation proves
  /// that the key was generated in the device's Secure Enclave and validates
  /// the app's authenticity.
  ///
  /// Parameters:
  /// - [keyId]: The identifier of the attestation key to use
  /// - [data]: Challenge data to include in the attestation
  ///
  /// Returns a [Future] that completes with an [AppleAttestationResult]
  /// containing the attestation statement and related metadata.
  ///
  /// Throws:
  /// - [PlatformException] if the native attestation process fails
  /// - [MissingPluginException] if the platform implementation is not available
  ///
  /// Example:
  /// ```dart
  /// final result = await device.appleAttestKey(
  ///   'key123',
  ///   base64Encode(utf8.encode('challenge-data')),
  /// );
  /// print('Attestation: ${result.attestationObject}');
  /// ```
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

  /// Generates a new Apple App Attestation key in the device's Secure Enclave.
  ///
  /// This method creates a new cryptographic key pair specifically for App Attestation.
  /// The private key remains secured in the Secure Enclave and cannot be extracted,
  /// while the public key can be used for attestation verification.
  ///
  /// Returns a [Future] that completes with a [String] representing the unique
  /// identifier for the generated attestation key.
  ///
  /// Throws:
  /// - [PlatformException] if key generation fails or if App Attestation is not supported
  /// - [MissingPluginException] if the platform implementation is not available
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final keyId = await device.appleGenerateAttestationKey();
  ///   print('Generated key ID: $keyId');
  ///   // Store keyId for future attestation operations
  /// } catch (e) {
  ///   print('Key generation failed: $e');
  /// }
  /// ```
  @override
  Future<String> appleGenerateAttestationKey() async {
    final result = await methodChannel.invokeMethod(
      "appleGenerateAttestationKey",
    );
    return result as String;
  }

  /// Requests an Android Play Integrity API token for app verification.
  ///
  /// This method initiates a Play Integrity check to verify the app's authenticity,
  /// device integrity, and licensing status. The integrity token can be used
  /// to validate that the app is running on a genuine Android device and
  /// has not been tampered with.
  ///
  /// Parameters:
  /// - [cloudProjectNumber]: Optional Google Cloud project number for enhanced verification.
  ///   If provided, enables additional Play Console integration features.
  /// - [data]: Challenge data to include in the integrity request for replay protection
  ///
  /// Returns a [Future] that completes with an [AndroidIntegrityResult]
  /// containing the integrity token and verification status.
  ///
  /// Throws:
  /// - [PlatformException] if the integrity check fails or if Play Integrity API is not available
  /// - [MissingPluginException] if the platform implementation is not available
  ///
  /// Example:
  /// ```dart
  /// final result = await device.androidRequestIntegrityToken(
  ///   123456789, // Your Google Cloud project number
  ///   base64Encode(utf8.encode('nonce-data')),
  /// );
  ///
  /// if (result.isValid) {
  ///   print('Device integrity verified');
  ///   print('Token: ${result.token}');
  /// } else {
  ///   print('Integrity check failed: ${result.error}');
  /// }
  /// ```
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
