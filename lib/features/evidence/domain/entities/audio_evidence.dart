import 'package:flutter/foundation.dart';
import 'package:saferide/core/constants/app_dimensions.dart';

@immutable
class AudioEvidence {
  final String id;
  final String rideId;
  final String? alertId;
  final String? storageUrl;
  final int durationSeconds;
  final String encryptionKey;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isSaved;

  AudioEvidence({
    required this.id,
    required this.rideId,
    this.alertId,
    this.storageUrl,
    required this.durationSeconds,
    required this.encryptionKey,
    required this.createdAt,
    DateTime? expiresAt,
    this.isSaved = false,
  }) : expiresAt = expiresAt ??
            createdAt.add(
              const Duration(
                days: AppDimensions.dataRetentionDays,
              ),
            );

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isUploaded => storageUrl != null;

  Duration get remainingTime => isExpired
      ? Duration.zero
      : expiresAt.difference(DateTime.now());

  AudioEvidence copyWith({
    String? id,
    String? rideId,
    String? alertId,
    String? storageUrl,
    int? durationSeconds,
    String? encryptionKey,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isSaved,
  }) {
    return AudioEvidence(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      alertId: alertId ?? this.alertId,
      storageUrl: storageUrl ?? this.storageUrl,
      durationSeconds:
          durationSeconds ?? this.durationSeconds,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioEvidence &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AudioEvidence(id: $id, rideId: $rideId, '
      'duration: ${durationSeconds}s, '
      'expired: $isExpired)';
}
