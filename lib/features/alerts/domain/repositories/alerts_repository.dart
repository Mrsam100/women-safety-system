import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/alerts/domain/entities/alert_config.dart';

/// Abstract repository defining operations for
/// automated alert checks during an active ride.
abstract class AlertsRepository {
  /// Check if the rider has deviated from the expected
  /// route. Returns the deviation distance in km.
  Future<Either<Failure, double>> checkRouteDeviation({
    required String userId,
    required String rideId,
    required double currentLatitude,
    required double currentLongitude,
    required List<({double lat, double lon})>
        expectedRoute,
  });

  /// Check for speed anomalies. Returns `true` if a
  /// speed anomaly is detected (excessive speed or
  /// prolonged stop in isolated area at night).
  Future<Either<Failure, bool>> checkSpeedAnomaly({
    required double currentLatitude,
    required double currentLongitude,
    required double speedKmh,
    required DateTime timestamp,
    required double previousLatitude,
    required double previousLongitude,
    required DateTime previousTimestamp,
  });

  /// Check for low battery conditions. Returns `true`
  /// if the battery is below the configured threshold.
  Future<Either<Failure, bool>> checkLowBattery({
    required String userId,
    required int batteryLevel,
    required int threshold,
  });

  /// Fetch the user's alert configuration from
  /// Firestore.
  Future<Either<Failure, AlertConfig>> getAlertConfig({
    required String userId,
  });

  /// Update the user's alert configuration in
  /// Firestore.
  Future<Either<Failure, AlertConfig>> updateAlertConfig({
    required String userId,
    required AlertConfig config,
  });
}
