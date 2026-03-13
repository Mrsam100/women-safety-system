import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/safety/data/models/alert_model.dart';
import 'package:saferide/features/safety/domain/entities/alert.dart';

class SafetyRemoteDatasource {
  final FirebaseFirestore _firestore;

  static const _tag = 'SafetyRemoteDatasource';

  const SafetyRemoteDatasource({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  /// Create an alert document under:
  /// /users/{userId}/rides/{rideId}/alerts/{alertId}
  Future<void> createAlert({
    required String userId,
    required String rideId,
    required Alert alert,
  }) async {
    try {
      final model = AlertModel.fromEntity(alert);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('rides')
          .doc(rideId)
          .collection('alerts')
          .doc(alert.id)
          .set(model.toJson());

      AppLogger.info(
        'Alert ${alert.id} created in Firestore',
        tag: _tag,
      );
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firestore createAlert failed',
        tag: _tag,
        error: e,
      );
      throw ServerException(
        message: e.message ?? 'Failed to create alert',
        code: e.code,
      );
    }
  }

  /// Fetch all alerts for a ride, ordered by timestamp
  /// descending.
  Future<List<AlertModel>> getAlerts({
    required String userId,
    required String rideId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('rides')
          .doc(rideId)
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AlertModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firestore getAlerts failed',
        tag: _tag,
        error: e,
      );
      throw ServerException(
        message: e.message ?? 'Failed to fetch alerts',
        code: e.code,
      );
    }
  }

  /// Update the live tracking document to emergency mode.
  /// Path: /liveTracking/{rideId}
  Future<void> updateLiveTracking({
    required String rideId,
    required double latitude,
    required double longitude,
    required bool isEmergency,
  }) async {
    try {
      await _firestore
          .collection('liveTracking')
          .doc(rideId)
          .set(
        {
          'latitude': latitude,
          'longitude': longitude,
          'isEmergency': isEmergency,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      AppLogger.info(
        'Live tracking updated: isEmergency=$isEmergency',
        tag: _tag,
      );
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firestore updateLiveTracking failed',
        tag: _tag,
        error: e,
      );
      throw ServerException(
        message: e.message ??
            'Failed to update live tracking',
        code: e.code,
      );
    }
  }

  /// Resolve (mark as resolved) an alert.
  Future<void> resolveAlert({
    required String userId,
    required String rideId,
    required String alertId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('rides')
          .doc(rideId)
          .collection('alerts')
          .doc(alertId)
          .update({
        'resolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info(
        'Alert $alertId resolved',
        tag: _tag,
      );
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firestore resolveAlert failed',
        tag: _tag,
        error: e,
      );
      throw ServerException(
        message: e.message ?? 'Failed to resolve alert',
        code: e.code,
      );
    }
  }
}
