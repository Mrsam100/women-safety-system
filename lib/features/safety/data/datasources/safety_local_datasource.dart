import 'package:saferide/core/services/local_storage_service.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/safety/data/models/alert_model.dart';
import 'package:saferide/features/safety/domain/entities/alert.dart';

/// Local datasource that queues alerts, SMS, push
/// notifications, and live tracking updates for offline
/// sync using Hive via [LocalStorageService].
class SafetyLocalDatasource {
  final LocalStorageService _localStorage;

  static const _tag = 'SafetyLocalDatasource';

  const SafetyLocalDatasource({
    required LocalStorageService localStorage,
  }) : _localStorage = localStorage;

  /// Queue an alert for later sync to Firestore.
  Future<void> queueAlert({
    required String userId,
    required String rideId,
    required Alert alert,
  }) async {
    final model = AlertModel.fromEntity(alert);
    await _localStorage.addToOfflineQueue({
      'type': 'alert',
      'userId': userId,
      'rideId': rideId,
      'data': model.toJson(),
      'queuedAt': DateTime.now().toIso8601String(),
    });

    AppLogger.info(
      'Alert ${alert.id} queued offline',
      tag: _tag,
    );
  }

  /// Queue an SMS for later dispatch via Cloud Function.
  Future<void> queueSms({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    await _localStorage.addToOfflineQueue({
      'type': 'sms',
      'phoneNumbers': phoneNumbers,
      'message': message,
      'queuedAt': DateTime.now().toIso8601String(),
    });

    AppLogger.info(
      'SMS queued offline for ${phoneNumbers.length} '
      'contacts',
      tag: _tag,
    );
  }

  /// Queue a push notification for later dispatch.
  Future<void> queuePushNotification({
    required String userName,
    required String message,
    required List<String> fcmTokens,
  }) async {
    await _localStorage.addToOfflineQueue({
      'type': 'push',
      'userName': userName,
      'message': message,
      'fcmTokens': fcmTokens,
      'queuedAt': DateTime.now().toIso8601String(),
    });

    AppLogger.info(
      'Push notification queued offline for '
      '${fcmTokens.length} tokens',
      tag: _tag,
    );
  }

  /// Queue a live tracking update for later sync.
  Future<void> queueLiveTrackingUpdate({
    required String rideId,
    required double latitude,
    required double longitude,
    required bool isEmergency,
  }) async {
    await _localStorage.addToOfflineQueue({
      'type': 'liveTrackingUpdate',
      'rideId': rideId,
      'latitude': latitude,
      'longitude': longitude,
      'isEmergency': isEmergency,
      'queuedAt': DateTime.now().toIso8601String(),
    });

    AppLogger.info(
      'Live tracking update queued offline',
      tag: _tag,
    );
  }

  /// Retrieve all queued items from the offline queue.
  List<Map> getOfflineQueue() {
    return _localStorage.getOfflineQueue();
  }

  /// Clear the offline queue after successful sync.
  Future<void> clearOfflineQueue() async {
    await _localStorage.clearOfflineQueue();
    AppLogger.info(
      'Offline queue cleared',
      tag: _tag,
    );
  }
}
