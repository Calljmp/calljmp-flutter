import 'package:calljmp/attestation.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/database.dart';
import 'package:calljmp/integrity.dart';
import 'package:calljmp/project.dart';
import 'package:calljmp/service.dart';
import 'package:calljmp/storage.dart';
import 'package:calljmp/users/users.dart';

class Calljmp {
  final Integrity integrity;
  final Users users;
  final Project project;
  final Database database;
  final Service service;
  final Storage storage;

  Calljmp._(
    this.integrity,
    this.users,
    this.project,
    this.database,
    this.service,
    this.storage,
  );

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
