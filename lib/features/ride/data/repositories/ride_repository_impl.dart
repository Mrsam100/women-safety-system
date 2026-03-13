import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/services/connectivity_service.dart';
import 'package:saferide/core/utils/distance_calculator.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/ride/data/datasources/ride_local_datasource.dart';
import 'package:saferide/features/ride/data/datasources/ride_remote_datasource.dart';
import 'package:saferide/features/ride/data/models/ride_model.dart';
import 'package:saferide/features/ride/data/models/route_point_model.dart';
import 'package:saferide/features/ride/domain/entities/ride.dart';
import 'package:saferide/features/ride/domain/entities/route_point.dart';
import 'package:saferide/features/ride/domain/repositories/ride_repository.dart';

class RideRepositoryImpl implements RideRepository {
  final RideRemoteDatasource _remoteDatasource;
  final RideLocalDatasource _localDatasource;
  final ConnectivityService _connectivity;

  static const _tag = 'RideRepositoryImpl';

  RideRepositoryImpl({
    required RideRemoteDatasource remoteDatasource,
    required RideLocalDatasource localDatasource,
    required ConnectivityService connectivity,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource,
        _connectivity = connectivity;

  @override
  Future<Either<Failure, Ride>> startRide({
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
    try {
      final now = DateTime.now();
      final rideId = '${userId}_${now.millisecondsSinceEpoch}';

      final model = RideModel(
        id: rideId,
        userId: userId,
        status: 'active',
        startLatitude: startLatitude,
        startLongitude: startLongitude,
        startAddress: startAddress,
        endLatitude: endLatitude,
        endLongitude: endLongitude,
        endAddress: endAddress,
        expectedRoute: expectedRoute
            .map(
              (p) => <String, double>{
                'lat': p.lat,
                'lon': p.lon,
              },
            )
            .toList(),
        startedAt: now,
      );

      if (_connectivity.isOnline) {
        final created =
            await _remoteDatasource.createRide(model);
        return Right(created.toEntity());
      }

      // Queue for offline sync
      await _localDatasource.queueRideOperation(
        operationType: 'start',
        userId: userId,
        rideId: rideId,
        data: model.toJson().map(
              (k, v) => MapEntry(k, v.toString()),
            ),
      );

      AppLogger.info(
        'Ride $rideId started offline',
        tag: _tag,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, Ride>> endRide({
    required String userId,
    required String rideId,
    int? userRating,
  }) async {
    try {
      final now = DateTime.now();

      if (_connectivity.isOnline) {
        // Fetch current ride to calculate duration
        final currentRide = await _remoteDatasource
            .getRide(userId: userId, rideId: rideId);
        final durationMinutes = now
            .difference(currentRide.startedAt)
            .inMinutes;

        // Calculate total distance from route points
        final routePoints =
            await _remoteDatasource.getRoutePoints(
          userId: userId,
          rideId: rideId,
        );
        final distanceKm =
            _calculateTotalDistance(routePoints);

        final updateData = <String, dynamic>{
          'status': 'completed',
          'endedAt': Timestamp.fromDate(now),
          'durationMinutes': durationMinutes,
          'distanceKm': distanceKm,
          if (userRating != null)
            'userRating': userRating,
        };

        final updated =
            await _remoteDatasource.updateRide(
          userId: userId,
          rideId: rideId,
          data: updateData,
        );

        // Clean up live tracking
        await _remoteDatasource
            .deleteLiveTracking(rideId);

        return Right(updated.toEntity());
      }

      // Queue for offline sync
      await _localDatasource.queueRideOperation(
        operationType: 'end',
        userId: userId,
        rideId: rideId,
        data: {
          'endedAt': now.toIso8601String(),
          if (userRating != null)
            'userRating': userRating,
        },
      );

      // Return a best-effort ride entity
      return Right(
        Ride(
          id: rideId,
          userId: userId,
          status: RideStatus.completed,
          startLatitude: 0,
          startLongitude: 0,
          startedAt: now,
          endedAt: now,
          userRating: userRating,
        ),
      );
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, List<Ride>>>
      getRideHistory({
    required String userId,
    int limit = 20,
    DateTime? startAfter,
  }) async {
    try {
      final models =
          await _remoteDatasource.getRideHistory(
        userId: userId,
        limit: limit,
        startAfter: startAfter,
      );
      final rides =
          models.map((m) => m.toEntity()).toList();
      return Right(rides);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, Ride>> getRide({
    required String userId,
    required String rideId,
  }) async {
    try {
      final model = await _remoteDatasource.getRide(
        userId: userId,
        rideId: rideId,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, void>> addRoutePoint({
    required String userId,
    required String rideId,
    required RoutePoint point,
  }) async {
    try {
      final model = RoutePointModel.fromEntity(point);

      // Always cache locally first
      await _localDatasource.cacheRoutePoint(model);

      if (_connectivity.isOnline) {
        await _remoteDatasource.addRoutePoint(
          userId: userId,
          rideId: rideId,
          point: model,
        );
      } else {
        await _localDatasource.queueRideOperation(
          operationType: 'addPoint',
          userId: userId,
          rideId: rideId,
          data: model.toJson().map(
                (k, v) => MapEntry(k, v.toString()),
              ),
        );
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, List<RoutePoint>>>
      getRoutePoints({
    required String userId,
    required String rideId,
  }) async {
    try {
      final models =
          await _remoteDatasource.getRoutePoints(
        userId: userId,
        rideId: rideId,
      );
      final points =
          models.map((m) => m.toEntity()).toList();
      return Right(points);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, double>> checkRouteDeviation({
    required String userId,
    required String rideId,
    required double currentLatitude,
    required double currentLongitude,
  }) async {
    try {
      final ride = await _remoteDatasource.getRide(
        userId: userId,
        rideId: rideId,
      );

      final expectedRoute = ride.expectedRoute
          .map(
            (p) => (lat: p['lat']!, lon: p['lon']!),
          )
          .toList();

      if (expectedRoute.isEmpty) {
        return const Right(0.0);
      }

      final deviation = DistanceCalculator.distanceToRoute(
        currentLatitude,
        currentLongitude,
        expectedRoute,
      );

      return Right(deviation);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  /// Calculate total distance from a list of route
  /// point models using the Haversine formula.
  double _calculateTotalDistance(
    List<RoutePointModel> points,
  ) {
    if (points.length < 2) return 0.0;

    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += DistanceCalculator.haversine(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    return double.parse(total.toStringAsFixed(2));
  }
}
