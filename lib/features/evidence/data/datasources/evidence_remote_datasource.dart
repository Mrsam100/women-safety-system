import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:saferide/core/constants/api_constants.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/core/services/local_storage_service.dart';
import 'package:saferide/features/evidence/data/models/audio_evidence_model.dart';
import 'package:saferide/features/evidence/data/models/location_trail_model.dart';
import 'package:uuid/uuid.dart';

/// Remote datasource for evidence management.
/// Handles Firebase Cloud Storage uploads for encrypted
/// audio and Firestore for metadata.
class EvidenceRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final LocalStorageService _localStorage;

  EvidenceRemoteDatasource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
    required LocalStorageService localStorage,
  })  : _firestore = firestore,
        _storage = storage,
        _auth = auth,
        _localStorage = localStorage;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        message: 'User not authenticated',
      );
    }
    return user.uid;
  }

  /// Encrypts audio files with AES-256, uploads to
  /// Cloud Storage, and creates Firestore metadata.
  Future<AudioEvidenceModel> saveAudioEvidence({
    required String rideId,
    required String? alertId,
    required List<String> audioFilePaths,
    required int durationSeconds,
  }) async {
    try {
      final evidenceId = const Uuid().v4();
      final now = DateTime.now();
      final expiresAt = now.add(
        const Duration(
          days: AppDimensions.dataRetentionDays,
        ),
      );

      // Generate AES-256 key and IV
      final key = encrypt_pkg.Key.fromSecureRandom(32);
      final iv = encrypt_pkg.IV.fromSecureRandom(16);
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(
          key,
          mode: encrypt_pkg.AESMode.cbc,
        ),
      );

      // Read and concatenate all audio file bytes
      final audioBytes = <int>[];
      for (final path in audioFilePaths) {
        final file = File(path);
        if (await file.exists()) {
          audioBytes.addAll(await file.readAsBytes());
        }
      }

      if (audioBytes.isEmpty) {
        throw const ServerException(
          message: 'No audio data to encrypt',
        );
      }

      // Encrypt the audio data
      final encrypted = encrypter.encryptBytes(
        audioBytes,
        iv: iv,
      );

      // Upload encrypted audio to Cloud Storage
      final storagePath =
          '${ApiConstants.audioEvidencePath}/'
          '$_userId/$rideId/$evidenceId.enc';

      final ref = _storage.ref().child(storagePath);
      await ref.putData(
        Uint8List.fromList(encrypted.bytes),
        SettableMetadata(
          contentType: 'application/octet-stream',
          customMetadata: {
            'rideId': rideId,
            'iv': iv.base64,
            'evidenceId': evidenceId,
          },
        ),
      );

      final storageUrl = await ref.getDownloadURL();

      // Store encryption key in secure storage (on-device
      // only — never sent to Firestore)
      final keyBase64 = key.base64;
      await _localStorage.saveSecure(
        'enc_key_$evidenceId',
        keyBase64,
      );

      // Create Firestore metadata record (no encryption key)
      final model = AudioEvidenceModel(
        id: evidenceId,
        rideId: rideId,
        alertId: alertId,
        storageUrl: storageUrl,
        durationSeconds: durationSeconds,
        encryptionKey: '', // key is in secure storage
        createdAt: now,
        expiresAt: expiresAt,
      );

      await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(_userId)
          .collection(
            ApiConstants.audioEvidenceSubcollection,
          )
          .doc(evidenceId)
          .set(model.toJson());

      return model;
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Firebase error: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(
        message:
            'Failed to save audio evidence: $e',
      );
    }
  }

  /// Retrieves all audio evidence metadata for a ride.
  Future<List<AudioEvidenceModel>> getAudioEvidence(
    String rideId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(_userId)
          .collection(
            ApiConstants.audioEvidenceSubcollection,
          )
          .where('rideId', isEqualTo: rideId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AudioEvidenceModel.fromJson(
                doc.data(),
              ))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: 'Failed to fetch evidence: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Retrieves the location trail for a ride from the
  /// locationTrail subcollection.
  Future<LocationTrailModel> getLocationTrail(
    String rideId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(_userId)
          .collection(ApiConstants.ridesSubcollection)
          .doc(rideId)
          .collection(
            ApiConstants.locationTrailSubcollection,
          )
          .orderBy('timestamp')
          .get();

      final points = snapshot.docs
          .map((doc) => TrailPointModel.fromJson(
                doc.data(),
              ))
          .toList();

      // Calculate total distance and duration
      double totalDistance = 0;
      int durationMillis = 0;

      if (points.length >= 2) {
        durationMillis = points.last.timestamp
            .difference(points.first.timestamp)
            .inMilliseconds;

        // Sum up distances between consecutive points
        for (int i = 1; i < points.length; i++) {
          totalDistance += _haversineDistance(
            points[i - 1].latitude,
            points[i - 1].longitude,
            points[i].latitude,
            points[i].longitude,
          );
        }
      }

      return LocationTrailModel(
        id: rideId,
        rideId: rideId,
        points: points,
        totalDistance: totalDistance,
        durationMillis: durationMillis,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            'Failed to fetch location trail: '
            '${e.message}',
        code: e.code,
      );
    }
  }

  /// Deletes an evidence record and its Cloud Storage
  /// file.
  Future<void> deleteEvidence(String evidenceId) async {
    try {
      // Get the metadata first for the storage URL
      final doc = await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(_userId)
          .collection(
            ApiConstants.audioEvidenceSubcollection,
          )
          .doc(evidenceId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final storageUrl = data['storageUrl'] as String?;

      // Delete from Cloud Storage
      if (storageUrl != null) {
        try {
          final ref =
              _storage.refFromURL(storageUrl);
          await ref.delete();
        } on FirebaseException {
          // Storage file may already be deleted
        }
      }

      // Delete Firestore record
      await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(_userId)
          .collection(
            ApiConstants.audioEvidenceSubcollection,
          )
          .doc(evidenceId)
          .delete();

      // Remove encryption key from secure storage
      await _localStorage.deleteSecure(
        'enc_key_$evidenceId',
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            'Failed to delete evidence: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Marks evidence as permanently saved.
  Future<AudioEvidenceModel> markAsSaved(
    String evidenceId,
  ) async {
    try {
      final docRef = _firestore
          .collection(ApiConstants.usersCollection)
          .doc(_userId)
          .collection(
            ApiConstants.audioEvidenceSubcollection,
          )
          .doc(evidenceId);

      await docRef.update({'isSaved': true});

      final updated = await docRef.get();
      return AudioEvidenceModel.fromJson(
        updated.data()!,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            'Failed to mark as saved: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Finds and deletes all expired, unsaved evidence.
  /// Returns the count of deleted records.
  Future<int> deleteExpiredEvidence() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(_userId)
          .collection(
            ApiConstants.audioEvidenceSubcollection,
          )
          .where('isSaved', isEqualTo: false)
          .where(
            'expiresAt',
            isLessThan: Timestamp.fromDate(now),
          )
          .get();

      int deletedCount = 0;
      for (final doc in snapshot.docs) {
        await deleteEvidence(doc.id);
        deletedCount++;
      }

      return deletedCount;
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            'Failed to delete expired evidence: '
            '${e.message}',
        code: e.code,
      );
    }
  }

  /// Downloads encrypted audio from Cloud Storage,
  /// decrypts it, and saves to a temporary local file.
  /// Returns the path to the decrypted file.
  Future<String> downloadEvidence(
    String evidenceId,
  ) async {
    try {
      final doc = await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(_userId)
          .collection(
            ApiConstants.audioEvidenceSubcollection,
          )
          .doc(evidenceId)
          .get();

      if (!doc.exists) {
        throw const ServerException(
          message: 'Evidence record not found',
        );
      }

      final model =
          AudioEvidenceModel.fromJson(doc.data()!);

      if (model.storageUrl == null) {
        throw const ServerException(
          message: 'Evidence file not uploaded yet',
        );
      }

      // Download encrypted bytes
      final ref =
          _storage.refFromURL(model.storageUrl!);
      final metadata = await ref.getMetadata();
      final ivBase64 =
          metadata.customMetadata?['iv'] ?? '';

      final encryptedData = await ref.getData();
      if (encryptedData == null) {
        throw const ServerException(
          message: 'Failed to download evidence file',
        );
      }

      // Retrieve encryption key from secure storage
      final keyBase64 = await _localStorage.getSecure(
        'enc_key_$evidenceId',
      );
      if (keyBase64 == null || keyBase64.isEmpty) {
        throw const ServerException(
          message: 'Encryption key not found in '
              'secure storage',
        );
      }
      final key = encrypt_pkg.Key.fromBase64(keyBase64);
      final iv = encrypt_pkg.IV.fromBase64(ivBase64);
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(
          key,
          mode: encrypt_pkg.AESMode.cbc,
        ),
      );

      final decrypted = encrypter.decryptBytes(
        encrypt_pkg.Encrypted(encryptedData),
        iv: iv,
      );

      // Save to temporary file
      final tempDir = Directory.systemTemp;
      final outputPath =
          '${tempDir.path}/evidence_$evidenceId.wav';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(decrypted);

      return outputPath;
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            'Failed to download evidence: '
            '${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(
        message:
            'Failed to download evidence: $e',
      );
    }
  }

  /// Haversine formula to calculate distance between
  /// two GPS coordinates in kilometers.
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) *
            math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(
      math.sqrt(a),
      math.sqrt(1 - a),
    );

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * 3.14159265358979323846 / 180.0;
  }
}
