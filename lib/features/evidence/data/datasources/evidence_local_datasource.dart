import 'package:hive/hive.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/features/evidence/data/models/location_trail_model.dart';

/// Local datasource for caching location trail points
/// and audio evidence metadata using Hive.
class EvidenceLocalDatasource {
  static const _trailBoxName = 'location_trails';
  static const _evidenceBoxName = 'audio_evidence_cache';

  /// Caches location trail points for a ride.
  Future<void> cacheLocationTrail(
    LocationTrailModel trail,
  ) async {
    try {
      final box = await Hive.openBox<Map>(
        _trailBoxName,
      );
      await box.put(trail.rideId, trail.toJson());
    } catch (e) {
      throw CacheException(
        message:
            'Failed to cache location trail: $e',
      );
    }
  }

  /// Retrieves cached location trail for a ride.
  /// Returns null if not cached.
  Future<LocationTrailModel?> getCachedLocationTrail(
    String rideId,
  ) async {
    try {
      final box = await Hive.openBox<Map>(
        _trailBoxName,
      );
      final data = box.get(rideId);
      if (data == null) return null;
      return LocationTrailModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (e) {
      throw CacheException(
        message:
            'Failed to read cached location trail: $e',
      );
    }
  }

  /// Appends a single trail point to the cached trail
  /// for a ride. Creates a new trail if none exists.
  Future<void> appendTrailPoint({
    required String rideId,
    required TrailPointModel point,
  }) async {
    try {
      final box = await Hive.openBox<Map>(
        _trailBoxName,
      );
      final existing = box.get(rideId);

      if (existing != null) {
        final data = Map<String, dynamic>.from(existing);
        final points =
            List<dynamic>.from(data['points'] ?? []);
        points.add(point.toJson());
        data['points'] = points;
        await box.put(rideId, data);
      } else {
        final trail = LocationTrailModel(
          id: rideId,
          rideId: rideId,
          points: [point],
          totalDistance: 0.0,
          durationMillis: 0,
        );
        await box.put(rideId, trail.toJson());
      }
    } catch (e) {
      throw CacheException(
        message:
            'Failed to append trail point: $e',
      );
    }
  }

  /// Caches audio evidence metadata for offline access.
  Future<void> cacheAudioEvidenceMetadata(
    Map<String, dynamic> evidenceJson,
  ) async {
    try {
      final box = await Hive.openBox<Map>(
        _evidenceBoxName,
      );
      final id = evidenceJson['id'] as String;
      await box.put(id, evidenceJson);
    } catch (e) {
      throw CacheException(
        message:
            'Failed to cache audio evidence: $e',
      );
    }
  }

  /// Gets all cached audio evidence metadata for a ride.
  Future<List<Map<String, dynamic>>>
      getCachedAudioEvidence(String rideId) async {
    try {
      final box = await Hive.openBox<Map>(
        _evidenceBoxName,
      );
      final results = <Map<String, dynamic>>[];
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          final map = Map<String, dynamic>.from(data);
          if (map['rideId'] == rideId) {
            results.add(map);
          }
        }
      }
      return results;
    } catch (e) {
      throw CacheException(
        message:
            'Failed to read cached audio evidence: $e',
      );
    }
  }

  /// Removes cached location trail for a ride.
  Future<void> clearCachedTrail(String rideId) async {
    try {
      final box = await Hive.openBox<Map>(
        _trailBoxName,
      );
      await box.delete(rideId);
    } catch (e) {
      throw CacheException(
        message:
            'Failed to clear cached trail: $e',
      );
    }
  }

  /// Removes cached audio evidence metadata by ID.
  Future<void> clearCachedEvidence(
    String evidenceId,
  ) async {
    try {
      final box = await Hive.openBox<Map>(
        _evidenceBoxName,
      );
      await box.delete(evidenceId);
    } catch (e) {
      throw CacheException(
        message:
            'Failed to clear cached evidence: $e',
      );
    }
  }
}
