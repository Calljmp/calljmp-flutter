import 'package:calljmp/access.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/integrity.dart';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/http.dart' as http;

class Service {
  final Config _config;
  final Integrity _integrity;

  Service(this._config, this._integrity);

  String get url {
    if (_config.development?.enabled == true &&
        _config.service?.baseUrl != null) {
      return _config.service!.baseUrl!;
    }
    return "${_config.serviceUrl}/service";
  }

  Future<AccessToken> accessToken() async {
    var token = await CalljmpStore.instance.get(CalljmpStoreKey.accessToken);
    if (token != null) {
      final result = AccessToken.tryParse(token);
      if (result.data != null) {
        return result.data!;
      }
      await CalljmpStore.instance.delete(CalljmpStoreKey.accessToken);
    }

    await _integrity.access();

    token = await CalljmpStore.instance.get(CalljmpStoreKey.accessToken);
    if (token == null) {
      throw Exception("Failed to retrieve access token after attestation");
    }

    final result = AccessToken.tryParse(token);
    if (result.data == null || result.error != null) {
      throw Exception("Failed to parse access token: ${result.error}");
    }

    final accessToken = result.data!;
    if (accessToken.isExpired) {
      throw Exception("Access token is expired");
    }

    return accessToken;
  }

  http.HttpRequest request({String route = '/'}) {
    final sanitizedRoute = route.replaceFirst(RegExp(r'^/'), '');
    return http
        .request('$url/$sanitizedRoute')
        .use(http.context(_config))
        .use(http.access());
  }
}
