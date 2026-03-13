import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/services/connectivity_service.dart';
import 'package:saferide/core/services/notification_service.dart';
import 'package:saferide/core/services/sms_service.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/safety/data/datasources/safety_local_datasource.dart';

/// Sends an emergency alert to all emergency contacts via
/// SMS (native telephony) and push notification.
///
/// Works offline: SMS is sent via native telephony, and
/// the push notification request is queued for when
/// connectivity returns.
class SendEmergencyAlert {
  final SmsService _smsService;
  final NotificationService _notificationService;
  final ConnectivityService _connectivityService;
  final SafetyLocalDatasource _localDatasource;

  static const _tag = 'SendEmergencyAlert';

  const SendEmergencyAlert({
    required SmsService smsService,
    required NotificationService notificationService,
    required ConnectivityService connectivityService,
    required SafetyLocalDatasource localDatasource,
  })  : _smsService = smsService,
        _notificationService = notificationService,
        _connectivityService = connectivityService,
        _localDatasource = localDatasource;

  /// Send alert to all contacts.
  ///
  /// [contactPhones] - phone numbers for SMS.
  /// [contactFcmTokens] - FCM tokens for push (contacts
  ///   who have the app).
  /// [userName] - sender display name.
  /// [latitude], [longitude] - current location.
  /// [trackingUrl] - optional live tracking link.
  Future<Either<Failure, void>> call({
    required List<String> contactPhones,
    List<String> contactFcmTokens = const [],
    required String userName,
    required double latitude,
    required double longitude,
    String? trackingUrl,
  }) async {
    try {
      final message = SmsService.buildEmergencyMessage(
        userName: userName,
        latitude: latitude,
        longitude: longitude,
        trackingUrl: trackingUrl,
      );

      // ── SMS (works offline via native telephony) ──
      final smsFuture = _smsService
          .sendBulkSms(
            phoneNumbers: contactPhones,
            message: message,
          )
          .then((_) {
        AppLogger.info(
          'SMS sent to ${contactPhones.length} contacts',
          tag: _tag,
        );
      }).catchError((e) {
        AppLogger.error(
          'SMS dispatch error',
          tag: _tag,
          error: e,
        );
      });

      // ── Push notification ──
      final pushFuture = _sendPushOrQueue(
        userName: userName,
        message: message,
        contactFcmTokens: contactFcmTokens,
      );

      // ── Local confirmation notification ──
      final localNotifFuture =
          _notificationService.showEmergencyNotification(
        userName: userName,
        message: 'Emergency alert sent to '
            '${contactPhones.length} contacts.',
      );

      await Future.wait([
        smsFuture,
        pushFuture,
        localNotifFuture,
      ]);

      AppLogger.info(
        'Emergency alert dispatched successfully',
        tag: _tag,
      );

      return const Right(null);
    } catch (e, st) {
      AppLogger.error(
        'Emergency alert failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return Left(
        ServerFailure(
          message: 'Emergency alert failed: $e',
          code: 'ALERT_DISPATCH_FAILED',
        ),
      );
    }
  }

  Future<void> _sendPushOrQueue({
    required String userName,
    required String message,
    required List<String> contactFcmTokens,
  }) async {
    if (contactFcmTokens.isEmpty) return;

    if (_connectivityService.isOnline) {
      // Push handled via Cloud Function triggered by
      // Firestore alert creation. We log intent here.
      AppLogger.info(
        'Push notifications will be sent via Cloud '
        'Function for ${contactFcmTokens.length} tokens',
        tag: _tag,
      );
    } else {
      // Queue for later sync
      await _localDatasource.queuePushNotification(
        userName: userName,
        message: message,
        fcmTokens: contactFcmTokens,
      );
      AppLogger.info(
        'Push notification queued offline',
        tag: _tag,
      );
    }
  }
}
