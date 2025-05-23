typedef ServiceConfig = ({String? baseUrl});

typedef AndroidConfig = ({int? cloudProjectNumber});

typedef DevelopmentConfig = ({
  bool? enabled,
  String? baseUrl,
  String? apiToken,
});

/// SDK configuration options for Calljmp Flutter SDK.
class Config {
  /// The URL of the Calljmp project.
  final String projectUrl;

  /// The URL of the Calljmp service.
  final String serviceUrl;

  /// The URL of the Calljmp service.
  final ServiceConfig? service;

  /// The Android project number.
  final AndroidConfig? android;

  /// The development environment configuration.
  final DevelopmentConfig? development;

  /// Creates a new instance of the [Config] class.
  const Config({
    required this.projectUrl,
    required this.serviceUrl,
    this.service,
    this.android,
    this.development,
  });
}
