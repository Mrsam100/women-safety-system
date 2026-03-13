import 'package:dartz/dartz.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/utils/distance_calculator.dart';
import 'package:saferide/core/utils/logger.dart';

/// Result of a route deviation check including
/// distance and whether the deviation has been
/// sustained long enough to trigger an alert.
class RouteDeviationResult {
  final double deviationKm;
  final bool shouldAlert;
  final Duration sustainedDuration;

  const RouteDeviationResult({
    required this.deviationKm,
    required this.shouldAlert,
    required this.sustainedDuration,
  });
}

/// Compare current GPS position vs expected route
/// points every 30 seconds. Alert if deviation exceeds
/// the threshold (default 1.5 km) sustained for more
/// than 2 minutes.
///
/// Maintains internal state to track how long the
/// rider has been off-route.
class CheckRouteDeviation {
  static const _tag = 'CheckRouteDeviation';

  /// Timestamp when deviation was first detected.
  DateTime? _deviationStartedAt;

  /// The last known deviation distance.
  double _lastDeviationKm = 0.0;

  /// Reset the internal deviation tracking state.
  /// Call this when a ride starts or ends.
  void reset() {
    _deviationStartedAt = null;
    _lastDeviationKm = 0.0;
  }

  /// Check if the current position deviates from the
  /// expected route beyond the configured threshold.
  ///
  /// [currentLat] / [currentLon] — rider's current
  ///   GPS coordinates.
  /// [expectedRoute] — polyline of expected route
  ///   points.
  /// [thresholdKm] — distance threshold in km
  ///   (defaults to [AppDimensions.deviationThresholdKm]).
  ///
  /// Returns [Right] with [RouteDeviationResult].
  /// Returns [Left] with [Failure] on error.
  Future<Either<Failure, RouteDeviationResult>> call({
    required double currentLat,
    required double currentLon,
    required List<({double lat, double lon})>
        expectedRoute,
    double? thresholdKm,
  }) async {
    try {
      final threshold =
          thresholdKm ?? AppDimensions.deviationThresholdKm;

      // If no expected route is set, the rider is
      // free-roaming — no deviation possible.
      if (expectedRoute.isEmpty) {
        _deviationStartedAt = null;
        _lastDeviationKm = 0.0;
        return const Right(
          RouteDeviationResult(
            deviationKm: 0.0,
            shouldAlert: false,
            sustainedDuration: Duration.zero,
          ),
        );
      }

      final deviationKm =
          DistanceCalculator.distanceToRoute(
        currentLat,
        currentLon,
        expectedRoute,
      );

      _lastDeviationKm = deviationKm;
      final now = DateTime.now();

      if (deviationKm > threshold) {
        // Start tracking sustained deviation
        _deviationStartedAt ??= now;

        final sustained =
            now.difference(_deviationStartedAt!);
        final sustainedMinutes = sustained.inMinutes;

        final shouldAlert = sustainedMinutes >=
            AppDimensions.deviationTimeLimitMin;

        if (shouldAlert) {
          AppLogger.warning(
            'Route deviation alert: '
            '${deviationKm.toStringAsFixed(2)} km '
            'for $sustainedMinutes min',
            tag: _tag,
          );
        } else {
          AppLogger.debug(
            'Route deviation detected: '
            '${deviationKm.toStringAsFixed(2)} km '
            '(${sustained.inSeconds}s)',
            tag: _tag,
          );
        }

        return Right(
          RouteDeviationResult(
            deviationKm: deviationKm,
            shouldAlert: shouldAlert,
            sustainedDuration: sustained,
          ),
        );
      }

      // Back on route — reset deviation tracking
      if (_deviationStartedAt != null) {
        AppLogger.info(
          'Rider back on route',
          tag: _tag,
        );
      }
      _deviationStartedAt = null;

      return Right(
        RouteDeviationResult(
          deviationKm: deviationKm,
          shouldAlert: false,
          sustainedDuration: Duration.zero,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Route deviation check failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return Left(
        LocationFailure(
          message: 'Route deviation check failed: $e',
        ),
      );
    }
  }

  /// The last calculated deviation distance in km.
  double get lastDeviationKm => _lastDeviationKm;

  /// Whether the rider is currently deviating from
  /// the expected route.
  bool get isDeviating => _deviationStartedAt != null;
}
