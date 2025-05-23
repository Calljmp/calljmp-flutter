import 'dart:convert';
import 'dart:io';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/error.dart';
import 'package:http/http.dart' as http;

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

class HttpRequest {
  final Uri _url;
  final List<HttpMiddleware> _middlewares = [];
  final Map<String, String> _headers = {};
  String _method = "GET";
  dynamic _body;

  HttpRequest(this._url);

  HttpRequest use(HttpMiddleware middleware) {
    _middlewares.add(middleware);
    return this;
  }

  HttpRequest json(Map<String, dynamic> body) {
    _headers["Content-Type"] = "application/json";
    _body = jsonEncode(body);
    return this;
  }

  HttpResult get() => HttpResult(this.._method = "GET");

  HttpResult post() => HttpResult(this.._method = "POST");

  HttpResult put() => HttpResult(this.._method = "PUT");

  HttpResult delete() => HttpResult(this.._method = "DELETE");

  Future<http.StreamedResponse> send() async {
    final client = HttpClient(http.Client());
    try {
      final request = http.Request(_method, _url);
      request.headers.addAll(_headers);

      if (_body != null) {
        if (_body is String) {
          request.body = _body;
        } else if (_body is List) {
          request.bodyBytes = _body.cast<int>();
        } else if (_body is Map) {
          request.bodyFields = _body.cast<String, String>();
        } else {
          throw ArgumentError('Invalid request body "$_body".');
        }
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

  Future<T> json<T>([T Function(Map<String, dynamic>)? fn]) async {
    final response = await _request.send();
    final bodyBytes = await response.stream.toBytes();
    final jsonMap = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;
    if (jsonMap["error"] != null) {
      ServiceError.fromJson(jsonMap["error"]).throwError();
    }
    if (fn != null) {
      return fn(jsonMap);
    }
    return Future.value() as T;
  }
}

HttpRequest request(String url) => HttpRequest(Uri.parse(url));
