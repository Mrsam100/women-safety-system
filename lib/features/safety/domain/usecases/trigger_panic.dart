import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/services/audio_service.dart';
import 'package:saferide/core/services/connectivity_service.dart';
import 'package:saferide/core/services/local_storage_service.dart';
import 'package:saferide/core/services/location_service.dart';
import 'package:saferide/core/services/notification_service.dart';
import 'package:saferide/core/services/sms_service.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/safety/data/datasources/safety_local_datasource.dart';
import 'package:saferide/features/safety/data/datasources/safety_remote_datasource.dart';
import 'package:saferide/features/safety/domain/entities/alert.dart';

/// THE MOST CRITICAL FILE IN THE APP.
///
/// Orchestrates the full panic sequence:
/// 1. GPS capture (current location)
/// 2. Audio evidence save (last 30s, AES-256 encrypted)
/// 3. SMS dispatch to all emergency contacts
/// 4. Firestore alert creation
/// 5. Push notification to contacts with the app
/// 6. Live tracking update (isEmergency: true)
///
/// All steps run in parallel where possible.
/// Must work offline (queue and sync later).
class TriggerPanic {
  final LocationService _locationService;
  final AudioService _audioService;
  final SmsService _smsService;
  final NotificationService _notificationService;
  final ConnectivityService _connectivityService;
  final LocalStorageService _localStorageService;
  final SafetyRemoteDatasource _remoteDatasource;
  final SafetyLocalDatasource _localDatasource;

  static const _tag = 'TriggerPanic';

  const TriggerPanic({
    required LocationService locationService,
    required AudioService audioService,
    required SmsService smsService,
    required NotificationService notificationService,
    required ConnectivityService connectivityService,
    required LocalStorageService localStorageService,
    required SafetyRemoteDatasource remoteDatasource,
    required SafetyLocalDatasource localDatasource,
  })  : _locationService = locationService,
        _audioService = audioService,
        _smsService = smsService,
        _notificationService = notificationService,
        _connectivityService = connectivityService,
        _localStorageService = localStorageService,
        _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;

  /// Execute the full panic sequence.
  ///
  /// [userId] - the authenticated user's ID.
  /// [rideId] - the current ride ID.
  /// [contactPhones] - phone numbers of emergency contacts.
  /// [contactFcmTokens] - FCM tokens of contacts who have
  ///   the app installed (for push notifications).
  /// [userName] - display name for SMS / push messages.
  /// [encryptionKey] - 32-byte AES-256 key (base64).
  Future<Either<Failure, Alert>> call({
    required String userId,
    required String rideId,
    required List<String> contactPhones,
    List<String> contactFcmTokens = const [],
    required String userName,
    required String encryptionKey,
  }) async {
    try {
      AppLogger.critical(
        'PANIC TRIGGERED for user $userId, ride $rideId',
        tag: _tag,
      );

      final alertId = const Uuid().v4();
      final now = DateTime.now();
      final isOnline = _connectivityService.isOnline;

      // ──────────────────────────────────────────────
      // PHASE 1 — Parallel: GPS + Audio evidence
      // These are independent and can run concurrently.
      // ──────────────────────────────────────────────

      final results = await Future.wait([
        _captureLocation(),
        _saveEncryptedAudio(
          userId: userId,
          rideId: rideId,
          alertId: alertId,
          encryptionKey: encryptionKey,
        ),
      ]);

      final locationResult =
          results[0] as Map<String, double>;
      final audioPath = results[1] as String?;

      final latitude = locationResult['latitude']!;
      final longitude = locationResult['longitude']!;

      // Build the alert entity
      final alert = Alert(
        id: alertId,
        type: AlertType.panic,
        severity: AlertSeverity.critical,
        latitude: latitude,
        longitude: longitude,
        details: {
          'rideId': rideId,
          'userId': userId,
          'audioEvidencePath': audioPath,
          'triggeredAt': now.toIso8601String(),
          'isOnline': isOnline,
        },
        threatScore: 100.0,
        resolved: false,
        notifiedContacts: contactPhones,
        timestamp: now,
      );

      // Build SMS message
      final smsMessage = SmsService.buildEmergencyMessage(
        userName: userName,
        latitude: latitude,
        longitude: longitude,
        trackingUrl: isOnline
            ? 'https://saferide.app/track/$rideId'
            : null,
      );

      // ──────────────────────────────────────────────
      // PHASE 2 — Parallel: SMS + Alert + Push + Live
      // All independent operations fire together.
      // ──────────────────────────────────────────────

      await Future.wait<void>([
        // 1) SMS to all contacts (native telephony works
        //    offline)
        _sendSmsToContacts(
          contactPhones: contactPhones,
          message: smsMessage,
        ),

        // 2) Create alert in Firestore or queue offline
        _persistAlert(
          alert: alert,
          userId: userId,
          rideId: rideId,
          isOnline: isOnline,
        ),

        // 3) Push notification (only when online)
        if (isOnline && contactFcmTokens.isNotEmpty)
          _sendPushNotifications(
            userName: userName,
            contactFcmTokens: contactFcmTokens,
          ),

        // 4) Update live tracking to emergency mode
        _updateLiveTracking(
          rideId: rideId,
          latitude: latitude,
          longitude: longitude,
          isOnline: isOnline,
        ),
      ]);

      // Show local emergency notification on this device
      await _notificationService.showEmergencyNotification(
        userName: userName,
        message: 'Emergency alert sent to '
            '${contactPhones.length} contacts.',
      );

      AppLogger.critical(
        'PANIC SEQUENCE COMPLETE — alert $alertId',
        tag: _tag,
      );

      return Right(alert);
    } catch (e, st) {
      AppLogger.critical(
        'PANIC SEQUENCE FAILED',
        tag: _tag,
        error: e,
        stackTrace: st,
      );

      // Even if orchestration fails, attempt SMS as
      // last-resort (fire-and-forget).
      _attemptLastResortSms(
        contactPhones: contactPhones,
        userName: userName,
      );

      return Left(
        ServerFailure(
          message: 'Panic trigger failed: $e',
          code: 'PANIC_FAILED',
        ),
      );
    }
  }

  // ────────────────────────────────────────────────────
  // Private helpers
  // ────────────────────────────────────────────────────

  /// Capture the current GPS position. Falls back to the
  /// last known position when GPS acquisition fails.
  Future<Map<String, double>> _captureLocation() async {
    try {
      final position =
          await _locationService.getCurrentPosition();
      AppLogger.info(
        'GPS captured: ${position.latitude}, '
        '${position.longitude}',
        tag: _tag,
      );
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      AppLogger.warning(
        'GPS acquisition failed, using last known position',
        tag: _tag,
      );
      final last = _locationService.lastPosition;
      if (last != null) {
        return {
          'latitude': last.latitude,
          'longitude': last.longitude,
        };
      }
      // Absolute fallback — 0,0 is better than crashing
      return {'latitude': 0.0, 'longitude': 0.0};
    }
  }

  /// Stop the audio buffer, concatenate chunks, encrypt
  /// with AES-256, and write to a secure location.
  /// Returns the encrypted file path, or null on failure.
  Future<String?> _saveEncryptedAudio({
    required String userId,
    required String rideId,
    required String alertId,
    required String encryptionKey,
  }) async {
    try {
      final audioPaths =
          await _audioService.stopAndGetBuffer();
      if (audioPaths.isEmpty) {
        AppLogger.warning(
          'No audio chunks to save',
          tag: _tag,
        );
        return null;
      }

      // Concatenate all chunk bytes
      final allBytes = <int>[];
      for (final path in audioPaths) {
        final file = File(path);
        if (await file.exists()) {
          allBytes.addAll(await file.readAsBytes());
        }
      }

      if (allBytes.isEmpty) return null;

      // AES-256 encryption
      final key = enc.Key.fromBase64(encryptionKey);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(
        enc.AES(key, mode: enc.AESMode.cbc),
      );
      final encrypted = encrypter.encryptBytes(
        allBytes,
        iv: iv,
      );

      // Write encrypted file
      final dir = await getApplicationDocumentsDirectory();
      final encryptedDir = Directory(
        '${dir.path}/audio_evidence/$rideId',
      );
      if (!await encryptedDir.exists()) {
        await encryptedDir.create(recursive: true);
      }

      final encryptedPath =
          '${encryptedDir.path}/$alertId.enc';
      final encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsBytes(encrypted.bytes);

      // Store the IV alongside the file for decryption
      final ivPath = '${encryptedDir.path}/$alertId.iv';
      await File(ivPath).writeAsBytes(iv.bytes);

      AppLogger.info(
        'Audio evidence encrypted: $encryptedPath '
        '(${allBytes.length} bytes)',
        tag: _tag,
      );

      return encryptedPath;
    } catch (e) {
      AppLogger.error(
        'Failed to save encrypted audio',
        tag: _tag,
        error: e,
      );
      return null;
    }
  }

  /// Send SMS to all emergency contacts using native
  /// telephony (works offline).
  Future<void> _sendSmsToContacts({
    required List<String> contactPhones,
    required String message,
  }) async {
    try {
      await _smsService.sendBulkSms(
        phoneNumbers: contactPhones,
        message: message,
      );
      AppLogger.info(
        'SMS sent to ${contactPhones.length} contacts',
        tag: _tag,
      );
    } catch (e) {
      AppLogger.error(
        'SMS dispatch failed',
        tag: _tag,
        error: e,
      );
      // Do not rethrow — other parallel tasks must
      // continue.
    }
  }

  /// Persist the alert to Firestore when online, or queue
  /// it locally when offline.
  Future<void> _persistAlert({
    required Alert alert,
    required String userId,
    required String rideId,
    required bool isOnline,
  }) async {
    try {
      if (isOnline) {
        await _remoteDatasource.createAlert(
          userId: userId,
          rideId: rideId,
          alert: alert,
        );
        AppLogger.info(
          'Alert persisted to Firestore',
          tag: _tag,
        );
      } else {
        await _localDatasource.queueAlert(
          userId: userId,
          rideId: rideId,
          alert: alert,
        );
        AppLogger.info(
          'Alert queued locally (offline)',
          tag: _tag,
        );
      }
    } catch (e) {
      // Fallback: always queue locally on any error
      AppLogger.error(
        'Remote persist failed, queuing locally',
        tag: _tag,
        error: e,
      );
      await _localDatasource.queueAlert(
        userId: userId,
        rideId: rideId,
        alert: alert,
      );
    }
  }

  /// Send push notifications to contacts who have the app.
  Future<void> _sendPushNotifications({
    required String userName,
    required List<String> contactFcmTokens,
  }) async {
    try {
      // Push notifications are dispatched via Cloud
      // Function triggered by the Firestore alert write.
      // We also fire a local notification to confirm.
      AppLogger.info(
        'Push notifications triggered for '
        '${contactFcmTokens.length} tokens',
        tag: _tag,
      );
    } catch (e) {
      AppLogger.error(
        'Push notification failed',
        tag: _tag,
        error: e,
      );
    }
  }

  /// Mark the live tracking document as an emergency.
  Future<void> _updateLiveTracking({
    required String rideId,
    required double latitude,
    required double longitude,
    required bool isOnline,
  }) async {
    try {
      if (isOnline) {
        await _remoteDatasource.updateLiveTracking(
          rideId: rideId,
          latitude: latitude,
          longitude: longitude,
          isEmergency: true,
        );
        AppLogger.info(
          'Live tracking updated to emergency',
          tag: _tag,
        );
      } else {
        await _localDatasource.queueLiveTrackingUpdate(
          rideId: rideId,
          latitude: latitude,
          longitude: longitude,
          isEmergency: true,
        );
        AppLogger.info(
          'Live tracking update queued (offline)',
          tag: _tag,
        );
      }
    } catch (e) {
      AppLogger.error(
        'Live tracking update failed',
        tag: _tag,
        error: e,
      );
    }
  }

  /// Fire-and-forget SMS as an absolute last resort when
  /// the full sequence fails.
  void _attemptLastResortSms({
    required List<String> contactPhones,
    required String userName,
  }) {
    try {
      final lastPos = _locationService.lastPosition;
      final lat = lastPos?.latitude ?? 0.0;
      final lon = lastPos?.longitude ?? 0.0;

      final message = SmsService.buildEmergencyMessage(
        userName: userName,
        latitude: lat,
        longitude: lon,
        trackingUrl: null,
      );

      _smsService
          .sendBulkSms(
            phoneNumbers: contactPhones,
            message: message,
          )
          .catchError((_) {});
    } catch (_) {
      // Swallow — nothing else we can do.
    }
  }
}
