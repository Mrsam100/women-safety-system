import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/core/constants/api_constants.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/features/ride/data/models/ride_model.dart';
import 'package:saferide/features/ride/data/models/route_point_model.dart';

class RideRemoteDatasource {
  final FirebaseFirestore _firestore;

  static const _tag = 'RideRemoteDatasource';

  RideRemoteDatasource({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  /// Reference to a user's rides subcollection.
  CollectionReference<Map<String, dynamic>> _ridesRef(
    String userId,
  ) {
    return _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.ridesSubcollection);
  }

  /// Reference to a ride's location trail.
  CollectionReference<Map<String, dynamic>>
      _locationTrailRef(
    String userId,
    String rideId,
  ) {
    return _ridesRef(userId)
        .doc(rideId)
        .collection(
          ApiConstants.locationTrailSubcollection,
        );
  }

  /// Reference to the top-level live tracking document.
  DocumentReference<Map<String, dynamic>>
      _liveTrackingRef(String rideId) {
    return _firestore
        .collection(ApiConstants.liveTrackingCollection)
        .doc(rideId);
  }

  /// Create a new ride document and initialise live
  /// tracking.
  Future<RideModel> createRide(RideModel model) async {
    try {
      final docRef = _ridesRef(model.userId).doc(
        model.id,
      );
      await docRef.set(model.toJson());

      // Initialise live tracking document
      await _liveTrackingRef(model.id).set({
        'rideId': model.id,
        'userId': model.userId,
        'latitude': model.startLatitude,
        'longitude': model.startLongitude,
        'isEmergency': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return model;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to create ride',
        code: e.code,
      );
    }
  }

  /// Update ride fields (e.g. status, endedAt).
  Future<RideModel> updateRide({
    required String userId,
    required String rideId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = _ridesRef(userId).doc(rideId);
      await docRef.update(data);

      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        throw const ServerException(
          message: 'Ride not found after update',
        );
      }
      return RideModel.fromJson(snapshot.data()!);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to update ride',
        code: e.code,
      );
    }
  }

  /// Fetch a single ride.
  Future<RideModel> getRide({
    required String userId,
    required String rideId,
  }) async {
    try {
      final snapshot =
          await _ridesRef(userId).doc(rideId).get();
      if (!snapshot.exists) {
        throw const ServerException(
          message: 'Ride not found',
          code: 'NOT_FOUND',
        );
      }
      return RideModel.fromJson(snapshot.data()!);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch ride',
        code: e.code,
      );
    }
  }

  /// Fetch ride history, ordered by startedAt
  /// descending.
  Future<List<RideModel>> getRideHistory({
    required String userId,
    int limit = 20,
    DateTime? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _ridesRef(userId)
              .orderBy('startedAt', descending: true)
              .limit(limit);

      if (startAfter != null) {
        query = query.startAfter(
          [Timestamp.fromDate(startAfter)],
        );
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => RideModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            e.message ?? 'Failed to fetch ride history',
        code: e.code,
      );
    }
  }

  /// Add a route point to the location trail
  /// subcollection and update live tracking.
  Future<void> addRoutePoint({
    required String userId,
    required String rideId,
    required RoutePointModel point,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add to location trail
      batch.set(
        _locationTrailRef(userId, rideId).doc(point.id),
        point.toJson(),
      );

      // Update live tracking
      batch.update(
        _liveTrackingRef(rideId),
        {
          'latitude': point.latitude,
          'longitude': point.longitude,
          'speed': point.speed,
          'bearing': point.bearing,
          'batteryLevel': point.batteryLevel,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            e.message ?? 'Failed to add route point',
        code: e.code,
      );
    }
  }

  /// Get all route points for a ride, ordered by
  /// timestamp ascending.
  Future<List<RoutePointModel>> getRoutePoints({
    required String userId,
    required String rideId,
  }) async {
    try {
      final snapshot = await _locationTrailRef(
        userId,
        rideId,
      ).orderBy('timestamp').get();

      return snapshot.docs
          .map(
            (doc) =>
                RoutePointModel.fromJson(doc.data()),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            e.message ?? 'Failed to fetch route points',
        code: e.code,
      );
    }
  }

  /// Delete the live tracking document when the ride
  /// ends.
  Future<void> deleteLiveTracking(String rideId) async {
    try {
      await _liveTrackingRef(rideId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ??
            'Failed to delete live tracking',
        code: e.code,
      );
    }
  }
}
