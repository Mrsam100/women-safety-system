import 'package:saferide/core/utils/logger.dart';
import 'package:telephony/telephony.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;

  /// Send SMS via native telephony (works offline).
  Future<void> sendNativeSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      await _telephony.sendSms(
        to: phoneNumber,
        message: message,
      );
      AppLogger.info(
        'SMS sent to $phoneNumber via native telephony',
        tag: 'SmsService',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to send native SMS to $phoneNumber',
        error: e,
        tag: 'SmsService',
      );
      rethrow;
    }
  }

  /// Send SMS to multiple numbers.
  Future<void> sendBulkSms({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    for (final number in phoneNumbers) {
      await sendNativeSms(
        phoneNumber: number,
        message: message,
      );
    }
  }

  /// Build emergency SMS message with tracking link.
  static String buildEmergencyMessage({
    required String userName,
    required double latitude,
    required double longitude,
    required String? trackingUrl,
  }) {
    final buffer = StringBuffer()
      ..writeln('EMERGENCY ALERT from $userName!')
      ..writeln(
        'Location: https://maps.google.com/'
        '?q=$latitude,$longitude',
      );

    if (trackingUrl != null) {
      buffer.writeln('Live tracking: $trackingUrl');
    }

    buffer.writeln('Please call immediately!');
    return buffer.toString();
  }

  /// Build low battery SMS message.
  static String buildLowBatteryMessage({
    required String userName,
    required double latitude,
    required double longitude,
    required int batteryLevel,
  }) {
    return 'LOW BATTERY ($batteryLevel%) - $userName\n'
        'Last known location: https://maps.google.com/'
        '?q=$latitude,$longitude';
  }
}
