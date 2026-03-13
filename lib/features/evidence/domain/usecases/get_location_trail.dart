import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/evidence/domain/entities/location_trail.dart';
import 'package:saferide/features/evidence/domain/repositories/evidence_repository.dart';

class GetLocationTrail {
  final EvidenceRepository _repository;

  const GetLocationTrail(this._repository);

  /// Fetches the location trail for a given ride.
  /// Returns cached data if available, otherwise
  /// fetches from Firestore.
  Future<Either<Failure, LocationTrail>> call(
    String rideId,
  ) async {
    if (rideId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Ride ID cannot be empty',
        ),
      );
    }

    return await _repository.getLocationTrail(rideId);
  }
}
