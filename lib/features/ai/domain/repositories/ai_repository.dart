import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/ai/data/models/keyword_detection_result.dart';
import 'package:saferide/features/ai/data/models/threat_score_model.dart';
import 'package:saferide/features/ai/domain/entities/threat_assessment.dart';

/// Contract for AI-related data operations including
/// on-device keyword detection and threat scoring.
abstract class AiRepository {
  /// Run keyword detection on a raw audio chunk
  /// (PCM 16-bit, 16 kHz, mono).
  ///
  /// Returns the detection result if a keyword was
  /// found, or a result with empty keyword otherwise.
  Future<Either<Failure, KeywordDetectionResult>>
      detectKeywords(Uint8List audioChunk);

  /// Calculate an aggregate threat score from the
  /// provided list of [signals].
  Future<Either<Failure, ThreatScoreModel>>
      calculateThreatScore(
    List<ThreatSignal> signals,
  );

  /// Retrieve the most recent threat assessments
  /// (up to [limit]) stored locally for the current
  /// ride session.
  Future<Either<Failure, List<ThreatAssessment>>>
      getRecentAssessments({int limit = 10});
}
