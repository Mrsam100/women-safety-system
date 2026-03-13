import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/features/ride/domain/entities/ride.dart';

class RideModel {
  final String id;
  final String userId;
  final String status;
  final double startLatitude;
  final double startLongitude;
  final String? startAddress;
  final double? endLatitude;
  final double? endLongitude;
  final String? endAddress;
  final List<Map<String, double>> expectedRoute;
  final double safetyScore;
  final int alertsTriggered;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final double? distanceKm;
  final int? userRating;

  const RideModel({
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

  factory RideModel.fromJson(Map<String, dynamic> json) {
    final rawRoute =
        json['expectedRoute'] as List<dynamic>? ?? [];
    final route = rawRoute.map((item) {
      if (item is GeoPoint) {
        return <String, double>{
          'lat': item.latitude,
          'lon': item.longitude,
        };
      }
      final map = item as Map;
      return <String, double>{
        'lat': (map['lat'] as num).toDouble(),
        'lon': (map['lon'] as num).toDouble(),
      };
    }).toList();

    return RideModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      status: json['status'] as String? ?? 'active',
      startLatitude:
          _extractLatitude(json['startLocation']),
      startLongitude:
          _extractLongitude(json['startLocation']),
      startAddress: json['startAddress'] as String?,
      endLatitude: json['endLocation'] != null
          ? _extractLatitude(json['endLocation'])
          : null,
      endLongitude: json['endLocation'] != null
          ? _extractLongitude(json['endLocation'])
          : null,
      endAddress: json['endAddress'] as String?,
      expectedRoute: route,
      safetyScore:
          (json['safetyScore'] as num?)?.toDouble() ?? 0,
      alertsTriggered:
          (json['alertsTriggered'] as int?) ?? 0,
      startedAt:
          (json['startedAt'] as Timestamp).toDate(),
      endedAt: json['endedAt'] != null
          ? (json['endedAt'] as Timestamp).toDate()
          : null,
      durationMinutes:
          json['durationMinutes'] as int?,
      distanceKm:
          (json['distanceKm'] as num?)?.toDouble(),
      userRating: json['userRating'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'status': status,
      'startLocation': GeoPoint(
        startLatitude,
        startLongitude,
      ),
      'startAddress': startAddress,
      'endLocation': endLatitude != null &&
              endLongitude != null
          ? GeoPoint(endLatitude!, endLongitude!)
          : null,
      'endAddress': endAddress,
      'expectedRoute': expectedRoute
          .map(
            (p) => GeoPoint(p['lat']!, p['lon']!),
          )
          .toList(),
      'safetyScore': safetyScore,
      'alertsTriggered': alertsTriggered,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null
          ? Timestamp.fromDate(endedAt!)
          : null,
      'durationMinutes': durationMinutes,
      'distanceKm': distanceKm,
      'userRating': userRating,
    };
  }

  Ride toEntity() {
    return Ride(
      id: id,
      userId: userId,
      status: _parseStatus(status),
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      startAddress: startAddress,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
      endAddress: endAddress,
      expectedRoute: expectedRoute
          .map(
            (p) => (lat: p['lat']!, lon: p['lon']!),
          )
          .toList(),
      safetyScore: safetyScore,
      alertsTriggered: alertsTriggered,
      startedAt: startedAt,
      endedAt: endedAt,
      durationMinutes: durationMinutes,
      distanceKm: distanceKm,
      userRating: userRating,
    );
  }

  factory RideModel.fromEntity(Ride entity) {
    return RideModel(
      id: entity.id,
      userId: entity.userId,
      status: entity.status.name,
      startLatitude: entity.startLatitude,
      startLongitude: entity.startLongitude,
      startAddress: entity.startAddress,
      endLatitude: entity.endLatitude,
      endLongitude: entity.endLongitude,
      endAddress: entity.endAddress,
      expectedRoute: entity.expectedRoute
          .map(
            (p) => <String, double>{
              'lat': p.lat,
              'lon': p.lon,
            },
          )
          .toList(),
      safetyScore: entity.safetyScore,
      alertsTriggered: entity.alertsTriggered,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      durationMinutes: entity.durationMinutes,
      distanceKm: entity.distanceKm,
      userRating: entity.userRating,
    );
  }

  static RideStatus _parseStatus(String value) {
    switch (value) {
      case 'active':
        return RideStatus.active;
      case 'completed':
        return RideStatus.completed;
      case 'emergency':
        return RideStatus.emergency;
      default:
        return RideStatus.active;
    }
  }

  static double _extractLatitude(dynamic value) {
    if (value is GeoPoint) return value.latitude;
    if (value is Map) {
      return (value['lat'] as num).toDouble();
    }
    return 0.0;
  }

  static double _extractLongitude(dynamic value) {
    if (value is GeoPoint) return value.longitude;
    if (value is Map) {
      return (value['lon'] as num).toDouble();
    }
    return 0.0;
  }
}
