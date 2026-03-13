import 'dart:async';

import 'package:saferide/core/services/connectivity_service.dart';
import 'package:saferide/core/services/sms_service.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/safety/data/datasources/safety_local_datasource.dart';
import 'package:saferide/features/safety/data/datasources/safety_remote_datasource.dart';
import 'package:saferide/features/safety/data/models/alert_model.dart';

/// Syncs queued offline items (alerts, SMS, push
/// notifications, live tracking updates) when
/// connectivity is restored.
class OfflineSyncService {
  final ConnectivityService _connectivity;
  final SafetyRemoteDatasource _remoteDatasource;
  final SafetyLocalDatasource _localDatasource;
  final SmsService _smsService;

  StreamSubscription<bool>? _subscription;
  bool _isSyncing = false;

  static const _tag = 'OfflineSyncService';

  OfflineSyncService({
    required ConnectivityService connectivity,
    required SafetyRemoteDatasource remoteDatasource,
    required SafetyLocalDatasource localDatasource,
    required SmsService smsService,
  })  : _connectivity = connectivity,
        _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource,
        _smsService = smsService;

  /// Start listening for connectivity changes and sync
  /// queued items when back online.
  void startListening() {
    _subscription?.cancel();
    _subscription =
        _connectivity.onConnectivityChanged.listen(
      (isOnline) {
        if (isOnline) {
          syncOfflineQueue();
        }
      },
    );

    // Also attempt sync immediately if already online
    if (_connectivity.isOnline) {
      syncOfflineQueue();
    }
  }

  /// Process all items in the offline queue.
  Future<void> syncOfflineQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = _localDatasource.getOfflineQueue();
      if (queue.isEmpty) {
        _isSyncing = false;
        return;
      }

      AppLogger.info(
        'Syncing ${queue.length} offline items',
        tag: _tag,
      );

      for (final item in queue) {
        try {
          final type = item['type'] as String?;
          switch (type) {
            case 'alert':
              await _syncAlert(item);
            case 'sms':
              await _syncSms(item);
            case 'liveTrackingUpdate':
              await _syncLiveTracking(item);
            case 'push':
              // Push notifications are triggered by the
              // Firestore alert write via Cloud Function,
              // so syncing the alert is sufficient.
              break;
            default:
              AppLogger.warning(
                'Unknown offline queue type: $type',
                tag: _tag,
              );
          }
        } catch (e) {
          AppLogger.error(
            'Failed to sync item: $e',
            tag: _tag,
            error: e,
          );
          // Continue with other items
        }
      }

      await _localDatasource.clearOfflineQueue();
      AppLogger.info(
        'Offline queue synced and cleared',
        tag: _tag,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncAlert(Map item) async {
    final userId = item['userId'] as String;
    final rideId = item['rideId'] as String;
    final data =
        Map<String, dynamic>.from(item['data'] as Map);
    final alertModel = AlertModel.fromJson(data);
    final alert = alertModel.toEntity();

    await _remoteDatasource.createAlert(
      userId: userId,
      rideId: rideId,
      alert: alert,
    );
    AppLogger.info(
      'Synced offline alert ${alert.id}',
      tag: _tag,
    );
  }

  Future<void> _syncSms(Map item) async {
    final phones = List<String>.from(
      item['phoneNumbers'] as List,
    );
    final message = item['message'] as String;

    await _smsService.sendBulkSms(
      phoneNumbers: phones,
      message: message,
    );
    AppLogger.info(
      'Synced offline SMS to ${phones.length} contacts',
      tag: _tag,
    );
  }

  Future<void> _syncLiveTracking(Map item) async {
    final rideId = item['rideId'] as String;
    final lat = (item['latitude'] as num).toDouble();
    final lon = (item['longitude'] as num).toDouble();
    final isEmergency = item['isEmergency'] as bool;

    await _remoteDatasource.updateLiveTracking(
      rideId: rideId,
      latitude: lat,
      longitude: lon,
      isEmergency: isEmergency,
    );
    AppLogger.info(
      'Synced offline live tracking for $rideId',
      tag: _tag,
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
