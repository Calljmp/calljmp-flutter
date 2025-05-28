enum ServiceErrorCode {
  internal(1000),
  notFound(1001),
  unauthorized(1002),
  badRequest(1003),
  forbidden(1004),
  tooManyRequests(1005),
  userAlreadyExists(2000),
  userNotFound(2001),
  usageExceeded(3000);

  final int value;
  const ServiceErrorCode(this.value);

  static ServiceErrorCode? fromValue(int value) {
    return ServiceErrorCode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ServiceErrorCode.internal,
    );
  }
}

class ServiceError implements Exception {
  final String message;
  final ServiceErrorCode code;

  ServiceError(this.message, this.code);

  factory ServiceError.fromCode(ServiceErrorCode code) {
    switch (code) {
      case ServiceErrorCode.notFound:
        return ServiceError('Not found', code);
      case ServiceErrorCode.unauthorized:
        return ServiceError('Unauthorized', code);
      case ServiceErrorCode.badRequest:
        return ServiceError('Bad request', code);
      case ServiceErrorCode.forbidden:
        return ServiceError('Forbidden', code);
      case ServiceErrorCode.tooManyRequests:
        return ServiceError('Too many requests', code);
      case ServiceErrorCode.internal:
      default:
        return ServiceError('Internal error', code);
    }
  }

  factory ServiceError.fromJson(Map<String, dynamic> json) {
    final code =
        ServiceErrorCode.fromValue(json['code'] as int) ??
        ServiceErrorCode.internal;
    return ServiceError(json['message'] as String, code);
  }

  int get statusCode {
    switch (code) {
      case ServiceErrorCode.notFound:
        return 404;
      case ServiceErrorCode.unauthorized:
        return 401;
      case ServiceErrorCode.badRequest:
        return 400;
      case ServiceErrorCode.forbidden:
        return 403;
      case ServiceErrorCode.tooManyRequests:
        return 429;
      case ServiceErrorCode.internal:
      default:
        return 500;
    }
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'code': code.value};
  }

  @override
  String toString() => 'ServiceError($message, code: ${code.value})';
}
