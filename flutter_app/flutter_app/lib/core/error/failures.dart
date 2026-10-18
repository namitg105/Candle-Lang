import 'package:equatable/equatable.dart';

/// Base failure class — all domain-layer errors extend this.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class ComputationFailure extends Failure {
  const ComputationFailure([super.message = 'Computation error occurred']);
}
