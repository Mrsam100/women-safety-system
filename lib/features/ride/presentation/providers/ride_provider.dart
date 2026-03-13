import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/core/providers/service_providers.dart';
import 'package:saferide/core/providers/shared_providers.dart';
import 'package:saferide/core/services/battery_service.dart';
import 'package:saferide/core/services/connectivity_service.dart';
import 'package:saferide/core/services/location_service.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/ride/data/datasources/ride_local_datasource.dart';
import 'package:saferide/features/ride/data/datasources/ride_remote_datasource.dart';
import 'package:saferide/features/ride/data/repositories/ride_repository_impl.dart';
import 'package:saferide/features/ride/domain/entities/ride.dart';
import 'package:saferide/features/ride/domain/entities/route_point.dart';
import 'package:saferide/features/ride/domain/repositories/ride_repository.dart';
import 'package:saferide/features/ride/domain/usecases/check_route_deviation.dart';
import 'package:saferide/features/ride/domain/usecases/end_ride.dart';
import 'package:saferide/features/ride/domain/usecases/start_ride.dart';
import 'package:geolocator/geolocator.dart';

// ── Datasource providers ──

final rideRemoteDatasourceProvider =
    Provider<RideRemoteDatasource>((ref) {
  return RideRemoteDatasource(
    firestore: ref.watch(firestoreProvider),
  );
});

final rideLocalDatasourceProvider =
    Provider<RideLocalDatasource>((ref) {
  return RideLocalDatasource(
    localStorage:
        ref.watch(localStorageServiceProvider),
  );
});

// ── Repository provider ──

final rideRepositoryProvider =
    Provider<RideRepository>((ref) {
  return RideRepositoryImpl(
    remoteDatasource: ref.watch(
      rideRemoteDatasourceProvider,
    ),
    localDatasource: ref.watch(
      rideLocalDatasourceProvider,
    ),
    connectivity: ref.watch(
      connectivityServiceProvider,
    ),
  );
});

// ── Use case providers ──

final startRideUseCaseProvider =
    Provider<StartRide>((ref) {
  return StartRide(ref.watch(rideRepositoryProvider));
});

final endRideUseCaseProvider =
    Provider<EndRide>((ref) {
  return EndRide(ref.watch(rideRepositoryProvider));
});

final checkRouteDeviationUseCaseProvider =
    Provider<CheckRouteDeviation>((ref) {
  return CheckRouteDeviation(
    ref.watch(rideRepositoryProvider),
  );
});

// ── Ride state ──

enum RideLifecycleStatus {
  idle,
  starting,
  active,
  ending,
  ended,
  error,
}

class RideState {
  final RideLifecycleStatus status;
  final Ride? currentRide;
  final List<RoutePoint> routePoints;
  final double deviationKm;
  final String? errorMessage;

  const RideState({
    this.status = RideLifecycleStatus.idle,
    this.currentRide,
    this.routePoints = const [],
    this.deviationKm = 0.0,
    this.errorMessage,
  });

  bool get isActive =>
      status == RideLifecycleStatus.active;

  RideState copyWith({
    RideLifecycleStatus? status,
    Ride? currentRide,
    List<RoutePoint>? routePoints,
    double? deviationKm,
    String? errorMessage,
  }) {
    return RideState(
      status: status ?? this.status,
      currentRide: currentRide ?? this.currentRide,
      routePoints: routePoints ?? this.routePoints,
      deviationKm: deviationKm ?? this.deviationKm,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RideNotifier extends StateNotifier<RideState> {
  final StartRide _startRide;
  final EndRide _endRide;
  final CheckRouteDeviation _checkDeviation;
  final RideRepository _repository;
  final LocationService _locationService;
  final BatteryService _batteryService;
  final Ref _ref;

  StreamSubscription<Position>? _locationSubscription;
  Timer? _deviationTimer;

  static const _tag = 'RideNotifier';

  RideNotifier({
    required StartRide startRide,
    required EndRide endRide,
    required CheckRouteDeviation checkDeviation,
    required RideRepository repository,
    required LocationService locationService,
    required BatteryService batteryService,
    required Ref ref,
  })  : _startRide = startRide,
        _endRide = endRide,
        _checkDeviation = checkDeviation,
        _repository = repository,
        _locationService = locationService,
        _batteryService = batteryService,
        _ref = ref,
        super(const RideState());

  /// Start a new ride at the current GPS position.
  Future<void> startRide({
    required String userId,
    String? startAddress,
    double? endLatitude,
    double? endLongitude,
    String? endAddress,
    List<({double lat, double lon})> expectedRoute =
        const [],
  }) async {
    state = state.copyWith(
      status: RideLifecycleStatus.starting,
    );

    try {
      final position =
          await _locationService.getCurrentPosition();

      final result = await _startRide(
        userId: userId,
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        startAddress: startAddress,
        endLatitude: endLatitude,
        endLongitude: endLongitude,
        endAddress: endAddress,
        expectedRoute: expectedRoute,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            status: RideLifecycleStatus.error,
            errorMessage: failure.message,
          );
        },
        (ride) {
          state = state.copyWith(
            status: RideLifecycleStatus.active,
            currentRide: ride,
            routePoints: [],
            deviationKm: 0.0,
          );

          // Update shared state
          _ref.read(isRideActiveProvider.notifier)
              .state = true;
          _ref.read(activeRideIdProvider.notifier)
              .state = ride.id;

          // Start GPS tracking
          _startLocationTracking(userId, ride.id);

          // Start periodic deviation checks
          if (expectedRoute.isNotEmpty) {
            _startDeviationChecks(userId, ride.id);
          }

          AppLogger.info(
            'Ride ${ride.id} started',
            tag: _tag,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: RideLifecycleStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// End the current active ride.
  Future<void> endRide({
    required String userId,
    int? userRating,
  }) async {
    final ride = state.currentRide;
    if (ride == null) return;

    state = state.copyWith(
      status: RideLifecycleStatus.ending,
    );

    _stopLocationTracking();
    _deviationTimer?.cancel();

    final result = await _endRide(
      userId: userId,
      rideId: ride.id,
      userRating: userRating,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: RideLifecycleStatus.error,
          errorMessage: failure.message,
        );
      },
      (endedRide) {
        state = state.copyWith(
          status: RideLifecycleStatus.ended,
          currentRide: endedRide,
        );

        // Update shared state
        _ref.read(isRideActiveProvider.notifier)
            .state = false;
        _ref.read(activeRideIdProvider.notifier)
            .state = null;

        AppLogger.info(
          'Ride ${ride.id} ended',
          tag: _tag,
        );
      },
    );
  }

  /// Manually add a route point (used when receiving
  /// location updates).
  Future<void> addRoutePoint(
    RoutePoint point, {
    required String userId,
  }) async {
    final ride = state.currentRide;
    if (ride == null) return;

    final result = await _repository.addRoutePoint(
      userId: userId,
      rideId: ride.id,
      point: point,
    );

    result.fold(
      (failure) {
        AppLogger.error(
          'Failed to add route point: '
          '${failure.message}',
          tag: _tag,
        );
      },
      (_) {
        state = state.copyWith(
          routePoints: [...state.routePoints, point],
        );
      },
    );
  }

  /// Reset the notifier to idle.
  void reset() {
    _stopLocationTracking();
    _deviationTimer?.cancel();
    state = const RideState();
  }

  void _startLocationTracking(
    String userId,
    String rideId,
  ) {
    _locationService.startTracking(
      intervalMs:
          AppDimensions.locationUpdateInterval * 1000,
      distanceFilter: 5,
    );

    _locationSubscription =
        _locationService.locationStream.listen(
      (position) async {
        final batteryLevel =
            await _batteryService.getBatteryLevel();

        final point = RoutePoint(
          id: '${rideId}_${DateTime.now().millisecondsSinceEpoch}',
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          bearing: position.heading,
          accuracy: position.accuracy,
          batteryLevel: batteryLevel,
          timestamp: DateTime.now(),
        );

        await addRoutePoint(point, userId: userId);
      },
    );
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService.stopTracking();
  }

  void _startDeviationChecks(
    String userId,
    String rideId,
  ) {
    _deviationTimer = Timer.periodic(
      const Duration(
        seconds: AppDimensions.routeCheckInterval,
      ),
      (_) async {
        final lastPosition =
            _locationService.lastPosition;
        if (lastPosition == null) return;

        final result = await _checkDeviation(
          userId: userId,
          rideId: rideId,
          currentLatitude: lastPosition.latitude,
          currentLongitude: lastPosition.longitude,
        );

        result.fold(
          (failure) {
            AppLogger.error(
              'Deviation check failed: '
              '${failure.message}',
              tag: _tag,
            );
          },
          (deviation) {
            state = state.copyWith(
              deviationKm: deviation,
            );

            if (deviation >
                AppDimensions.deviationThresholdKm) {
              AppLogger.warning(
                'Route deviation detected: '
                '${deviation.toStringAsFixed(2)} km',
                tag: _tag,
              );
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _stopLocationTracking();
    _deviationTimer?.cancel();
    super.dispose();
  }
}

final rideNotifierProvider =
    StateNotifierProvider<RideNotifier, RideState>(
  (ref) {
    return RideNotifier(
      startRide: ref.watch(startRideUseCaseProvider),
      endRide: ref.watch(endRideUseCaseProvider),
      checkDeviation: ref.watch(
        checkRouteDeviationUseCaseProvider,
      ),
      repository: ref.watch(rideRepositoryProvider),
      locationService: ref.watch(
        locationServiceProvider,
      ),
      batteryService: ref.watch(
        batteryServiceProvider,
      ),
      ref: ref,
    );
  },
);
