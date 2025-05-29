/// Enumeration of service error codes used throughout the Calljmp SDK.
///
/// Each error code represents a specific type of error that can occur
/// when interacting with the Calljmp service. The numeric values correspond
/// to the error codes returned by the backend service.
///
/// Error codes are grouped by category:
/// - 1000-1999: General HTTP errors
/// - 2000-2999: User-related errors
/// - 3000-3999: Usage and quota errors
enum ServiceErrorCode {
  /// Internal server error (1000).
  ///
  /// Indicates an unexpected error occurred on the server side.
  internal(1000),

  /// Resource not found error (1001).
  ///
  /// The requested resource does not exist or is not accessible.
  notFound(1001),

  /// Unauthorized access error (1002).
  ///
  /// The request lacks valid authentication credentials.
  unauthorized(1002),

  /// Bad request error (1003).
  ///
  /// The request is malformed or contains invalid parameters.
  badRequest(1003),

  /// Forbidden access error (1004).
  ///
  /// The authenticated user lacks permission to access the resource.
  forbidden(1004),

  /// Too many requests error (1005).
  ///
  /// The request rate limit has been exceeded.
  tooManyRequests(1005),

  /// User already exists error (2000).
  ///
  /// Attempted to create a user that already exists in the system.
  userAlreadyExists(2000),

  /// User not found error (2001).
  ///
  /// The specified user does not exist in the system.
  userNotFound(2001),

  /// Usage exceeded error (3000).
  ///
  /// The account has exceeded its usage quota or limits.
  usageExceeded(3000);

  /// The numeric error code value.
  final int value;

  /// Creates a ServiceErrorCode with the specified numeric value.
  const ServiceErrorCode(this.value);

  /// Returns a ServiceErrorCode from its numeric value.
  ///
  /// If no matching error code is found, returns [ServiceErrorCode.internal].
  ///
  /// [value] The numeric error code to convert.
  ///
  /// Returns the corresponding ServiceErrorCode or internal if not found.
  static ServiceErrorCode? fromValue(int value) {
    return ServiceErrorCode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ServiceErrorCode.internal,
    );
  }
}

/// Exception class for service-related errors in the Calljmp SDK.
///
/// ServiceError encapsulates both a human-readable error message and
/// a specific error code that can be used for programmatic error handling.
///
/// ## Usage
///
/// ```dart
/// try {
///   await calljmp.users.get('user_id');
/// } catch (e) {
///   if (e is ServiceError) {
///     switch (e.code) {
///       case ServiceErrorCode.notFound:
///         print('User not found');
///         break;
///       case ServiceErrorCode.unauthorized:
///         print('Authentication required');
///         break;
///       default:
///         print('Error: ${e.message}');
///     }
///   }
/// }
/// ```
class ServiceError implements Exception {
  /// The human-readable error message.
  final String message;

  /// The specific error code indicating the type of error.
  final ServiceErrorCode code;

  /// Creates a ServiceError with the specified message and code.
  ///
  /// [message] A human-readable description of the error.
  /// [code] The specific error code type.
  ServiceError(this.message, this.code);

  /// Creates a ServiceError from a ServiceErrorCode with a default message.
  ///
  /// This factory provides standard error messages for common error codes.
  ///
  /// [code] The error code to create a ServiceError for.
  ///
  /// Returns a ServiceError with an appropriate default message.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final error = ServiceError.fromCode(ServiceErrorCode.notFound);
  /// print(error.message); // "Not found"
  /// ```
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

  /// Creates a ServiceError from a JSON response.
  ///
  /// Parses the error information from a service response and creates
  /// the appropriate ServiceError instance.
  ///
  /// [json] A map containing 'message' and 'code' fields.
  ///
  /// Returns a ServiceError parsed from the JSON data.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final json = {'message': 'User not found', 'code': 2001};
  /// final error = ServiceError.fromJson(json);
  /// ```
  factory ServiceError.fromJson(Map<String, dynamic> json) {
    final code =
        ServiceErrorCode.fromValue(json['code'] as int) ??
        ServiceErrorCode.internal;
    return ServiceError(json['message'] as String, code);
  }

  /// Returns the HTTP status code associated with this error.
  ///
  /// Maps ServiceErrorCode values to their corresponding HTTP status codes
  /// for easier integration with HTTP-based error handling.
  ///
  /// Returns the appropriate HTTP status code (400-500 range).
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

  /// Converts this ServiceError to a JSON representation.
  ///
  /// Creates a map suitable for serialization containing the error
  /// message and numeric error code.
  ///
  /// Returns a map with 'message' and 'code' fields.
  Map<String, dynamic> toJson() {
    return {'message': message, 'code': code.value};
  }

  /// Returns a string representation of this ServiceError.
  ///
  /// The format is: ServiceError(message, code: numeric_code)
  @override
  String toString() => 'ServiceError($message, code: ${code.value})';
}
