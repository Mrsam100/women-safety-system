import 'package:dartz/dartz.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/services/battery_service.dart';
import 'package:saferide/core/services/location_service.dart';
import 'package:saferide/core/services/sms_service.dart';
import 'package:saferide/core/utils/logger.dart';

/// Result of a low battery check.
class LowBatteryResult {
  final bool shouldAlert;
  final int batteryLevel;
  final bool contactsNotified;

  const LowBatteryResult({
    required this.shouldAlert,
    required this.batteryLevel,
    this.contactsNotified = false,
  });
}

/// Check the device battery level and send the last
/// known location to all emergency contacts when the
/// battery drops below the configured threshold
/// (default 10%).
///
/// This use case ensures contacts are notified before
/// the device shuts down, so they have the rider's
/// last known position.
class CheckLowBattery {
  final BatteryService _batteryService;
  final LocationService _locationService;
  final SmsService _smsService;

  static const _tag = 'CheckLowBattery';

  /// Whether a low-battery alert has already been sent
  /// during this ride session. Prevents duplicate SMS.
  bool _hasAlerted = false;

  CheckLowBattery({
    required BatteryService batteryService,
    required LocationService locationService,
    required SmsService smsService,
  })  : _batteryService = batteryService,
        _locationService = locationService,
        _smsService = smsService;

  /// Reset internal state. Call when a ride starts
  /// or ends.
  void reset() {
    _hasAlerted = false;
  }

  /// Check the battery level and notify emergency
  /// contacts if it drops below [threshold].
  ///
  /// [userName] — display name for the SMS message.
  /// [contactPhones] — phone numbers of emergency
  ///   contacts.
  /// [threshold] — battery percentage threshold
  ///   (defaults to [AppDimensions.lowBatteryThreshold]).
  ///
  /// Returns [Right] with [LowBatteryResult].
  /// Returns [Left] with [Failure] on error.
  Future<Either<Failure, LowBatteryResult>> call({
    required String userName,
    required List<String> contactPhones,
    int? threshold,
  }) async {
    try {
      final batteryThreshold =
          threshold ?? AppDimensions.lowBatteryThreshold;

      final batteryLevel =
          await _batteryService.getBatteryLevel();

      if (batteryLevel > batteryThreshold ||
          _hasAlerted) {
        return Right(
          LowBatteryResult(
            shouldAlert: false,
            batteryLevel: batteryLevel,
          ),
        );
      }

      // Battery is below threshold and we haven't
      // alerted yet — send last known location.
      _hasAlerted = true;

      AppLogger.warning(
        'Low battery detected: $batteryLevel% '
        '(threshold: $batteryThreshold%)',
        tag: _tag,
      );

      // Capture current or last known position
      double latitude;
      double longitude;

      try {
        final position =
            await _locationService.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (_) {
        final lastPos = _locationService.lastPosition;
        latitude = lastPos?.latitude ?? 0.0;
        longitude = lastPos?.longitude ?? 0.0;
      }

      // Send low-battery SMS to all contacts
      bool contactsNotified = false;
      if (contactPhones.isNotEmpty) {
        try {
          final message =
              SmsService.buildLowBatteryMessage(
            userName: userName,
            latitude: latitude,
            longitude: longitude,
            batteryLevel: batteryLevel,
          );

          await _smsService.sendBulkSms(
            phoneNumbers: contactPhones,
            message: message,
          );

          contactsNotified = true;

          AppLogger.info(
            'Low battery alert sent to '
            '${contactPhones.length} contacts',
            tag: _tag,
          );
        } catch (e) {
          AppLogger.error(
            'Failed to send low battery SMS',
            tag: _tag,
            error: e,
          );
          // Do not rethrow — the check itself
          // succeeded, SMS delivery is best-effort.
        }
      }

      return Right(
        LowBatteryResult(
          shouldAlert: true,
          batteryLevel: batteryLevel,
          contactsNotified: contactsNotified,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Low battery check failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return Left(
        ServerFailure(
          message: 'Low battery check failed: $e',
          code: 'BATTERY_CHECK_FAILED',
        ),
      );
    }
  }

  /// Whether a low-battery alert has been sent during
  /// this session.
  bool get hasAlerted => _hasAlerted;
}
