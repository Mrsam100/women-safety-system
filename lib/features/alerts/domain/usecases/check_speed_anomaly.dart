import 'package:dartz/dartz.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/utils/distance_calculator.dart';
import 'package:saferide/core/utils/logger.dart';

/// Type of speed anomaly detected.
enum SpeedAnomalyType {
  /// Vehicle is travelling above the speed threshold.
  excessiveSpeed,

  /// Vehicle has been stationary in an isolated area
  /// during nighttime for an extended period.
  stoppedIsolatedNight,
}

/// Result of a speed anomaly check.
class SpeedAnomalyResult {
  final bool shouldAlert;
  final SpeedAnomalyType? anomalyType;
  final double speedKmh;
  final Duration? stoppedDuration;
  final String? reason;

  const SpeedAnomalyResult({
    required this.shouldAlert,
    this.anomalyType,
    required this.speedKmh,
    this.stoppedDuration,
    this.reason,
  });
}

/// Detect speed anomalies during an active ride.
///
/// Two detection modes:
/// 1. **Excessive speed** — alert if speed exceeds
///    the threshold (default 100 km/h).
/// 2. **Stopped in isolated area at night** — alert if
///    the vehicle is stationary for more than 5 minutes
///    during nighttime hours (8 PM to 6 AM).
class CheckSpeedAnomaly {
  static const _tag = 'CheckSpeedAnomaly';

  /// Nighttime start hour (20:00 / 8 PM).
  static const _nightStartHour = 20;

  /// Nighttime end hour (06:00 / 6 AM).
  static const _nightEndHour = 6;

  /// Minimum stop duration in minutes before alerting.
  static const _stoppedThresholdMinutes = 5;

  /// Speed below which the vehicle is considered
  /// stationary (km/h). Accounts for GPS drift.
  static const _stationarySpeedKmh = 2.0;

  /// Timestamp when the vehicle first stopped.
  DateTime? _stoppedSince;

  /// Location where the vehicle stopped.
  double? _stoppedLat;
  double? _stoppedLon;

  /// Reset internal state. Call when a ride starts
  /// or ends.
  void reset() {
    _stoppedSince = null;
    _stoppedLat = null;
    _stoppedLon = null;
  }

  /// Evaluate whether the current ride parameters
  /// indicate a speed anomaly.
  ///
  /// [currentLat] / [currentLon] — current position.
  /// [previousLat] / [previousLon] — previous position.
  /// [timeDiffSeconds] — seconds between the two
  ///   position readings.
  /// [timestamp] — current reading timestamp (used to
  ///   determine nighttime).
  /// [speedThresholdKmh] — override the default speed
  ///   threshold.
  /// [nightTimeOnly] — when `true`, the excessive
  ///   speed check only fires during nighttime hours.
  Future<Either<Failure, SpeedAnomalyResult>> call({
    required double currentLat,
    required double currentLon,
    required double previousLat,
    required double previousLon,
    required int timeDiffSeconds,
    required DateTime timestamp,
    double? speedThresholdKmh,
    bool nightTimeOnly = false,
  }) async {
    try {
      final threshold = speedThresholdKmh ??
          AppDimensions.speedThresholdKmh;

      final speedKmh = DistanceCalculator.calculateSpeed(
        previousLat,
        previousLon,
        currentLat,
        currentLon,
        timeDiffSeconds,
      );

      final isNight = _isNightTime(timestamp);

      // ── Check 1: Excessive speed ──
      final checkSpeed = nightTimeOnly ? isNight : true;
      if (checkSpeed && speedKmh > threshold) {
        // Reset stopped state — vehicle is moving
        _stoppedSince = null;
        _stoppedLat = null;
        _stoppedLon = null;

        AppLogger.warning(
          'Excessive speed detected: '
          '${speedKmh.toStringAsFixed(1)} km/h '
          '(threshold: $threshold)',
          tag: _tag,
        );

        return Right(
          SpeedAnomalyResult(
            shouldAlert: true,
            anomalyType: SpeedAnomalyType.excessiveSpeed,
            speedKmh: speedKmh,
            reason: 'Speed ${speedKmh.toStringAsFixed(0)}'
                ' km/h exceeds limit of '
                '${threshold.toStringAsFixed(0)} km/h',
          ),
        );
      }

      // ── Check 2: Stopped in isolated area at night ──
      if (isNight && speedKmh < _stationarySpeedKmh) {
        if (_stoppedSince == null) {
          _stoppedSince = timestamp;
          _stoppedLat = currentLat;
          _stoppedLon = currentLon;
        } else {
          // Verify the vehicle hasn't drifted far from
          // where it stopped (GPS jitter tolerance).
          final drift = DistanceCalculator.haversine(
            _stoppedLat!,
            _stoppedLon!,
            currentLat,
            currentLon,
          );

          // If drifted more than 100 m, reset — this
          // is actual movement, not a stop.
          if (drift > 0.1) {
            _stoppedSince = timestamp;
            _stoppedLat = currentLat;
            _stoppedLon = currentLon;
          }
        }

        final stoppedDuration =
            timestamp.difference(_stoppedSince!);

        if (stoppedDuration.inMinutes >=
            _stoppedThresholdMinutes) {
          AppLogger.warning(
            'Stopped in isolated area at night: '
            '${stoppedDuration.inMinutes} min',
            tag: _tag,
          );

          return Right(
            SpeedAnomalyResult(
              shouldAlert: true,
              anomalyType:
                  SpeedAnomalyType.stoppedIsolatedNight,
              speedKmh: speedKmh,
              stoppedDuration: stoppedDuration,
              reason: 'Vehicle stopped for '
                  '${stoppedDuration.inMinutes} min '
                  'during nighttime',
            ),
          );
        }

        return Right(
          SpeedAnomalyResult(
            shouldAlert: false,
            speedKmh: speedKmh,
            stoppedDuration: stoppedDuration,
          ),
        );
      }

      // Moving normally — reset stopped state
      if (speedKmh >= _stationarySpeedKmh) {
        _stoppedSince = null;
        _stoppedLat = null;
        _stoppedLon = null;
      }

      return Right(
        SpeedAnomalyResult(
          shouldAlert: false,
          speedKmh: speedKmh,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Speed anomaly check failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return Left(
        LocationFailure(
          message: 'Speed anomaly check failed: $e',
        ),
      );
    }
  }

  /// Whether the given timestamp falls within
  /// nighttime hours (8 PM to 6 AM).
  bool _isNightTime(DateTime timestamp) {
    final hour = timestamp.hour;
    return hour >= _nightStartHour ||
        hour < _nightEndHour;
  }

  /// Whether the vehicle is currently stationary.
  bool get isStopped => _stoppedSince != null;
}
