import 'dart:convert';
import 'dart:io';
import 'package:calljmp/calljmp_device_interface.dart';

/// Provides device attestation functionality for iOS and Android platforms.
///
/// The Attestation class handles platform-specific device verification to ensure
/// that API requests are coming from legitimate, unmodified applications. This
/// is a core security feature that prevents unauthorized access and API abuse.
///
/// ## Platform Support
///
/// - **iOS**: Uses Apple's App Attestation service to verify app integrity
/// - **Android**: Uses Google Play Integrity API to verify app and device integrity
///
/// ## Security Benefits
///
/// - Verifies that the app hasn't been tampered with or modified
/// - Confirms the app is running on a legitimate device
/// - Prevents API access from emulators, rooted devices, or modified apps
/// - Eliminates the need for traditional API keys
///
/// ## Usage
///
/// Attestation is handled automatically by the SDK and typically doesn't
/// require direct interaction from application code.
///
/// ```dart
/// // Attestation happens automatically during authentication
/// final user = await calljmp.users.auth.email.authenticate(
///   email: 'user@example.com',
///   password: 'password',
///   policy: UserAuthenticationPolicy.signInOrCreate,
/// );
/// ```
class Attestation {
  final int? _cloudProjectNumber;
  String? _keyId;

  /// Creates a new Attestation instance.
  ///
  /// ## Parameters
  ///
  /// - [keyId]: iOS App Attestation key identifier (optional, generated if needed)
  /// - [cloudProjectNumber]: Google Cloud project number for Android Play Integrity
  Attestation({String? keyId, int? cloudProjectNumber})
    : _keyId = keyId,
      _cloudProjectNumber = cloudProjectNumber;

  /// Performs device attestation with the provided data.
  ///
  /// This method creates a platform-specific attestation token that proves
  /// the app's authenticity and integrity. The attestation includes the
  /// provided data to prevent replay attacks.
  ///
  /// ## Parameters
  ///
  /// - [data]: Data to include in the attestation (String or Object that will be JSON encoded)
  ///
  /// ## Returns
  ///
  /// A Future that resolves to an attestation object containing the platform-specific token
  ///
  /// ## Throws
  ///
  /// - [Exception] if the platform is not supported
  /// - Platform-specific exceptions if attestation fails
  ///
  /// ## Platform Details
  ///
  /// **iOS**: Uses Apple's App Attestation service which requires:
  /// - An attestation key (generated automatically if needed)
  /// - The app to be signed with a valid provisioning profile
  /// - The device to support attestation (iOS 14+)
  ///
  /// **Android**: Uses Google Play Integrity API which requires:
  /// - A valid Google Cloud project number
  /// - The app to be installed from Google Play or a trusted source
  /// - Play Integrity API to be enabled in the Google Cloud Console
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
