import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/ride/domain/repositories/ride_repository.dart';

/// Compares the current GPS position against the
/// expected route for a ride. Returns the deviation
/// distance in kilometres.
class CheckRouteDeviation {
  final RideRepository _repository;

  const CheckRouteDeviation(this._repository);

  /// Returns [Right] with the deviation distance (km).
  /// A value of 0.0 means the rider is on route.
  Future<Either<Failure, double>> call({
    required String userId,
    required String rideId,
    required double currentLatitude,
    required double currentLongitude,
  }) async {
    return await _repository.checkRouteDeviation(
      userId: userId,
      rideId: rideId,
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
    );
  }
}
