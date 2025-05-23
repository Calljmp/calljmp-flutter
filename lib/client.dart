import 'package:calljmp/attestation.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/integrity.dart';
import 'package:calljmp/users/users.dart';

class Calljmp {
  final Integrity integrity;
  final Users users;

  Calljmp._(this.integrity, this.users);

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

    return Calljmp._(
      Integrity(config, attestation),
      Users(config, attestation),
    );
  }
}
