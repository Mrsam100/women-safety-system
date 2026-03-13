import 'package:flutter/foundation.dart';
import 'package:saferide/features/ai/domain/entities/keyword_detection.dart';

/// Model representing the result of a keyword detection
/// pass on an audio chunk.
///
/// If no keyword was detected, [keyword] is an empty
/// string and [confidence] is 0.0.
@immutable
class KeywordDetectionResult {
  /// The detected distress keyword, or empty string
  /// if none was found.
  final String keyword;

  /// Confidence score (0.0–1.0) of the detection.
  final double confidence;

  /// Timestamp when the detection was performed.
  final DateTime timestamp;

  const KeywordDetectionResult({
    required this.keyword,
    required this.confidence,
    required this.timestamp,
  });

  /// Whether a keyword was actually detected.
  bool get isDetected =>
      keyword.isNotEmpty && confidence > 0.0;

  /// Create an empty (no detection) result.
  factory KeywordDetectionResult.empty() =>
      KeywordDetectionResult(
        keyword: '',
        confidence: 0.0,
        timestamp: DateTime.now(),
      );

  factory KeywordDetectionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return KeywordDetectionResult(
      keyword: json['keyword'] as String? ?? '',
      confidence:
          (json['confidence'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyword': keyword,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  KeywordDetectionResult copyWith({
    String? keyword,
    double? confidence,
    DateTime? timestamp,
  }) {
    return KeywordDetectionResult(
      keyword: keyword ?? this.keyword,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeywordDetectionResult &&
          runtimeType == other.runtimeType &&
          keyword == other.keyword &&
          confidence == other.confidence &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      keyword.hashCode ^
      confidence.hashCode ^
      timestamp.hashCode;

  /// Convert to domain entity.
  KeywordDetection toEntity() {
    return KeywordDetection(
      keyword: keyword,
      confidence: confidence,
      timestamp: timestamp,
    );
  }

  @override
  String toString() =>
      'KeywordDetectionResult('
      'keyword: $keyword, '
      'confidence: ${confidence.toStringAsFixed(2)}, '
      'timestamp: $timestamp)';
}
