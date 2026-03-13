import 'package:flutter/foundation.dart';

enum RideStatus {
  active,
  completed,
  emergency,
}

@immutable
class Ride {
  final String id;
  final String userId;
  final RideStatus status;
  final double startLatitude;
  final double startLongitude;
  final String? startAddress;
  final double? endLatitude;
  final double? endLongitude;
  final String? endAddress;
  final List<({double lat, double lon})> expectedRoute;
  final double safetyScore;
  final int alertsTriggered;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final double? distanceKm;
  final int? userRating;

  const Ride({
    required this.id,
    required this.userId,
    required this.status,
    required this.startLatitude,
    required this.startLongitude,
    this.startAddress,
    this.endLatitude,
    this.endLongitude,
    this.endAddress,
    this.expectedRoute = const [],
    this.safetyScore = 0,
    this.alertsTriggered = 0,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes,
    this.distanceKm,
    this.userRating,
  });

  Ride copyWith({
    String? id,
    String? userId,
    RideStatus? status,
    double? startLatitude,
    double? startLongitude,
    String? startAddress,
    double? endLatitude,
    double? endLongitude,
    String? endAddress,
    List<({double lat, double lon})>? expectedRoute,
    double? safetyScore,
    int? alertsTriggered,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    double? distanceKm,
    int? userRating,
  }) {
    return Ride(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude:
          startLongitude ?? this.startLongitude,
      startAddress: startAddress ?? this.startAddress,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      endAddress: endAddress ?? this.endAddress,
      expectedRoute:
          expectedRoute ?? this.expectedRoute,
      safetyScore: safetyScore ?? this.safetyScore,
      alertsTriggered:
          alertsTriggered ?? this.alertsTriggered,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes:
          durationMinutes ?? this.durationMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      userRating: userRating ?? this.userRating,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ride &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
