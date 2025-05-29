import 'package:calljmp/attestation.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/database.dart';
import 'package:calljmp/integrity.dart';
import 'package:calljmp/project.dart';
import 'package:calljmp/service.dart';
import 'package:calljmp/storage.dart';
import 'package:calljmp/users/users.dart';

/// The main Calljmp client that provides access to all SDK functionality.
///
/// This class serves as the entry point for the Calljmp SDK, providing access to:
/// - User authentication and management
/// - Database operations with direct SQLite access
/// - Project configuration and management
/// - Custom service endpoints
/// - Local storage capabilities
/// - Device integrity verification
///
/// ## Usage
///
/// ```dart
/// // Initialize with default configuration
/// final calljmp = Calljmp();
///
/// // Initialize with custom configuration
/// final calljmp = Calljmp(
///   service: ServiceConfig(url: 'https://my-service.com'),
///   android: AndroidConfig(cloudProjectNumber: '123456789'),
///   development: DevelopmentConfig(
///     enabled: true,
///     baseUrl: 'https://dev.calljmp.com',
///   ),
/// );
/// ```
class Calljmp {
  /// Provides device integrity verification capabilities.
  final Integrity integrity;

  /// Provides user authentication and management functionality.
  final Users users;

  /// Provides project configuration and management.
  final Project project;

  /// Provides direct SQLite database access.
  final Database database;

  /// Provides access to custom service endpoints.
  final Service service;

  /// Provides local storage capabilities.
  final Storage storage;

  /// Private constructor used internally by the factory constructor.
  Calljmp._(
    this.integrity,
    this.users,
    this.project,
    this.database,
    this.service,
    this.storage,
  );

  /// Creates a new Calljmp client instance with the specified configuration.
  ///
  /// ## Parameters
  ///
  /// - [projectUrl]: Custom project URL override (optional)
  /// - [serviceUrl]: Custom service URL override (optional)
  /// - [service]: Service configuration for custom endpoints
  /// - [android]: Android-specific configuration including cloud project number
  /// - [development]: Development mode configuration for testing
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Basic initialization
  /// final calljmp = Calljmp();
  ///
  /// // With Android configuration
  /// final calljmp = Calljmp(
  ///   android: AndroidConfig(cloudProjectNumber: '123456789'),
  /// );
  ///
  /// // Development mode
  /// final calljmp = Calljmp(
  ///   development: DevelopmentConfig(
  ///     enabled: true,
  ///     baseUrl: 'https://dev.calljmp.com',
  ///   ),
  /// );
  /// ```
  factory Calljmp({
    String? projectUrl,
    String? serviceUrl,
    ServiceConfig? service,
    AndroidConfig? android,
    DevelopmentConfig? development,
  }) {
    final baseUrl =
        (development?.enabled == true ? development?.baseUrl : null) ??
        "https://api.calljmp.com";

    final config = Config(
      serviceUrl: "$baseUrl/target/v1",
      projectUrl: "$baseUrl/project",
      service: service,
      android: android,
      development: development,
    );

    final attestation = Attestation(
      cloudProjectNumber: config.android?.cloudProjectNumber,
    );
    final integrity = Integrity(config, attestation);

    return Calljmp._(
      integrity,
      Users(config, attestation),
      Project(config, attestation),
      Database(config),
      Service(config, integrity),
      Storage(config),
    );
  }
}
