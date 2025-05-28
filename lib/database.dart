import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;

class Database {
  final Config _config;

  Database(this._config);

  Future<({int? insertId, int? numAffectedRows, List<dynamic> rows})> query(
    String sql, [
    List<dynamic>? params,
  ]) => http
      .request("${_config.serviceUrl}/database/query")
      .use(http.context(_config))
      .use(http.access())
      .post({"sql": sql, "params": params ?? []})
      .json(
        (json) => (
          insertId: json['insertId'] as int?,
          numAffectedRows: json['numAffectedRows'] as int?,
          rows: json['rows'] as List<dynamic>,
        ),
      );
}
