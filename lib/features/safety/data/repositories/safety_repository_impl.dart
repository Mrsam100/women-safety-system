import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/safety/data/datasources/safety_local_datasource.dart';
import 'package:saferide/features/safety/data/datasources/safety_remote_datasource.dart';
import 'package:saferide/features/safety/data/models/alert_model.dart';
import 'package:saferide/features/safety/domain/entities/alert.dart';
import 'package:saferide/features/safety/domain/repositories/safety_repository.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  final SafetyRemoteDatasource _remoteDatasource;
  final SafetyLocalDatasource _localDatasource;

  static const _tag = 'SafetyRepositoryImpl';

  const SafetyRepositoryImpl({
    required SafetyRemoteDatasource remoteDatasource,
    required SafetyLocalDatasource localDatasource,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;

  @override
  Future<Either<Failure, Alert>> triggerPanic({
    required String userId,
    required String rideId,
  }) async {
    // The actual panic orchestration is handled by the
    // TriggerPanic use case, which calls datasources
    // directly for maximum parallelism. This method
    // exists to satisfy the repository contract and can
    // be used by simpler callers.
    try {
      final alert = Alert(
        id: '${userId}_${rideId}_${DateTime.now().millisecondsSinceEpoch}',
        type: AlertType.panic,
        severity: AlertSeverity.critical,
        latitude: 0.0,
        longitude: 0.0,
        threatScore: 100.0,
        timestamp: DateTime.now(),
      );

      await _remoteDatasource.createAlert(
        userId: userId,
        rideId: rideId,
        alert: alert,
      );

      return Right(alert);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      AppLogger.error(
        'triggerPanic failed',
        tag: _tag,
        error: e,
      );
      return Left(
        ServerFailure(message: 'Panic trigger failed: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> triggerFakeCall({
    Duration delay = Duration.zero,
  }) async {
    // Fake call is fully client-side; no remote
    // interaction required. The use case handles timing.
    return const Right(null);
  }

  @override
  Future<Either<Failure, Alert>> createAlert(
    Alert alert,
  ) async {
    try {
      final model = AlertModel.fromEntity(alert);
      // Attempt remote write; fall back to local queue.
      try {
        await _remoteDatasource.createAlert(
          userId: alert.details['userId'] as String? ?? '',
          rideId: alert.details['rideId'] as String? ?? '',
          alert: alert,
        );
      } on ServerException {
        await _localDatasource.queueAlert(
          userId:
              alert.details['userId'] as String? ?? '',
          rideId:
              alert.details['rideId'] as String? ?? '',
          alert: alert,
        );
      }

      return Right(alert);
    } catch (e) {
      AppLogger.error(
        'createAlert failed',
        tag: _tag,
        error: e,
      );
      return Left(
        ServerFailure(message: 'Create alert failed: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Alert>>> getAlerts({
    required String userId,
    required String rideId,
  }) async {
    try {
      final models = await _remoteDatasource.getAlerts(
        userId: userId,
        rideId: rideId,
      );

      final alerts =
          models.map((m) => m.toEntity()).toList();
      return Right(alerts);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      AppLogger.error(
        'getAlerts failed',
        tag: _tag,
        error: e,
      );
      return Left(
        ServerFailure(message: 'Fetch alerts failed: $e'),
      );
    }
  }
}
