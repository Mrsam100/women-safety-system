import 'package:flutter/foundation.dart';
import 'package:saferide/features/ai/domain/entities/threat_assessment.dart';

/// Serializable model for persisting and transferring
/// threat score data. Maps to/from JSON and converts
/// to the domain [ThreatAssessment] entity.
@immutable
class ThreatScoreModel {
  /// Aggregate threat score (0–100).
  final int score;

  /// List of active signals contributing to the score.
  final List<ThreatSignalModel> signals;

  /// Timestamp of the calculation.
  final DateTime timestamp;

  const ThreatScoreModel({
    required this.score,
    required this.signals,
    required this.timestamp,
  });

  factory ThreatScoreModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ThreatScoreModel(
      score: json['score'] as int? ?? 0,
      signals: (json['signals'] as List<dynamic>?)
              ?.map(
                (s) => ThreatSignalModel.fromJson(
                  s as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'signals':
          signals.map((s) => s.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Convert to domain entity.
  ThreatAssessment toEntity() {
    return ThreatAssessment(
      score: score,
      activeSignals: signals
          .map(
            (s) => ThreatSignal(
              description: s.description,
              points: s.points,
            ),
          )
          .toList(),
      lastUpdated: timestamp,
    );
  }

  /// Create from domain entity.
  factory ThreatScoreModel.fromEntity(
    ThreatAssessment entity,
  ) {
    return ThreatScoreModel(
      score: entity.score,
      signals: entity.activeSignals
          .map(
            (s) => ThreatSignalModel(
              description: s.description,
              points: s.points,
            ),
          )
          .toList(),
      timestamp: entity.lastUpdated,
    );
  }

  ThreatScoreModel copyWith({
    int? score,
    List<ThreatSignalModel>? signals,
    DateTime? timestamp,
  }) {
    return ThreatScoreModel(
      score: score ?? this.score,
      signals: signals ?? this.signals,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThreatScoreModel &&
          runtimeType == other.runtimeType &&
          score == other.score &&
          timestamp == other.timestamp;

  @override
  int get hashCode => score.hashCode ^ timestamp.hashCode;

  @override
  String toString() =>
      'ThreatScoreModel(score: $score, '
      'signals: ${signals.length}, '
      'timestamp: $timestamp)';
}

/// Serializable model for a single threat signal.
@immutable
class ThreatSignalModel {
  final String description;
  final int points;

  const ThreatSignalModel({
    required this.description,
    required this.points,
  });

  factory ThreatSignalModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ThreatSignalModel(
      description:
          json['description'] as String? ?? '',
      points: json['points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'points': points,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThreatSignalModel &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          points == other.points;

  @override
  int get hashCode =>
      description.hashCode ^ points.hashCode;

  @override
  String toString() =>
      'ThreatSignalModel($description: +$points)';
}
