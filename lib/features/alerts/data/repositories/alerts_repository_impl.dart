import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/utils/distance_calculator.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/alerts/data/datasources/alerts_remote_datasource.dart';
import 'package:saferide/features/alerts/data/models/alert_config_model.dart';
import 'package:saferide/features/alerts/domain/entities/alert_config.dart';
import 'package:saferide/features/alerts/domain/repositories/alerts_repository.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  final AlertsRemoteDatasource _remoteDatasource;

  static const _tag = 'AlertsRepositoryImpl';

  AlertsRepositoryImpl({
    required AlertsRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, double>> checkRouteDeviation({
    required String userId,
    required String rideId,
    required double currentLatitude,
    required double currentLongitude,
    required List<({double lat, double lon})>
        expectedRoute,
  }) async {
    try {
      if (expectedRoute.isEmpty) {
        return const Right(0.0);
      }

      final deviation =
          DistanceCalculator.distanceToRoute(
        currentLatitude,
        currentLongitude,
        expectedRoute,
      );

      return Right(deviation);
    } catch (e) {
      AppLogger.error(
        'Route deviation check failed',
        tag: _tag,
        error: e,
      );
      return Left(
        LocationFailure(
          message: 'Route deviation check failed: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> checkSpeedAnomaly({
    required double currentLatitude,
    required double currentLongitude,
    required double speedKmh,
    required DateTime timestamp,
    required double previousLatitude,
    required double previousLongitude,
    required DateTime previousTimestamp,
  }) async {
    try {
      // Delegate speed calculation to the use case
      // layer — this repository just confirms the
      // raw speed value.
      final calculatedSpeed =
          DistanceCalculator.calculateSpeed(
        previousLatitude,
        previousLongitude,
        currentLatitude,
        currentLongitude,
        timestamp
            .difference(previousTimestamp)
            .inSeconds,
      );

      return Right(calculatedSpeed > speedKmh);
    } catch (e) {
      AppLogger.error(
        'Speed anomaly check failed',
        tag: _tag,
        error: e,
      );
      return Left(
        LocationFailure(
          message: 'Speed anomaly check failed: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> checkLowBattery({
    required String userId,
    required int batteryLevel,
    required int threshold,
  }) async {
    try {
      return Right(batteryLevel <= threshold);
    } catch (e) {
      AppLogger.error(
        'Low battery check failed',
        tag: _tag,
        error: e,
      );
      return Left(
        ServerFailure(
          message: 'Low battery check failed: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, AlertConfig>> getAlertConfig({
    required String userId,
  }) async {
    try {
      final model =
          await _remoteDatasource.getAlertConfig(
        userId: userId,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, AlertConfig>> updateAlertConfig({
    required String userId,
    required AlertConfig config,
  }) async {
    try {
      final model = AlertConfigModel.fromEntity(config);
      final updated =
          await _remoteDatasource.updateAlertConfig(
        userId: userId,
        config: model,
      );
      return Right(updated.toEntity());
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: e.message,
          code: e.code,
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
