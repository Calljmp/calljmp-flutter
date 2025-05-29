/// Configuration for custom service endpoints.
///
/// Used to specify a custom base URL for service requests when using
/// your own deployed service instance.
///
/// ## Example
///
/// ```dart
/// final config = ServiceConfig(baseUrl: 'https://my-service.com');
/// ```
typedef ServiceConfig = ({String? baseUrl});

/// Android-specific configuration options.
///
/// Contains Android platform specific settings required for Play Integrity
/// attestation and device verification.
///
/// ## Example
///
/// ```dart
/// final config = AndroidConfig(cloudProjectNumber: 123456789);
/// ```
typedef AndroidConfig = ({int? cloudProjectNumber});

/// Development environment configuration.
///
/// Used to configure the SDK for development and testing environments.
/// When enabled, allows overriding API endpoints and using custom tokens.
///
/// ## Example
///
/// ```dart
/// final config = DevelopmentConfig(
///   enabled: true,
///   baseUrl: 'https://dev.calljmp.com',
///   apiToken: 'dev-token-123',
/// );
/// ```
typedef DevelopmentConfig = ({
  bool? enabled,
  String? baseUrl,
  String? apiToken,
});

/// SDK configuration options for Calljmp Flutter SDK.
///
/// This class contains all the configuration parameters needed to initialize
/// and customize the behavior of the Calljmp SDK. It includes URLs for
/// project and service endpoints, as well as platform-specific and
/// development configuration options.
class Config {
  /// The URL of the Calljmp project endpoint.
  ///
  /// This URL is used for project-related API calls such as retrieving
  /// project configuration and metadata.
  final String projectUrl;

  /// The URL of the Calljmp service endpoint.
  ///
  /// This URL is used for all service-related API calls including
  /// database operations, user management, and custom endpoints.
  final String serviceUrl;

  /// Optional service configuration for custom endpoints.
  ///
  /// When provided, allows overriding the default service URL with
  /// a custom deployment.
  final ServiceConfig? service;

  /// Android-specific configuration options.
  ///
  /// Contains settings required for Android Play Integrity attestation,
  /// including the cloud project number.
  final AndroidConfig? android;

  /// Development environment configuration.
  ///
  /// When provided, enables development mode with custom endpoints
  /// and authentication tokens for testing purposes.
  final DevelopmentConfig? development;

  /// Creates a new instance of the [Config] class.
  ///
  /// ## Parameters
  ///
  /// - [projectUrl]: The Calljmp project endpoint URL
  /// - [serviceUrl]: The Calljmp service endpoint URL
  /// - [service]: Optional custom service configuration
  /// - [android]: Optional Android-specific settings
  /// - [development]: Optional development environment settings
  const Config({
    required this.projectUrl,
    required this.serviceUrl,
    this.service,
    this.android,
    this.development,
  });
}
