import 'package:dartz/dartz.dart';
import 'package:finsquare_mobile_app/core/errors/failures.dart';

/// Base use case interface
/// [T] is the return type
/// [Params] is the parameter type
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use this when the use case doesn't need any parameters
class NoParams {
  const NoParams();
}
