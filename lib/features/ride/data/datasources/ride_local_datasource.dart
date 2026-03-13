import 'package:saferide/core/services/local_storage_service.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/ride/data/models/route_point_model.dart';

/// Local datasource that caches route points in Hive
/// for offline-first operation and supports batch
/// upload when connectivity is restored.
class RideLocalDatasource {
  final LocalStorageService _localStorage;

  static const _tag = 'RideLocalDatasource';

  const RideLocalDatasource({
    required LocalStorageService localStorage,
  }) : _localStorage = localStorage;

  /// Cache a route point locally.
  Future<void> cacheRoutePoint(
    RoutePointModel point,
  ) async {
    await _localStorage.cacheLocationPoint(
      point.toJson().map(
            (key, value) =>
                MapEntry(key, value.toString()),
          ),
    );
    AppLogger.debug(
      'Route point ${point.id} cached locally',
      tag: _tag,
    );
  }

  /// Get all cached route points that haven't been
  /// uploaded yet.
  List<Map<String, dynamic>> getCachedRoutePoints() {
    final raw = _localStorage.getCachedLocations();
    return raw
        .map(
          (m) => Map<String, dynamic>.from(m),
        )
        .toList();
  }

  /// Clear all cached route points after a successful
  /// batch upload.
  Future<void> clearCachedRoutePoints() async {
    await _localStorage.clearLocationCache();
    AppLogger.info(
      'Cached route points cleared',
      tag: _tag,
    );
  }

  /// Queue a ride-related operation (start/end/point)
  /// for offline sync.
  Future<void> queueRideOperation({
    required String operationType,
    required String userId,
    required String rideId,
    required Map<String, dynamic> data,
  }) async {
    await _localStorage.addToOfflineQueue({
      'type': 'ride_$operationType',
      'userId': userId,
      'rideId': rideId,
      'data': data,
      'queuedAt': DateTime.now().toIso8601String(),
    });

    AppLogger.info(
      'Ride operation "$operationType" queued offline '
      'for ride $rideId',
      tag: _tag,
    );
  }

  /// Retrieve all queued ride operations.
  List<Map<String, dynamic>> getQueuedOperations() {
    final queue = _localStorage.getOfflineQueue();
    return queue
        .where(
          (item) =>
              item['type']?.toString().startsWith(
                    'ride_',
                  ) ??
              false,
        )
        .map(
          (m) => Map<String, dynamic>.from(m),
        )
        .toList();
  }

  /// Clear the offline queue after successful sync.
  Future<void> clearOfflineQueue() async {
    await _localStorage.clearOfflineQueue();
    AppLogger.info(
      'Ride offline queue cleared',
      tag: _tag,
    );
  }
}
