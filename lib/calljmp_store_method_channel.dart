import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'calljmp_store_interface.dart';

/// An implementation of [CalljmpStore] that uses method channels.
class MethodChannelCalljmpStore extends CalljmpStore {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('calljmp_store');

  @override
  Future<String?> secureGet(String keyId) {
    // TODO: implement secureGet
    return super.secureGet(keyId);
  }

  @override
  Future<void> securePut(String keyId, String value) {
    // TODO: implement securePut
    return super.securePut(keyId, value);
  }

  @override
  Future<void> secureDelete(String keyId) {
    // TODO: implement secureDelete
    return super.secureDelete(keyId);
  }
}
