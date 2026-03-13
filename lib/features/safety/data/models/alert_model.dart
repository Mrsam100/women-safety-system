import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/features/safety/domain/entities/alert.dart';

class AlertModel {
  final String id;
  final String type;
  final String severity;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> details;
  final double threatScore;
  final bool resolved;
  final List<String> notifiedContacts;
  final DateTime timestamp;

  const AlertModel({
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

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      type: json['type'] as String,
      severity: json['severity'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      details: json['details'] != null
          ? Map<String, dynamic>.from(
              json['details'] as Map,
            )
          : const {},
      threatScore:
          (json['threatScore'] as num).toDouble(),
      resolved: json['resolved'] as bool? ?? false,
      notifiedContacts: json['notifiedContacts'] != null
          ? List<String>.from(
              json['notifiedContacts'] as List,
            )
          : const [],
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'latitude': latitude,
      'longitude': longitude,
      'details': details,
      'threatScore': threatScore,
      'resolved': resolved,
      'notifiedContacts': notifiedContacts,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  Alert toEntity() {
    return Alert(
      id: id,
      type: _parseAlertType(type),
      severity: _parseAlertSeverity(severity),
      latitude: latitude,
      longitude: longitude,
      details: details,
      threatScore: threatScore,
      resolved: resolved,
      notifiedContacts: notifiedContacts,
      timestamp: timestamp,
    );
  }

  factory AlertModel.fromEntity(Alert entity) {
    return AlertModel(
      id: entity.id,
      type: entity.type.name,
      severity: entity.severity.name,
      latitude: entity.latitude,
      longitude: entity.longitude,
      details: entity.details,
      threatScore: entity.threatScore,
      resolved: entity.resolved,
      notifiedContacts: entity.notifiedContacts,
      timestamp: entity.timestamp,
    );
  }

  static AlertType _parseAlertType(String value) {
    return AlertType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertType.panic,
    );
  }

  static AlertSeverity _parseAlertSeverity(String value) {
    return AlertSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertSeverity.high,
    );
  }
}
