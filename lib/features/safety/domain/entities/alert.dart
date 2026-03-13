import 'package:flutter/foundation.dart';

enum AlertType {
  panic,
  shake,
  routeDeviation,
  speedAnomaly,
  lowBattery,
  keywordDetected,
  autoEscalation,
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

@immutable
class Alert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> details;
  final double threatScore;
  final bool resolved;
  final List<String> notifiedContacts;
  final DateTime timestamp;

  const Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.latitude,
    required this.longitude,
    this.details = const {},
    required this.threatScore,
    this.resolved = false,
    this.notifiedContacts = const [],
    required this.timestamp,
  });

  Alert copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? details,
    double? threatScore,
    bool? resolved,
    List<String>? notifiedContacts,
    DateTime? timestamp,
  }) {
    return Alert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      details: details ?? this.details,
      threatScore: threatScore ?? this.threatScore,
      resolved: resolved ?? this.resolved,
      notifiedContacts:
          notifiedContacts ?? this.notifiedContacts,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alert &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Alert(id: $id, type: $type, severity: $severity)';
}
