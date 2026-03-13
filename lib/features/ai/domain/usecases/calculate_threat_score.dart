import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/ai/domain/entities/threat_assessment.dart';

// ─── Signal point constants ───

/// Route deviation from expected path.
const int kRouteDeviationPoints = 30;

/// Abnormal speed (too fast or suspiciously slow).
const int kSpeedAnomalyPoints = 25;

/// Base points for distress keyword detection.
/// Multiplied by confidence (0.0–1.0), so actual
/// contribution is 0–20.
const int kDistressKeywordBasePoints = 20;

/// Isolated area combined with nighttime travel.
const int kIsolatedNighttimePoints = 15;

/// Vehicle stopped for an extended duration in an
/// unexpected location.
const int kExtendedStopPoints = 10;

/// Shake alert triggered by accelerometer.
const int kShakeAlertPoints = 35;

/// Panic button pressed — instant escalation to
/// maximum score.
const int kPanicButtonPoints = 50;

/// Area historical risk score contribution (0–10).
const int kAreaRiskMaxPoints = 10;

/// Recalculation interval in seconds.
const int kRecalcIntervalSeconds = 10;

// ─── Signal input types ───

/// Container for all raw signal inputs fed into the
/// threat score calculation engine.
class ThreatSignalInput {
  /// Whether the rider has deviated from the expected
  /// route beyond the threshold.
  final bool isRouteDeviated;

  /// Whether speed is anomalous (too high or
  /// suspiciously low for the road type).
  final bool isSpeedAnomalous;

  /// Detected distress keyword (null if none).
  final String? distressKeyword;

  /// Confidence of the keyword detection (0.0–1.0).
  final double keywordConfidence;

  /// Whether the current location is classified as
  /// isolated (low population density).
  final bool isIsolatedArea;

  /// Whether it is currently nighttime (10 PM – 5 AM).
  final bool isNighttime;

  /// Whether the vehicle has been stopped for an
  /// extended duration in an unexpected location.
  final bool isExtendedStop;

  /// Whether the shake alert was triggered.
  final bool isShakeAlert;

  /// Whether the panic button was pressed.
  final bool isPanicButton;

  /// Historical area risk score (0.0–1.0).
  final double areaRiskScore;

  const ThreatSignalInput({
    this.isRouteDeviated = false,
    this.isSpeedAnomalous = false,
    this.distressKeyword,
    this.keywordConfidence = 0.0,
    this.isIsolatedArea = false,
    this.isNighttime = false,
    this.isExtendedStop = false,
    this.isShakeAlert = false,
    this.isPanicButton = false,
    this.areaRiskScore = 0.0,
  });
}

/// THE CORE AI FILE.
///
/// Combines all safety signals into a single threat
/// score (0–100). This is recalculated every
/// [kRecalcIntervalSeconds] seconds during an active
/// ride.
///
/// Signal contributions:
///   - Route deviation:       +30
///   - Speed anomaly:         +25
///   - Distress keyword:      +20 * confidence
///   - Isolated area + night: +15
///   - Extended stop:         +10
///   - Shake alert:           +35
///   - Panic button:          +50 (instant max)
///   - Area risk:             +0–10
///
/// Score = min(100, sum of all active signals).
///
/// Thresholds (from [AppDimensions]):
///   green  : 0–30   → no action
///   yellow : 31–60  → prompt user
///   orange : 61–80  → notify contacts
///   red    : 81–100 → full emergency
class CalculateThreatScore {
  static const _tag = 'CalculateThreatScore';

  /// Timestamp of the last calculation.
  DateTime? _lastCalculation;

  /// Previous assessment for comparison.
  ThreatAssessment? _previousAssessment;

  /// Whether enough time has elapsed since the last
  /// calculation to warrant a recalculation.
  bool get shouldRecalculate {
    if (_lastCalculation == null) return true;
    final elapsed = DateTime.now()
        .difference(_lastCalculation!)
        .inSeconds;
    return elapsed >= kRecalcIntervalSeconds;
  }

  /// The most recent assessment result.
  ThreatAssessment? get previousAssessment =>
      _previousAssessment;

  /// Reset internal state. Call when a ride starts
  /// or ends.
  void reset() {
    _lastCalculation = null;
    _previousAssessment = null;
  }

  /// Calculate the aggregate threat score from the
  /// provided signal inputs.
  ///
  /// Returns [Right] with a [ThreatAssessment] on
  /// success, or [Left] with a [Failure] on error.
  Future<Either<Failure, ThreatAssessment>> call(
    ThreatSignalInput input,
  ) async {
    try {
      final signals = <ThreatSignal>[];

      // ── Panic button (instant max priority) ──
      if (input.isPanicButton) {
        signals.add(
          const ThreatSignal(
            description: 'Panic button activated',
            points: kPanicButtonPoints,
          ),
        );
      }

      // ── Shake alert ──
      if (input.isShakeAlert) {
        signals.add(
          const ThreatSignal(
            description: 'Shake alert triggered',
            points: kShakeAlertPoints,
          ),
        );
      }

      // ── Route deviation ──
      if (input.isRouteDeviated) {
        signals.add(
          const ThreatSignal(
            description: 'Route deviation detected',
            points: kRouteDeviationPoints,
          ),
        );
      }

      // ── Speed anomaly ──
      if (input.isSpeedAnomalous) {
        signals.add(
          const ThreatSignal(
            description: 'Speed anomaly detected',
            points: kSpeedAnomalyPoints,
          ),
        );
      }

      // ── Distress keyword ──
      if (input.distressKeyword != null &&
          input.keywordConfidence > 0.0) {
        final keywordPoints =
            (kDistressKeywordBasePoints *
                    input.keywordConfidence)
                .round();
        signals.add(
          ThreatSignal(
            description:
                'Distress keyword: '
                '"${input.distressKeyword}" '
                '(${(input.keywordConfidence * 100).toStringAsFixed(0)}%)',
            points: keywordPoints,
          ),
        );
      }

      // ── Isolated area + nighttime (combined) ──
      if (input.isIsolatedArea && input.isNighttime) {
        signals.add(
          const ThreatSignal(
            description:
                'Isolated area during nighttime',
            points: kIsolatedNighttimePoints,
          ),
        );
      }

      // ── Extended stop ──
      if (input.isExtendedStop) {
        signals.add(
          const ThreatSignal(
            description: 'Extended stop in '
                'unexpected location',
            points: kExtendedStopPoints,
          ),
        );
      }

      // ── Area historical risk ──
      if (input.areaRiskScore > 0.0) {
        final areaPoints =
            (kAreaRiskMaxPoints * input.areaRiskScore)
                .round()
                .clamp(0, kAreaRiskMaxPoints);
        if (areaPoints > 0) {
          signals.add(
            ThreatSignal(
              description:
                  'Area risk score: '
                  '${(input.areaRiskScore * 100).toStringAsFixed(0)}%',
              points: areaPoints,
            ),
          );
        }
      }

      // ── Compute final score ──
      final rawScore = signals.fold<int>(
        0,
        (sum, signal) => sum + signal.points,
      );
      final score = math.min(100, rawScore);

      final now = DateTime.now();
      final assessment = ThreatAssessment(
        score: score,
        activeSignals: List.unmodifiable(signals),
        lastUpdated: now,
      );

      _lastCalculation = now;

      // Log level transitions
      if (_previousAssessment != null &&
          _previousAssessment!.level !=
              assessment.level) {
        AppLogger.warning(
          'Threat level changed: '
          '${_previousAssessment!.level.name} → '
          '${assessment.level.name} '
          '(score: $score)',
          tag: _tag,
        );
      } else {
        AppLogger.debug(
          'Threat score: $score '
          '(${assessment.level.name}), '
          '${signals.length} active signals',
          tag: _tag,
        );
      }

      _previousAssessment = assessment;

      return Right(assessment);
    } catch (e, st) {
      AppLogger.error(
        'Threat score calculation failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return Left(
        ServerFailure(
          message:
              'Threat score calculation failed: $e',
        ),
      );
    }
  }
}
