import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/ride/domain/entities/ride.dart';
import 'package:saferide/features/ride/domain/entities/route_point.dart';

abstract class RideRepository {
  /// Start a new ride for the given user.
  /// Returns the created [Ride] on success.
  Future<Either<Failure, Ride>> startRide({
    required String userId,
    required double startLatitude,
    required double startLongitude,
    String? startAddress,
    double? endLatitude,
    double? endLongitude,
    String? endAddress,
    List<({double lat, double lon})> expectedRoute,
  });

  /// End an active ride. Calculates duration and
  /// distance, sets status to [RideStatus.completed].
  Future<Either<Failure, Ride>> endRide({
    required String userId,
    required String rideId,
    int? userRating,
  });

  /// Fetch paginated ride history for a user,
  /// ordered by most recent first.
  Future<Either<Failure, List<Ride>>> getRideHistory({
    required String userId,
    int limit,
    DateTime? startAfter,
  });

  /// Fetch a single ride by ID.
  Future<Either<Failure, Ride>> getRide({
    required String userId,
    required String rideId,
  });

  /// Add a GPS route point to the ride's location
  /// trail and update live tracking.
  Future<Either<Failure, void>> addRoutePoint({
    required String userId,
    required String rideId,
    required RoutePoint point,
  });

  /// Get all route points for a ride.
  Future<Either<Failure, List<RoutePoint>>> getRoutePoints({
    required String userId,
    required String rideId,
  });

  /// Compare the current position against the expected
  /// route. Returns the deviation distance in km.
  Future<Either<Failure, double>> checkRouteDeviation({
    required String userId,
    required String rideId,
    required double currentLatitude,
    required double currentLongitude,
  });
}
