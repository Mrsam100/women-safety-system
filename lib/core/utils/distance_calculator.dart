import 'dart:math';

abstract final class DistanceCalculator {
  static const _earthRadiusKm = 6371.0;

  /// Calculate distance between two GPS coordinates
  /// using the Haversine formula. Returns distance in km.
  static double haversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  /// Find the minimum distance from a point to a polyline
  /// (list of route points). Returns distance in km.
  static double distanceToRoute(
    double lat,
    double lon,
    List<({double lat, double lon})> routePoints,
  ) {
    if (routePoints.isEmpty) return double.infinity;

    var minDistance = double.infinity;
    for (final point in routePoints) {
      final dist = haversine(lat, lon, point.lat, point.lon);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }
    return minDistance;
  }

  /// Calculate speed in km/h given two points and
  /// time difference in seconds.
  static double calculateSpeed(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    int timeDiffSeconds,
  ) {
    if (timeDiffSeconds <= 0) return 0;
    final distKm = haversine(lat1, lon1, lat2, lon2);
    return (distKm / timeDiffSeconds) * 3600;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}
