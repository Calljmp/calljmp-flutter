import 'package:calljmp/access.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/integrity.dart';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/http.dart' as http;

/// Provides access to custom service endpoints.
///
/// The Service class allows you to interact with your own custom service
/// endpoints deployed alongside your Calljmp backend. This enables you to
/// extend the core Calljmp functionality with your own business logic
/// while maintaining the same authentication and security model.
///
/// ## Usage
///
/// ```dart
/// final calljmp = Calljmp();
///
/// // Simple GET request
/// final message = await calljmp.service
///   .request(route: '/hello')
///   .get()
///   .json((json) => json['message'] as String);
///
/// // POST request with data
/// final result = await calljmp.service
///   .request(route: '/api/orders')
///   .post({'product_id': 123, 'quantity': 2})
///   .json((json) => json);
///
/// // Custom headers and authentication
/// final data = await calljmp.service
///   .request(route: '/api/protected')
///   .header('X-Custom-Header', 'value')
///   .get()
///   .json((json) => json);
/// ```
///
/// ## Service Development
///
/// Your custom service endpoints are implemented as part of your Calljmp
/// deployment and have access to the same database, user context, and
/// security features as the core Calljmp APIs.
class Service {
  final Config _config;
  final Integrity _integrity;

  /// Creates a new Service instance.
  ///
  /// This constructor is typically called internally by the Calljmp client
  /// and should not be used directly in application code.
  ///
  /// ## Parameters
  ///
  /// - [_config]: The SDK configuration containing API endpoints and settings
  /// - [_integrity]: The integrity service for device verification
  Service(this._config, this._integrity);

  /// Gets the base URL for service requests.
  ///
  /// This property returns the appropriate service URL based on the current
  /// configuration. In development mode with a custom service URL, it returns
  /// the custom URL. Otherwise, it returns the standard service endpoint.
  ///
  /// ## Returns
  ///
  /// The base URL string for service requests
  String get url {
    if (_config.development?.enabled == true &&
        _config.service?.baseUrl != null) {
      return _config.service!.baseUrl!;
    }
    return "${_config.serviceUrl}/service";
  }

  /// Retrieves and validates the current access token.
  ///
  /// This method handles access token management including retrieval from
  /// local storage, validation, and automatic refresh through device integrity
  /// verification when needed.
  ///
  /// ## Returns
  ///
  /// A Future that resolves to a valid AccessToken
  ///
  /// ## Throws
  ///
  /// - [Exception] if unable to retrieve or validate the access token
  /// - [Exception] if the token is expired or invalid
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   final token = await calljmp.service.accessToken();
  ///   print('Access token expires at: ${token.expiresAt}');
  /// } catch (e) {
  ///   print('Failed to get access token: $e');
  /// }
  /// ```
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

  /// Creates a configured HTTP request for a service endpoint.
  ///
  /// This method creates an HTTP request object that is pre-configured with
  /// the correct base URL, authentication context, and access token handling.
  /// You can then use the returned request object to make GET, POST, PUT,
  /// DELETE, or other HTTP requests.
  ///
  /// ## Parameters
  ///
  /// - [route]: The service route to request (defaults to '/')
  ///
  /// ## Returns
  ///
  /// An HttpRequest object ready for making HTTP calls
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // GET request
  /// final response = await calljmp.service
  ///   .request(route: '/api/users')
  ///   .get()
  ///   .json((json) => json);
  ///
  /// // POST request
  /// final created = await calljmp.service
  ///   .request(route: '/api/posts')
  ///   .post({
  ///     'title': 'My Post',
  ///     'content': 'Post content here',
  ///   })
  ///   .json((json) => json);
  ///
  /// // PUT request with custom headers
  /// final updated = await calljmp.service
  ///   .request(route: '/api/posts/123')
  ///   .header('Content-Type', 'application/json')
  ///   .put({'title': 'Updated Title'})
  ///   .json((json) => json);
  ///
  /// // DELETE request
  /// await calljmp.service
  ///   .request(route: '/api/posts/123')
  ///   .delete();
  /// ```
  http.HttpRequest request({String route = '/'}) {
    final sanitizedRoute = route.replaceFirst(RegExp(r'^/'), '');
    return http
        .request('$url/$sanitizedRoute')
        .use(http.context(_config))
        .use(http.access());
  }
}
