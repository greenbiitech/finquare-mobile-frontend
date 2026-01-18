/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// Server exception
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
  });
}

/// Network exception
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
  });
}

/// Cache exception
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error occurred',
  });
}

/// Unauthorized exception
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Unauthorized access',
    super.statusCode = 401,
  });
}
