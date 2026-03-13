import 'package:flutter/foundation.dart';

@immutable
class SafetyEvent {
  final String id;
  final String type;
  final String description;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  const SafetyEvent({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  SafetyEvent copyWith({
    String? id,
    String? type,
    String? description,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
  }) {
    return SafetyEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafetyEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SafetyEvent(id: $id, type: $type, '
      'description: $description)';
}
