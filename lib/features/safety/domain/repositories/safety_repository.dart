import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/safety/domain/entities/alert.dart';

abstract class SafetyRepository {
  /// Triggers a full panic sequence: GPS, audio, SMS,
  /// Firestore alert, push, live tracking update.
  Future<Either<Failure, Alert>> triggerPanic({
    required String userId,
    required String rideId,
  });

  /// Triggers a fake incoming call with optional delay.
  Future<Either<Failure, void>> triggerFakeCall({
    Duration delay = Duration.zero,
  });

  /// Creates an alert record in Firestore (or queues
  /// offline).
  Future<Either<Failure, Alert>> createAlert(Alert alert);

  /// Retrieves all alerts for a given user and ride.
  Future<Either<Failure, List<Alert>>> getAlerts({
    required String userId,
    required String rideId,
  });
}
