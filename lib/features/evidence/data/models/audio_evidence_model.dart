import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/features/evidence/domain/entities/audio_evidence.dart';

class AudioEvidenceModel {
  final String id;
  final String rideId;
  final String? alertId;
  final String? storageUrl;
  final int durationSeconds;
  final String encryptionKey;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isSaved;

  const AudioEvidenceModel({
    required this.id,
    required this.rideId,
    this.alertId,
    this.storageUrl,
    required this.durationSeconds,
    required this.encryptionKey,
    required this.createdAt,
    required this.expiresAt,
    this.isSaved = false,
  });

  factory AudioEvidenceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AudioEvidenceModel(
      id: json['id'] as String,
      rideId: json['rideId'] as String,
      alertId: json['alertId'] as String?,
      storageUrl: json['storageUrl'] as String?,
      durationSeconds: json['durationSeconds'] as int,
      encryptionKey:
          json['encryptionKey'] as String? ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: json['expiresAt'] is Timestamp
          ? (json['expiresAt'] as Timestamp).toDate()
          : DateTime.now(),
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'alertId': alertId,
      'storageUrl': storageUrl,
      'durationSeconds': durationSeconds,
      // encryptionKey is stored in flutter_secure_storage,
      // never written to Firestore
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isSaved': isSaved,
    };
  }

  AudioEvidence toEntity() {
    return AudioEvidence(
      id: id,
      rideId: rideId,
      alertId: alertId,
      storageUrl: storageUrl,
      durationSeconds: durationSeconds,
      encryptionKey: encryptionKey,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isSaved: isSaved,
    );
  }

  factory AudioEvidenceModel.fromEntity(
    AudioEvidence entity,
  ) {
    return AudioEvidenceModel(
      id: entity.id,
      rideId: entity.rideId,
      alertId: entity.alertId,
      storageUrl: entity.storageUrl,
      durationSeconds: entity.durationSeconds,
      encryptionKey: entity.encryptionKey,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
      isSaved: entity.isSaved,
    );
  }
}
