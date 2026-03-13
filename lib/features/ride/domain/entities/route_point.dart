import 'package:flutter/foundation.dart';

@immutable
class RoutePoint {
  final String id;
  final double latitude;
  final double longitude;
  final double speed;
  final double bearing;
  final double accuracy;
  final int batteryLevel;
  final DateTime timestamp;

  const RoutePoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.bearing,
    required this.accuracy,
    required this.batteryLevel,
    required this.timestamp,
  });

  RoutePoint copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? speed,
    double? bearing,
    double? accuracy,
    int? batteryLevel,
    DateTime? timestamp,
  }) {
    return RoutePoint(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      accuracy: accuracy ?? this.accuracy,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutePoint &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
