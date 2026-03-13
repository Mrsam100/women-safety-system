import 'package:flutter/foundation.dart';

@immutable
class TrailPoint {
  final double latitude;
  final double longitude;
  final double? speed;
  final DateTime timestamp;

  const TrailPoint({
    required this.latitude,
    required this.longitude,
    this.speed,
    required this.timestamp,
  });

  TrailPoint copyWith({
    double? latitude,
    double? longitude,
    double? speed,
    DateTime? timestamp,
  }) {
    return TrailPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrailPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      timestamp.hashCode;
}

@immutable
class LocationTrail {
  final String id;
  final String rideId;
  final List<TrailPoint> points;
  final double totalDistance;
  final Duration duration;

  const LocationTrail({
    required this.id,
    required this.rideId,
    required this.points,
    required this.totalDistance,
    required this.duration,
  });

  bool get isEmpty => points.isEmpty;

  int get pointCount => points.length;

  TrailPoint? get firstPoint =>
      points.isNotEmpty ? points.first : null;

  TrailPoint? get lastPoint =>
      points.isNotEmpty ? points.last : null;

  double? get averageSpeed {
    if (points.isEmpty) return null;
    final speeds = points
        .where((p) => p.speed != null)
        .map((p) => p.speed!);
    if (speeds.isEmpty) return null;
    return speeds.reduce((a, b) => a + b) / speeds.length;
  }

  LocationTrail copyWith({
    String? id,
    String? rideId,
    List<TrailPoint>? points,
    double? totalDistance,
    Duration? duration,
  }) {
    return LocationTrail(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      points: points ?? this.points,
      totalDistance: totalDistance ?? this.totalDistance,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationTrail &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'LocationTrail(id: $id, rideId: $rideId, '
      'points: ${points.length}, '
      'distance: ${totalDistance.toStringAsFixed(2)}km)';
}
