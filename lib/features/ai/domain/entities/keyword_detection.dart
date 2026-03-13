import 'package:flutter/foundation.dart';

/// Domain entity representing the result of keyword
/// detection on an audio chunk.
@immutable
class KeywordDetection {
  /// The detected distress keyword, or empty string
  /// if none was found.
  final String keyword;

  /// Confidence score (0.0–1.0) of the detection.
  final double confidence;

  /// Timestamp when the detection was performed.
  final DateTime timestamp;

  const KeywordDetection({
    required this.keyword,
    required this.confidence,
    required this.timestamp,
  });

  /// Whether a keyword was actually detected.
  bool get isDetected =>
      keyword.isNotEmpty && confidence > 0.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeywordDetection &&
          runtimeType == other.runtimeType &&
          keyword == other.keyword &&
          confidence == other.confidence &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      keyword.hashCode ^
      confidence.hashCode ^
      timestamp.hashCode;

  @override
  String toString() =>
      'KeywordDetection('
      'keyword: $keyword, '
      'confidence: ${confidence.toStringAsFixed(2)})';
}
