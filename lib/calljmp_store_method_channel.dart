import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'calljmp_store_interface.dart';

/// An implementation of [CalljmpStore] that uses method channels and caching.
class MethodChannelCalljmpStore extends CalljmpStore {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('calljmp_store');

  /// In-memory cache for store values.
  final Map<CalljmpStoreKey, String?> _cache = {};

  @override
  Future<String?> get(CalljmpStoreKey key) async {
    if (_cache.containsKey(key)) {
      return _cache[key];
    }
    final value = await methodChannel.invokeMethod<String>("secureGet", {
      "key": key.name,
    });
    _cache[key] = value;
    return value;
  }

  @override
  Future<void> put(CalljmpStoreKey key, String value) async {
    await methodChannel.invokeMethod("securePut", {
      "key": key.name,
      "value": value,
    });
    _cache[key] = value;
  }

  @override
  Future<void> delete(CalljmpStoreKey key) async {
    await methodChannel.invokeMethod("secureDelete", {"key": key.name});
    _cache.remove(key);
  }
}
