import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/evidence/domain/entities/audio_evidence.dart';
import 'package:saferide/features/evidence/domain/repositories/evidence_repository.dart';

class SaveAudioEvidence {
  final EvidenceRepository _repository;

  const SaveAudioEvidence(this._repository);

  /// Encrypts audio files with AES-256, uploads to
  /// Firebase Cloud Storage, and creates a Firestore
  /// metadata record.
  ///
  /// [rideId] - The ride this evidence belongs to.
  /// [alertId] - Optional alert that triggered the save.
  /// [audioFilePaths] - Local file paths of audio chunks.
  /// [durationSeconds] - Total duration of the audio.
  Future<Either<Failure, AudioEvidence>> call({
    required String rideId,
    String? alertId,
    required List<String> audioFilePaths,
    required int durationSeconds,
  }) async {
    if (audioFilePaths.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'No audio files provided',
        ),
      );
    }

    if (durationSeconds <= 0) {
      return const Left(
        ValidationFailure(
          message: 'Duration must be positive',
        ),
      );
    }

    return await _repository.saveAudioEvidence(
      rideId: rideId,
      alertId: alertId,
      audioFilePaths: audioFilePaths,
      durationSeconds: durationSeconds,
    );
  }
}
