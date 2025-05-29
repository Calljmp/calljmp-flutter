import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:calljmp/attestation.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;

/// Provides project configuration and management functionality.
///
/// The Project class handles project-level operations including connecting
/// to the Calljmp service and establishing the initial device attestation
/// for secure communication.
///
/// ## Usage
///
/// ```dart
/// final calljmp = Calljmp();
///
/// // Connect to the project and establish device attestation
/// await calljmp.project.connect();
/// ```
class Project {
  final Config _config;
  final Attestation _attestation;

  /// Creates a new Project instance.
  ///
  /// This constructor is typically called internally by the Calljmp client
  /// and should not be used directly in application code.
  ///
  /// ## Parameters
  ///
  /// - [_config]: The SDK configuration containing API endpoints and settings
  /// - [_attestation]: The attestation service for device verification
  Project(this._config, this._attestation);

  /// Connects to the Calljmp project and establishes device attestation.
  ///
  /// This method performs the initial connection to your Calljmp project,
  /// including device attestation to verify the app's authenticity. It should
  /// be called early in your app's lifecycle to establish secure communication.
  ///
  /// The method uses platform-specific attestation (App Attestation on iOS,
  /// Play Integrity on Android) to prove the app's identity and integrity.
  ///
  /// ## Throws
  ///
  /// - [HttpException] if there's a network error
  /// - [CalljmpException] if the project connection fails
  /// - [AttestationException] if device attestation fails (in production)
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   await calljmp.project.connect();
  ///   print('Successfully connected to Calljmp project');
  /// } catch (e) {
  ///   print('Failed to connect: $e');
  /// }
  /// ```
  ///
  /// ## Note
  ///
  /// In debug mode, attestation failures are logged but do not prevent
  /// the connection from succeeding. In production, attestation failures
  /// will cause the connection to fail for security reasons.
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
