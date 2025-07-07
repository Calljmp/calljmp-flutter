import 'dart:io';

import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/config.dart';

Future<Map<String, String>> aggregateContext(Config config) async {
  final result = <String, String>{};
  result['X-Calljmp-Platform'] = Platform.operatingSystem;

  if (config.development?.enabled == true &&
      config.development?.apiToken != null) {
    result['X-Calljmp-Api-Token'] = config.development!.apiToken!;
  }

  return result;
}

Future<Map<String, String>> aggregateAccess() async {
  final result = <String, String>{};

  final accessToken = await CalljmpStore.instance.get(
    CalljmpStoreKey.accessToken,
  );
  if (accessToken != null) {
    result['Authorization'] = "Bearer $accessToken";
  }

  return result;
}

Future<Map<String, String>> aggregate(Config config) async {
  final context = await aggregateContext(config);
  final access = await aggregateAccess();
  return {...context, ...access};
}
