import 'dart:convert';
import 'dart:io';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/error.dart';
import 'package:http/http.dart' as http;
export 'package:http/http.dart' show MultipartFile, ByteStream;
export 'package:http_parser/http_parser.dart' show MediaType;

typedef HttpMiddleware =
    Future<http.StreamedResponse> Function(
      http.BaseRequest request,
      Future<http.StreamedResponse> Function(http.BaseRequest) next,
    );

class HttpClient extends http.BaseClient {
  final http.Client _inner;
  final List<HttpMiddleware> _middlewares = [];

  HttpClient(this._inner);

  HttpClient use(List<HttpMiddleware> middleware) {
    _middlewares.addAll(middleware);
    return this;
  }

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

HttpMiddleware context(Config config) =>
    (http.BaseRequest request, next) async {
      request.headers["X-Calljmp-Platform"] = Platform.operatingSystem;

      if (config.development?.enabled == true &&
          config.development?.apiToken != null) {
        request.headers["X-Calljmp-Api-Token"] = config.development!.apiToken!;
      }

      return next(request);
    };

HttpMiddleware access() => (http.BaseRequest request, next) async {
  final accessToken = await CalljmpStore.instance.get(
    CalljmpStoreKey.accessToken,
  );
  if (accessToken != null) {
    request.headers["Authorization"] = "Bearer $accessToken";
  }

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

class FormData {
  final Map<String, Object> _fields = {};

  void addField(String key, String value) {
    _fields[key] = value;
  }

  void addFile(http.MultipartFile file) {
    _fields[file.field] = file;
  }

  Map<String, Object> get fields => Map.unmodifiable(_fields);
}

class HttpRequest {
  final List<HttpMiddleware> _middlewares = [];
  final Map<String, String> _headers = {};
  Uri _url;
  String _method = "GET";
  dynamic _body;
  bool _isMultipart = false;

  HttpRequest(this._url);

  HttpRequest use(HttpMiddleware middleware) {
    _middlewares.add(middleware);
    return this;
  }

  HttpRequest params(Map<String, dynamic> params) {
    _url = _url.replace(
      queryParameters: Map<String, dynamic>.from(_url.queryParameters)
        ..addAll(params.map((key, value) => MapEntry(key, value.toString()))),
    ); 
    return this;
  }

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

  HttpResult head() => HttpResult(this.._method = "HEAD");

  HttpResult get() => HttpResult(this.._method = "GET");

  HttpResult delete() => HttpResult(this.._method = "DELETE");

  HttpResult post([dynamic body]) => HttpResult(
    this
      .._withBody(body)
      .._method = "POST",
  );

  HttpResult put([dynamic body]) => HttpResult(
    this
      .._withBody(body)
      .._method = "PUT",
  );

  HttpResult patch([dynamic body]) => HttpResult(
    this
      .._withBody(body)
      .._method = "PATCH",
  );

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

class HttpResult {
  final HttpRequest _request;

  HttpResult(this._request);

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

  Future<http.ByteStream> stream() async {
    final response = await _request.send();
    await _checkResponse(response);
    return response.stream;
  }
}

HttpRequest request(String url) => HttpRequest(Uri.parse(url));
