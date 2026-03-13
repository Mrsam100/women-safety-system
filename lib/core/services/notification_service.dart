import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:saferide/core/utils/logger.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    // Get FCM token
    _fcmToken = await _fcm.getToken();
    AppLogger.info(
      'FCM token: $_fcmToken',
      tag: 'NotificationService',
    );

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((token) {
      _fcmToken = token;
      AppLogger.info(
        'FCM token refreshed',
        tag: 'NotificationService',
      );
    });

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info(
      'Foreground message: ${message.notification?.title}',
      tag: 'NotificationService',
    );
    showLocalNotification(
      title: message.notification?.title ?? 'SafeRide',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool critical = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      critical ? 'emergency_channel' : 'default_channel',
      critical ? 'Emergency Alerts' : 'Notifications',
      importance: critical ? Importance.max : Importance.high,
      priority: critical ? Priority.max : Priority.high,
      playSound: true,
      enableVibration: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> showEmergencyNotification({
    required String userName,
    required String message,
  }) async {
    await showLocalNotification(
      title: 'EMERGENCY: $userName',
      body: message,
      critical: true,
    );
  }
}
