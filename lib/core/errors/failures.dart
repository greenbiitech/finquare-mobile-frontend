import 'package:equatable/equatable.dart';

/// Base failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server-side failure
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
  });
}

/// Network connectivity failure
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
  });
}

/// Cache/local storage failure
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache error occurred',
  });
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
  });
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed',
  });
}

/// Unknown/unexpected failure
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred',
  });
}
