import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/evidence/domain/entities/audio_evidence.dart';
import 'package:saferide/features/evidence/domain/entities/location_trail.dart';

abstract class EvidenceRepository {
  /// Encrypts and saves audio evidence files, uploads to
  /// Cloud Storage, and creates a Firestore metadata record.
  /// Returns the saved [AudioEvidence] with storage URL.
  Future<Either<Failure, AudioEvidence>> saveAudioEvidence({
    required String rideId,
    required String? alertId,
    required List<String> audioFilePaths,
    required int durationSeconds,
  });

  /// Retrieves audio evidence metadata for a specific ride.
  Future<Either<Failure, List<AudioEvidence>>>
      getAudioEvidence(String rideId);

  /// Retrieves the location trail for a specific ride.
  Future<Either<Failure, LocationTrail>> getLocationTrail(
    String rideId,
  );

  /// Deletes evidence by ID (both Cloud Storage file
  /// and Firestore metadata).
  Future<Either<Failure, void>> deleteEvidence(
    String evidenceId,
  );

  /// Marks evidence as permanently saved so it will not
  /// be auto-deleted after the retention period.
  Future<Either<Failure, AudioEvidence>> markAsSaved(
    String evidenceId,
  );

  /// Finds and deletes all evidence that has expired
  /// and has not been marked as saved.
  Future<Either<Failure, int>> deleteExpiredEvidence();

  /// Downloads the encrypted audio file and returns the
  /// decrypted local file path.
  Future<Either<Failure, String>> downloadEvidence(
    String evidenceId,
  );
}
