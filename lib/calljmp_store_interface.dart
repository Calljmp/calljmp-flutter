import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'calljmp_store_method_channel.dart';

abstract class CalljmpStore extends PlatformInterface {
  /// Constructs a CalljmpPlatform.
  CalljmpStore() : super(token: _token);

  static final Object _token = Object();

  static CalljmpStore _instance = MethodChannelCalljmpStore();

  /// The default instance of [CalljmpStore] to use.
  ///
  /// Defaults to [MethodChannelCalljmpStore].
  static CalljmpStore get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CalljmpStore] when
  /// they register themselves.
  static set instance(CalljmpStore instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> secureGet(String keyId) {
    throw UnimplementedError('secureGet() has not been implemented.');
  }

  Future<void> securePut(String keyId, String value) {
    throw UnimplementedError('securePut() has not been implemented.');
  }

  Future<void> secureDelete(String keyId) {
    throw UnimplementedError('secureDelete() has not been implemented.');
  }
}
