/// HTTP client utilities for the Calljmp SDK.
///
/// This module provides a flexible HTTP client with middleware support,
/// automatic authentication handling, and service error processing.
///
/// ## Features
///
/// - Middleware-based request/response processing
/// - Automatic access token management
/// - Platform context injection
/// - Service error handling
/// - Multipart form data support
///
/// ## Example
///
/// ```dart
/// final response = await request('https://api.calljmp.com/users')
///   .params({'limit': 10})
///   .get()
///   .json();
/// ```
library;

import 'dart:convert';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/common.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/error.dart';
import 'package:http/http.dart' as http;
export 'package:http/http.dart' show MultipartFile, ByteStream;
export 'package:http_parser/http_parser.dart' show MediaType;

/// Function signature for HTTP middleware.
///
/// Middleware functions can modify requests before they are sent
/// and responses before they are processed. They follow a chain-of-responsibility
/// pattern where each middleware calls the next one in the chain.
///
/// [request] The HTTP request being processed.
/// [next] Function to call the next middleware or send the request.
///
/// Returns a Future that resolves to the HTTP response.
typedef HttpMiddleware =
    Future<http.StreamedResponse> Function(
      http.BaseRequest request,
      Future<http.StreamedResponse> Function(http.BaseRequest) next,
    );

/// HTTP client with middleware support for the Calljmp SDK.
///
/// This client extends the standard http.BaseClient to provide
/// middleware functionality for request/response processing.
/// Middleware is executed in reverse order of registration.
///
/// ## Example
///
/// ```dart
/// final client = HttpClient(http.Client())
///   .use([authMiddleware, loggingMiddleware]);
///
/// final response = await client.send(request);
/// ```
class HttpClient extends http.BaseClient {
  /// The underlying HTTP client.
  final http.Client _inner;

  /// List of middleware functions to apply to requests.
  final List<HttpMiddleware> _middlewares = [];

  /// Creates an HttpClient with the specified underlying client.
  ///
  /// [_inner] The base HTTP client to use for sending requests.
  HttpClient(this._inner);

  /// Adds middleware to this HTTP client.
  ///
  /// Middleware functions are executed in reverse order of registration
  /// (last added is executed first).
  ///
  /// [middleware] List of middleware functions to add.
  ///
  /// Returns this HttpClient for method chaining.
  HttpClient use(List<HttpMiddleware> middleware) {
    _middlewares.addAll(middleware);
    return this;
  }

  /// Sends an HTTP request through the middleware chain.
  ///
  /// The request is processed by all registered middleware
  /// before being sent by the underlying client.
  ///
  /// [request] The HTTP request to send.
  ///
  /// Returns a Future that resolves to the HTTP response.
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final chain = _middlewares.reversed
        .fold<Future<http.StreamedResponse> Function(http.BaseRequest)>(
          _inner.send,
          (next, middleware) =>
              (req) => middleware(req, next),
        );
    return chain(request);
  }
}

/// Middleware that adds platform context and API tokens to requests.
///
/// This middleware automatically adds:
/// - Platform information (iOS, Android, etc.) via X-Calljmp-Platform header
/// - Development API token if configured
///
/// [config] The Calljmp configuration containing platform and development settings.
///
/// Returns an HttpMiddleware function.
///
/// ## Example
///
/// ```dart
/// final client = HttpClient(http.Client())
///   .use([context(config)]);
/// ```
HttpMiddleware context(Config config) =>
    (http.BaseRequest request, next) async {
      final values = await aggregateContext(config);
      request.headers.addAll(values);
      return next(request);
    };

/// Middleware that handles access token authentication.
///
/// This middleware:
/// - Adds stored access tokens to requests via Authorization header
/// - Updates stored access tokens from response headers
/// - Automatically manages token refresh
///
/// Returns an HttpMiddleware function.
///
/// ## Example
///
/// ```dart
/// final client = HttpClient(http.Client())
///   .use([access()]);
/// ```
HttpMiddleware access() => (http.BaseRequest request, next) async {
  final values = await aggregateAccess();
  request.headers.addAll(values);

  final response = await next(request);

  final refreshAccessToken = response.headers["X-Calljmp-Access-Token"];
  if (refreshAccessToken != null) {
    await CalljmpStore.instance.put(
      CalljmpStoreKey.accessToken,
      refreshAccessToken,
    );
  }

  return response;
};

/// Container for multipart form data.
///
/// FormData allows you to build multipart/form-data requests
/// by adding fields and files. This is commonly used for
/// file uploads and forms with mixed content types.
///
/// ## Example
///
/// ```dart
/// final formData = FormData()
///   ..addField('name', 'John Doe')
///   ..addField('email', 'john@example.com')
///   ..addFile(await http.MultipartFile.fromPath('avatar', '/path/to/image.jpg'));
///
/// final response = await request('https://api.calljmp.com/upload')
///   .post(formData)
///   .json();
/// ```
class FormData {
  /// Internal storage for form fields and files.
  final Map<String, Object> _fields = {};

  /// Adds a text field to the form data.
  ///
  /// [key] The field name.
  /// [value] The field value as a string.
  void addField(String key, String value) {
    _fields[key] = value;
  }

  /// Adds a file to the form data.
  ///
  /// [file] The MultipartFile to add to the form.
  void addFile(http.MultipartFile file) {
    _fields[file.field] = file;
  }

  /// Returns an unmodifiable view of the form fields and files.
  ///
  /// The returned map contains both string values and MultipartFile objects.
  Map<String, Object> get fields => Map.unmodifiable(_fields);
}

/// Builder class for constructing and executing HTTP requests.
///
/// HttpRequest provides a fluent API for building HTTP requests
/// with support for middleware, query parameters, headers, and
/// various body types including JSON and multipart form data.
///
/// ## Example
///
/// ```dart
/// final request = HttpRequest(Uri.parse('https://api.calljmp.com/users'))
///   .params({'limit': 10, 'offset': 0})
///   .use(authMiddleware);
///
/// final response = await request.get().json();
/// ```
class HttpRequest {
  /// List of middleware to apply to this request.
  final List<HttpMiddleware> _middlewares = [];

  /// HTTP headers for this request.
  final Map<String, String> _headers = {};

  /// The target URL for this request.
  Uri _url;

  /// The HTTP method (GET, POST, etc.).
  String _method = "GET";

  /// The request body content.
  dynamic _body;

  /// Whether this is a multipart request.
  bool _isMultipart = false;

  /// Creates an HttpRequest for the specified URL.
  ///
  /// [_url] The target URL for the request.
  HttpRequest(this._url);

  /// Adds middleware to this request.
  ///
  /// [middleware] The middleware function to add.
  ///
  /// Returns this HttpRequest for method chaining.
  HttpRequest use(HttpMiddleware middleware) {
    _middlewares.add(middleware);
    return this;
  }

  /// Adds query parameters to the request URL.
  ///
  /// Parameters are URL-encoded and appended to the existing
  /// query string. Existing parameters with the same keys
  /// will be overwritten.
  ///
  /// [params] Map of parameter names to values.
  ///
  /// Returns this HttpRequest for method chaining.
  ///
  /// ## Example
  ///
  /// ```dart
  /// request.params({'limit': 10, 'filter': 'active'});
  /// ```
  HttpRequest params(Map<String, dynamic> params) {
    _url = _url.replace(
      queryParameters: Map<String, dynamic>.from(_url.queryParameters)
        ..addAll(params.map((key, value) => MapEntry(key, value.toString()))),
    );
    return this;
  }

  /// Sets the request body and content type.
  ///
  /// This private method handles different body types:
  /// - null: removes body and Content-Type header
  /// - `Map<String, dynamic>`: JSON-encodes and sets application/json
  /// - FormData: prepares multipart/form-data request
  ///
  /// [body] The body content to set.
  ///
  /// Returns this HttpRequest for method chaining.
  ///
  /// Throws [ArgumentError] if the body type is not supported.
  HttpRequest _withBody(dynamic body) {
    if (body == null) {
      _headers.remove("Content-Type");
      _body = null;
      _isMultipart = false;
    } else if (body is Map<String, dynamic>) {
      _headers["Content-Type"] = "application/json";
      _body = jsonEncode(body);
      _isMultipart = false;
    } else if (body is FormData) {
      _headers.remove("Content-Type");
      _body = body.fields;
      _isMultipart = true;
    } else {
      throw ArgumentError(
        'Invalid request body "$body". Expected a Map<String, dynamic> or MultipartFormData.',
      );
    }
    return this;
  }

  /// Creates an HttpResult for a HEAD request.
  ///
  /// HEAD requests are used to retrieve headers without the response body.
  ///
  /// Returns an HttpResult configured for HEAD method.
  HttpResult head() => HttpResult(this.._method = "HEAD");

  /// Creates an HttpResult for a GET request.
  ///
  /// GET requests are used to retrieve data from the server.
  ///
  /// Returns an HttpResult configured for GET method.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final users = await request('/api/users')
  ///   .params({'limit': 10})
  ///   .get()
  ///   .json<List>((json) => json['users']);
  /// ```
  HttpResult get() => HttpResult(this.._method = "GET");

  /// Creates an HttpResult for a DELETE request.
  ///
  /// DELETE requests are used to remove resources from the server.
  ///
  /// Returns an HttpResult configured for DELETE method.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await request('/api/users/123')
  ///   .delete()
  ///   .json();
  /// ```
  HttpResult delete() => HttpResult(this.._method = "DELETE");

  /// Creates an HttpResult for a POST request with optional body.
  ///
  /// POST requests are used to create new resources on the server.
  ///
  /// [body] Optional request body (Map, FormData, or null).
  ///
  /// Returns an HttpResult configured for POST method.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final user = await request('/api/users')
  ///   .post({'name': 'John', 'email': 'john@example.com'})
  ///   .json<Map>((json) => json['user']);
  /// ```
  HttpResult post([dynamic body]) => HttpResult(
    this
      .._withBody(body)
      .._method = "POST",
  );

  /// Creates an HttpResult for a PUT request with optional body.
  ///
  /// PUT requests are used to update or replace resources on the server.
  ///
  /// [body] Optional request body (Map, FormData, or null).
  ///
  /// Returns an HttpResult configured for PUT method.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final user = await request('/api/users/123')
  ///   .put({'name': 'John Updated', 'email': 'john.updated@example.com'})
  ///   .json<Map>((json) => json['user']);
  /// ```
  HttpResult put([dynamic body]) => HttpResult(
    this
      .._withBody(body)
      .._method = "PUT",
  );

  /// Creates an HttpResult for a PATCH request with optional body.
  ///
  /// PATCH requests are used to partially update resources on the server.
  ///
  /// [body] Optional request body (Map, FormData, or null).
  ///
  /// Returns an HttpResult configured for PATCH method.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final user = await request('/api/users/123')
  ///   .patch({'name': 'John Updated'})
  ///   .json<Map>((json) => json['user']);
  /// ```
  HttpResult patch([dynamic body]) => HttpResult(
    this
      .._withBody(body)
      .._method = "PATCH",
  );

  /// Sends the HTTP request and returns the raw response.
  ///
  /// This method builds the appropriate request type (regular or multipart)
  /// and sends it through the configured middleware chain.
  ///
  /// Returns a Future that resolves to the HTTP StreamedResponse.
  ///
  /// Throws various exceptions if the request fails to send.
  Future<http.StreamedResponse> send() async {
    final client = HttpClient(http.Client());
    try {
      http.BaseRequest request;

      if (_isMultipart) {
        final multipartRequest = http.MultipartRequest(_method, _url);
        multipartRequest.headers.addAll(_headers);

        if (_body != null) {
          final bodyMap = _body as Map<String, Object>;
          for (final entry in bodyMap.entries) {
            if (entry.value is http.MultipartFile) {
              multipartRequest.files.add(entry.value as http.MultipartFile);
            } else if (entry.value is String) {
              multipartRequest.fields[entry.key] = entry.value as String;
            } else {
              multipartRequest.fields[entry.key] = entry.value.toString();
            }
          }
        }

        request = multipartRequest;
      } else {
        final regularRequest = http.Request(_method, _url);
        regularRequest.headers.addAll(_headers);

        if (_body != null) {
          if (_body is String) {
            regularRequest.body = _body;
          } else if (_body is List) {
            regularRequest.bodyBytes = _body.cast<int>();
          } else if (_body is Map) {
            regularRequest.bodyFields = _body.cast<String, String>();
          } else {
            throw ArgumentError('Invalid request body "$_body".');
          }
        }
        request = regularRequest;
      }

      return client.use(_middlewares).send(request);
    } finally {
      client.close();
    }
  }
}

/// Result wrapper for HTTP requests with response processing capabilities.
///
/// HttpResult provides methods to process HTTP responses in different formats
/// while automatically handling error responses and service errors.
///
/// ## Example
///
/// ```dart
/// final result = await request('/api/users').get();
///
/// // Process as JSON with transformation
/// final users = await result.json<List>((json) => json['users']);
///
/// // Process as streaming data
/// final stream = await result.stream();
/// ```
class HttpResult {
  /// The HTTP request associated with this result.
  final HttpRequest _request;

  /// Creates an HttpResult for the specified request.
  ///
  /// [_request] The HttpRequest to execute and process.
  HttpResult(this._request);

  /// Checks the HTTP response for errors and throws ServiceError if needed.
  ///
  /// This method validates the response status code and parses error
  /// information from the response body if the request failed.
  ///
  /// [response] The HTTP response to check.
  ///
  /// Throws [ServiceError] if the response indicates an error.
  Future<void> _checkResponse(http.StreamedResponse response) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final bodyBytes = await response.stream.toBytes();
      final jsonMap =
          jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;
      if (jsonMap["error"] != null) {
        throw ServiceError.fromJson(jsonMap["error"]);
      } else {
        throw ServiceError(
          "Unexpected error: ${response.reasonPhrase}",
          ServiceErrorCode.internal,
        );
      }
    }
  }

  /// Processes the response as JSON with optional transformation.
  ///
  /// This method sends the request, validates the response, and parses
  /// the response body as JSON. An optional transformation function
  /// can be provided to convert the parsed JSON to the desired type.
  ///
  /// [fn] Optional function to transform the parsed JSON map.
  ///
  /// Returns a Future that resolves to the transformed result or void.
  ///
  /// Throws [ServiceError] if the request fails or returns an error status.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Simple JSON parsing
  /// await request('/api/users').get().json();
  ///
  /// // With transformation
  /// final users = await request('/api/users')
  ///   .get()
  ///   .json<List>((json) => json['users']);
  /// ```
  Future<T> json<T>([T Function(Map<String, dynamic>)? fn]) async {
    final response = await _request.send();
    await _checkResponse(response);
    final bodyBytes = await response.stream.toBytes();
    if (fn != null) {
      final json = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;
      return fn(json);
    }
    return Future.value() as T;
  }

  /// Processes the response as a byte stream.
  ///
  /// This method is useful for handling large responses or when you need
  /// to process the response data incrementally.
  ///
  /// Returns a Future that resolves to a ByteStream of the response body.
  ///
  /// Throws [ServiceError] if the request fails or returns an error status.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final stream = await request('/api/files/large-file')
  ///   .get()
  ///   .stream();
  ///
  /// await for (final chunk in stream) {
  ///   // Process chunk incrementally
  /// }
  /// ```
  Future<http.ByteStream> stream() async {
    final response = await _request.send();
    await _checkResponse(response);
    return response.stream;
  }
}

/// Creates an HttpRequest for the specified URL string.
///
/// This is a convenience function for creating HTTP requests without
/// having to manually parse the URL string to a Uri.
///
/// [url] The URL string to create a request for.
///
/// Returns an HttpRequest instance ready for configuration and execution.
///
/// ## Example
///
/// ```dart
/// final response = await request('https://api.calljmp.com/users')
///   .params({'limit': 10})
///   .get()
///   .json();
/// ```
HttpRequest request(String url) => HttpRequest(Uri.parse(url));
