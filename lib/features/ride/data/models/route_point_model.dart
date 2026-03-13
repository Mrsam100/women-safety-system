import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/features/ride/domain/entities/route_point.dart';

class RoutePointModel {
  final String id;
  final double latitude;
  final double longitude;
  final double speed;
  final double bearing;
  final double accuracy;
  final int batteryLevel;
  final DateTime timestamp;

  const RoutePointModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.bearing,
    required this.accuracy,
    required this.batteryLevel,
    required this.timestamp,
  });

  factory RoutePointModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return RoutePointModel(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      bearing:
          (json['bearing'] as num?)?.toDouble() ?? 0,
      accuracy:
          (json['accuracy'] as num?)?.toDouble() ?? 0,
      batteryLevel:
          (json['batteryLevel'] as int?) ?? 100,
      timestamp:
          (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'bearing': bearing,
      'accuracy': accuracy,
      'batteryLevel': batteryLevel,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  RoutePoint toEntity() {
    return RoutePoint(
      id: id,
      latitude: latitude,
      longitude: longitude,
      speed: speed,
      bearing: bearing,
      accuracy: accuracy,
      batteryLevel: batteryLevel,
      timestamp: timestamp,
    );
  }

  factory RoutePointModel.fromEntity(
    RoutePoint entity,
  ) {
    return RoutePointModel(
      id: entity.id,
      latitude: entity.latitude,
      longitude: entity.longitude,
      speed: entity.speed,
      bearing: entity.bearing,
      accuracy: entity.accuracy,
      batteryLevel: entity.batteryLevel,
      timestamp: entity.timestamp,
    );
  }
}
