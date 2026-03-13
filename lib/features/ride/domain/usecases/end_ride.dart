import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/ride/domain/entities/ride.dart';
import 'package:saferide/features/ride/domain/repositories/ride_repository.dart';

class EndRide {
  final RideRepository _repository;

  const EndRide(this._repository);

  Future<Either<Failure, Ride>> call({
    required String userId,
    required String rideId,
    int? userRating,
  }) async {
    return await _repository.endRide(
      userId: userId,
      rideId: rideId,
      userRating: userRating,
    );
  }
}
