/// Platform interface for secure storage in the Calljmp SDK.
///
/// This module defines the interface for platform-specific secure storage
/// implementations used to store sensitive data like access tokens.
///
/// ## Features
///
/// - Cross-platform storage interface
/// - Secure storage for sensitive data
/// - Plugin platform interface compliance
/// - Key-based storage operations
///
/// ## Platform Implementations
///
/// - iOS: Uses Keychain Services
/// - Android: Uses Encrypted SharedPreferences
/// - Other platforms: Uses secure storage libraries
library;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'calljmp_store_method_channel.dart';

/// Enumeration of storage keys used by the Calljmp SDK.
///
/// These keys define the types of data that can be stored
/// in the secure storage system.
enum CalljmpStoreKey {
  /// Access token for API authentication.
  accessToken,
}

/// Abstract platform interface for secure storage operations.
///
/// CalljmpStore defines the contract for platform-specific storage
/// implementations that handle sensitive data securely across different
/// platforms (iOS, Android, etc.).
///
/// ## Implementation
///
/// Platform-specific implementations should extend this class and
/// provide concrete implementations for all abstract methods.
///
/// ## Usage
///
/// ```dart
/// // Store an access token
/// await CalljmpStore.instance.put(
///   CalljmpStoreKey.accessToken,
///   'jwt_token_string'
/// );
///
/// // Retrieve an access token
/// final token = await CalljmpStore.instance.get(
///   CalljmpStoreKey.accessToken
/// );
///
/// // Delete an access token
/// await CalljmpStore.instance.delete(
///   CalljmpStoreKey.accessToken
/// );
/// ```
abstract class CalljmpStore extends PlatformInterface {
  /// Constructs a CalljmpStore platform interface.
  ///
  /// This constructor is called by platform-specific implementations
  /// to register with the platform interface system.
  CalljmpStore() : super(token: _token);

  /// Token used for platform interface verification.
  static final Object _token = Object();

  /// The current platform-specific implementation instance.
  static CalljmpStore _instance = MethodChannelCalljmpStore();

  /// The default instance of [CalljmpStore] to use.
  ///
  /// Defaults to [MethodChannelCalljmpStore] which uses method channels
  /// to communicate with platform-specific native implementations.
  static CalljmpStore get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CalljmpStore] when
  /// they register themselves.
  ///
  /// [instance] The platform-specific implementation to use.
  ///
  /// Throws [AssertionError] if the instance doesn't implement the correct interface.
  static set instance(CalljmpStore instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Retrieves a value from secure storage.
  ///
  /// [key] The storage key to retrieve the value for.
  ///
  /// Returns a Future that resolves to the stored value, or null if not found.
  ///
  /// Throws [UnimplementedError] if not implemented by platform-specific code.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final token = await CalljmpStore.instance.get(
  ///   CalljmpStoreKey.accessToken
  /// );
  /// if (token != null) {
  ///   print('Found stored token');
  /// }
  /// ```
  Future<String?> get(CalljmpStoreKey key) {
    throw UnimplementedError('get() has not been implemented.');
  }

  /// Stores a value in secure storage.
  ///
  /// [key] The storage key to store the value under.
  /// [value] The value to store securely.
  ///
  /// Returns a Future that completes when the value is stored.
  ///
  /// Throws [UnimplementedError] if not implemented by platform-specific code.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await CalljmpStore.instance.put(
  ///   CalljmpStoreKey.accessToken,
  ///   'jwt_token_string'
  /// );
  /// ```
  Future<void> put(CalljmpStoreKey key, String value) {
    throw UnimplementedError('put() has not been implemented.');
  }

  /// Deletes a value from secure storage.
  ///
  /// [key] The storage key to delete.
  ///
  /// Returns a Future that completes when the value is deleted.
  ///
  /// Throws [UnimplementedError] if not implemented by platform-specific code.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await CalljmpStore.instance.delete(
  ///   CalljmpStoreKey.accessToken
  /// );
  /// ```
  Future<void> delete(CalljmpStoreKey key) {
    throw UnimplementedError('delete() has not been implemented.');
  }
}
