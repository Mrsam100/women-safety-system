import 'package:flutter/foundation.dart';
import 'package:saferide/core/constants/app_dimensions.dart';

/// Threat level derived from the numeric score.
enum ThreatLevel {
  green,
  yellow,
  orange,
  red;

  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case ThreatLevel.green:
        return 'Safe';
      case ThreatLevel.yellow:
        return 'Caution';
      case ThreatLevel.orange:
        return 'Warning';
      case ThreatLevel.red:
        return 'Danger';
    }
  }
}

/// A single signal that contributes to the overall
/// threat score.
@immutable
class ThreatSignal {
  final String description;
  final int points;

  const ThreatSignal({
    required this.description,
    required this.points,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThreatSignal &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          points == other.points;

  @override
  int get hashCode => description.hashCode ^ points.hashCode;

  @override
  String toString() =>
      'ThreatSignal($description: +$points)';
}

/// Immutable threat assessment produced by the AI
/// scoring engine. The [level] is computed from [score]
/// using the thresholds defined in [AppDimensions].
@immutable
class ThreatAssessment {
  final int score;
  final List<ThreatSignal> activeSignals;
  final DateTime lastUpdated;

  const ThreatAssessment({
    required this.score,
    this.activeSignals = const [],
    required this.lastUpdated,
  });

  /// Default assessment with zero threat.
  factory ThreatAssessment.initial() => ThreatAssessment(
        score: 0,
        activeSignals: const [],
        lastUpdated: DateTime.now(),
      );

  /// Compute threat level from score using
  /// AppDimensions thresholds:
  ///   green  : 0–30
  ///   yellow : 31–60
  ///   orange : 61–80
  ///   red    : 81–100
  ThreatLevel get level {
    if (score <= AppDimensions.greenMax) {
      return ThreatLevel.green;
    } else if (score <= AppDimensions.yellowMax) {
      return ThreatLevel.yellow;
    } else if (score <= AppDimensions.orangeMax) {
      return ThreatLevel.orange;
    } else {
      return ThreatLevel.red;
    }
  }

  ThreatAssessment copyWith({
    int? score,
    List<ThreatSignal>? activeSignals,
    DateTime? lastUpdated,
  }) {
    return ThreatAssessment(
      score: score ?? this.score,
      activeSignals:
          activeSignals ?? this.activeSignals,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThreatAssessment &&
          runtimeType == other.runtimeType &&
          score == other.score &&
          listEquals(activeSignals, other.activeSignals) &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      score.hashCode ^
      activeSignals.hashCode ^
      lastUpdated.hashCode;

  @override
  String toString() =>
      'ThreatAssessment(score: $score, '
      'level: ${level.name}, '
      'signals: ${activeSignals.length})';
}
