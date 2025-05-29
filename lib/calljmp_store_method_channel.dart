/// Method channel implementation of secure storage for the Calljmp SDK.
///
/// This module provides a method channel-based implementation of the
/// CalljmpStore interface that communicates with platform-specific
/// native code for secure storage operations.
///
/// ## Features
///
/// - Method channel communication with native platforms
/// - In-memory caching for performance optimization
/// - Platform-specific secure storage (Keychain on iOS, Encrypted SharedPreferences on Android)
/// - Automatic cache management
///
/// ## Platform Support
///
/// - iOS: Uses Keychain Services via native Swift/Objective-C code
/// - Android: Uses Encrypted SharedPreferences via native Kotlin/Java code
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'calljmp_store_interface.dart';

/// An implementation of [CalljmpStore] that uses method channels and caching.
///
/// This class provides the default implementation for secure storage operations
/// by communicating with platform-specific native code through Flutter's
/// method channel system. It includes an in-memory cache to optimize
/// performance for frequently accessed values.
///
/// ## Caching Strategy
///
/// Values are cached in memory after the first retrieval to reduce
/// native calls and improve performance. The cache is automatically
/// updated when values are stored or deleted.
///
/// ## Usage
///
/// This class is typically used automatically as the default implementation
/// and doesn't need to be instantiated directly.
///
/// ```dart
/// // Used automatically through CalljmpStore.instance
/// final token = await CalljmpStore.instance.get(
///   CalljmpStoreKey.accessToken
/// );
/// ```
class MethodChannelCalljmpStore extends CalljmpStore {
  /// The method channel used to interact with the native platform.
  ///
  /// This channel handles communication between Dart code and
  /// platform-specific native implementations for secure storage.
  @visibleForTesting
  final methodChannel = const MethodChannel('calljmp_store');

  /// In-memory cache for store values.
  ///
  /// This cache improves performance by avoiding repeated native calls
  /// for the same storage keys. Values are cached after retrieval
  /// and updated when stored or deleted.
  final Map<CalljmpStoreKey, String?> _cache = {};

  /// Retrieves a value from secure storage with caching.
  ///
  /// This method first checks the in-memory cache for the requested key.
  /// If not found in cache, it calls the native platform implementation
  /// and caches the result for future use.
  ///
  /// [key] The storage key to retrieve the value for.
  ///
  /// Returns a Future that resolves to the stored value, or null if not found.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final token = await store.get(CalljmpStoreKey.accessToken);
  /// if (token != null) {
  ///   print('Access token found: ${token.substring(0, 10)}...');
  /// }
  /// ```
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

  /// Stores a value in secure storage and updates the cache.
  ///
  /// This method calls the native platform implementation to securely
  /// store the value and then updates the in-memory cache.
  ///
  /// [key] The storage key to store the value under.
  /// [value] The value to store securely.
  ///
  /// Returns a Future that completes when the value is stored.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await store.put(
  ///   CalljmpStoreKey.accessToken,
  ///   'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  /// );
  /// ```
  @override
  Future<void> put(CalljmpStoreKey key, String value) async {
    await methodChannel.invokeMethod("securePut", {
      "key": key.name,
      "value": value,
    });
    _cache[key] = value;
  }

  /// Deletes a value from secure storage and removes it from cache.
  ///
  /// This method calls the native platform implementation to delete
  /// the stored value and removes it from the in-memory cache.
  ///
  /// [key] The storage key to delete.
  ///
  /// Returns a Future that completes when the value is deleted.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await store.delete(CalljmpStoreKey.accessToken);
  /// ```
  @override
  Future<void> delete(CalljmpStoreKey key) async {
    await methodChannel.invokeMethod("secureDelete", {"key": key.name});
    _cache.remove(key);
  }
}
