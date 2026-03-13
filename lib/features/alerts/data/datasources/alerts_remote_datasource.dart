import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/core/constants/api_constants.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/features/alerts/data/models/alert_config_model.dart';

/// Remote datasource for alert configuration stored
/// in Firestore under each user's document.
class AlertsRemoteDatasource {
  final FirebaseFirestore _firestore;

  static const _tag = 'AlertsRemoteDatasource';
  static const _alertConfigField = 'alertConfig';

  AlertsRemoteDatasource({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  /// Reference to a user's document.
  DocumentReference<Map<String, dynamic>> _userRef(
    String userId,
  ) {
    return _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId);
  }

  /// Reference to a ride's alerts subcollection.
  CollectionReference<Map<String, dynamic>> _alertsRef(
    String userId,
    String rideId,
  ) {
    return _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.ridesSubcollection)
        .doc(rideId)
        .collection(ApiConstants.alertsSubcollection);
  }

  /// Fetch the user's alert configuration.
  /// Returns a default configuration if none exists.
  Future<AlertConfigModel> getAlertConfig({
    required String userId,
  }) async {
    try {
      final snapshot = await _userRef(userId).get();

      if (!snapshot.exists) {
        throw const ServerException(
          message: 'User not found',
          code: 'NOT_FOUND',
        );
      }

      final data = snapshot.data();
      if (data == null ||
          !data.containsKey(_alertConfigField)) {
        // Return default config and persist it
        final defaultConfig = const AlertConfigModel(
          id: 'default',
          routeDeviationEnabled: true,
          speedAnomalyEnabled: true,
          lowBatteryEnabled: true,
          deviationThresholdKm: 1.5,
          speedThresholdKmh: 100.0,
          nightTimeOnly: false,
          batteryThreshold: 10,
        );

        await _userRef(userId).update({
          _alertConfigField: defaultConfig.toJson(),
        });

        return defaultConfig;
      }

      return AlertConfigModel.fromJson(
        Map<String, dynamic>.from(
          data[_alertConfigField] as Map,
        ),
      );
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            e.message ?? 'Failed to get alert config',
        code: e.code,
      );
    }
  }

  /// Update the user's alert configuration.
  Future<AlertConfigModel> updateAlertConfig({
    required String userId,
    required AlertConfigModel config,
  }) async {
    try {
      await _userRef(userId).update({
        _alertConfigField: config.toJson(),
      });
      return config;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ??
            'Failed to update alert config',
        code: e.code,
      );
    }
  }

  /// Create an alert document in the ride's alerts
  /// subcollection.
  Future<void> createAlert({
    required String userId,
    required String rideId,
    required Map<String, dynamic> alertData,
  }) async {
    try {
      final alertId = alertData['id'] as String;
      await _alertsRef(userId, rideId)
          .doc(alertId)
          .set(alertData);
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            e.message ?? 'Failed to create alert',
        code: e.code,
      );
    }
  }

  /// Fetch all alerts for a ride.
  Future<List<Map<String, dynamic>>> getAlerts({
    required String userId,
    required String rideId,
  }) async {
    try {
      final snapshot = await _alertsRef(userId, rideId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data())
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            e.message ?? 'Failed to fetch alerts',
        code: e.code,
      );
    }
  }

  /// Resolve an alert (mark as handled).
  Future<void> resolveAlert({
    required String userId,
    required String rideId,
    required String alertId,
  }) async {
    try {
      await _alertsRef(userId, rideId)
          .doc(alertId)
          .update({
        'resolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            e.message ?? 'Failed to resolve alert',
        code: e.code,
      );
    }
  }
}
