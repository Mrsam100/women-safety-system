import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/features/safety/domain/entities/safety_event.dart';

class SafetyEventModel {
  final String id;
  final String type;
  final String description;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  const SafetyEventModel({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  factory SafetyEventModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SafetyEventModel(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      timestamp:
          (json['timestamp'] as Timestamp).toDate(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  SafetyEvent toEntity() {
    return SafetyEvent(
      id: id,
      type: type,
      description: description,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
    );
  }

  factory SafetyEventModel.fromEntity(
    SafetyEvent entity,
  ) {
    return SafetyEventModel(
      id: entity.id,
      type: entity.type,
      description: entity.description,
      timestamp: entity.timestamp,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }
}
