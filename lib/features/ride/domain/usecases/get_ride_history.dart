import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/ride/domain/entities/ride.dart';
import 'package:saferide/features/ride/domain/repositories/ride_repository.dart';

class GetRideHistory {
  final RideRepository _repository;

  const GetRideHistory(this._repository);

  Future<Either<Failure, List<Ride>>> call({
    required String userId,
    int limit = 20,
    DateTime? startAfter,
  }) async {
    return await _repository.getRideHistory(
      userId: userId,
      limit: limit,
      startAfter: startAfter,
    );
  }
}
