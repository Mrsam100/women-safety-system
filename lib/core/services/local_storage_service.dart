import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:saferide/core/utils/logger.dart';

class LocalStorageService {
  static const _settingsBox = 'settings';
  static const _locationCacheBox = 'location_cache';
  static const _offlineQueueBox = 'offline_queue';

  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
    await Hive.openBox<Map>(_locationCacheBox);
    await Hive.openBox<Map>(_offlineQueueBox);
    AppLogger.info(
      'Local storage initialized',
      tag: 'LocalStorageService',
    );
  }

  // --- Hive (Settings) ---

  Box get _settings => Hive.box(_settingsBox);

  T? getSetting<T>(String key) => _settings.get(key) as T?;

  Future<void> saveSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  Future<void> removeSetting(String key) async {
    await _settings.delete(key);
  }

  // --- Hive (Location Cache) ---

  Box<Map> get _locationCache =>
      Hive.box<Map>(_locationCacheBox);

  Future<void> cacheLocationPoint(Map<String, dynamic> point) async {
    await _locationCache.add(point);
  }

  List<Map> getCachedLocations() => _locationCache.values.toList();

  Future<void> clearLocationCache() async {
    await _locationCache.clear();
  }

  // --- Hive (Offline Queue) ---

  Box<Map> get _offlineQueue =>
      Hive.box<Map>(_offlineQueueBox);

  Future<void> addToOfflineQueue(Map<String, dynamic> item) async {
    await _offlineQueue.add(item);
  }

  List<Map> getOfflineQueue() => _offlineQueue.values.toList();

  Future<void> clearOfflineQueue() async {
    await _offlineQueue.clear();
  }

  // --- Secure Storage ---

  Future<void> saveSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _settings.clear();
    await _locationCache.clear();
    await _offlineQueue.clear();
    await _secureStorage.deleteAll();
  }
}
