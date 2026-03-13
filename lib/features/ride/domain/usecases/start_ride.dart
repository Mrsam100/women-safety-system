import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/ride/domain/entities/ride.dart';
import 'package:saferide/features/ride/domain/repositories/ride_repository.dart';

class StartRide {
  final RideRepository _repository;

  const StartRide(this._repository);

  Future<Either<Failure, Ride>> call({
    required String userId,
    required double startLatitude,
    required double startLongitude,
    String? startAddress,
    double? endLatitude,
    double? endLongitude,
    String? endAddress,
    List<({double lat, double lon})> expectedRoute =
        const [],
  }) async {
    return await _repository.startRide(
      userId: userId,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      startAddress: startAddress,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
      endAddress: endAddress,
      expectedRoute: expectedRoute,
    );
  }
}
