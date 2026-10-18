import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Generic use case contract.
/// [Type] is the success return type, [Params] is the input.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Marker class for use cases that take no parameters.
class NoParams {
  const NoParams();
}
