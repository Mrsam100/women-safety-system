import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/features/evidence/domain/entities/location_trail.dart';

class TrailPointModel {
  final double latitude;
  final double longitude;
  final double? speed;
  final DateTime timestamp;

  const TrailPointModel({
    required this.latitude,
    required this.longitude,
    this.speed,
    required this.timestamp,
  });

  factory TrailPointModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TrailPointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  TrailPoint toEntity() {
    return TrailPoint(
      latitude: latitude,
      longitude: longitude,
      speed: speed,
      timestamp: timestamp,
    );
  }

  factory TrailPointModel.fromEntity(TrailPoint entity) {
    return TrailPointModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      speed: entity.speed,
      timestamp: entity.timestamp,
    );
  }
}

class LocationTrailModel {
  final String id;
  final String rideId;
  final List<TrailPointModel> points;
  final double totalDistance;
  final int durationMillis;

  const LocationTrailModel({
    required this.id,
    required this.rideId,
    required this.points,
    required this.totalDistance,
    required this.durationMillis,
  });

  factory LocationTrailModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final pointsList =
        (json['points'] as List<dynamic>?) ?? [];
    return LocationTrailModel(
      id: json['id'] as String,
      rideId: json['rideId'] as String,
      points: pointsList
          .map(
            (p) => TrailPointModel.fromJson(
              p as Map<String, dynamic>,
            ),
          )
          .toList(),
      totalDistance:
          (json['totalDistance'] as num).toDouble(),
      durationMillis: json['durationMillis'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'points': points.map((p) => p.toJson()).toList(),
      'totalDistance': totalDistance,
      'durationMillis': durationMillis,
    };
  }

  LocationTrail toEntity() {
    return LocationTrail(
      id: id,
      rideId: rideId,
      points:
          points.map((p) => p.toEntity()).toList(),
      totalDistance: totalDistance,
      duration: Duration(milliseconds: durationMillis),
    );
  }

  factory LocationTrailModel.fromEntity(
    LocationTrail entity,
  ) {
    return LocationTrailModel(
      id: entity.id,
      rideId: entity.rideId,
      points: entity.points
          .map((p) => TrailPointModel.fromEntity(p))
          .toList(),
      totalDistance: entity.totalDistance,
      durationMillis: entity.duration.inMilliseconds,
    );
  }
}
