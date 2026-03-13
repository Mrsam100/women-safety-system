import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/ai/data/datasources/tflite_datasource.dart';
import 'package:saferide/features/ai/data/models/keyword_detection_result.dart';
import 'package:saferide/features/ai/data/models/threat_score_model.dart';
import 'package:saferide/features/ai/domain/entities/keyword_detection.dart';
import 'package:saferide/features/ai/domain/entities/threat_assessment.dart';
import 'package:saferide/features/ai/domain/repositories/ai_repository.dart';

/// Implementation of [AiRepository] backed by the
/// on-device TFLite datasource for keyword detection
/// and in-memory storage for threat assessments.
class AiRepositoryImpl implements AiRepository {
  static const _tag = 'AiRepositoryImpl';

  final TfliteDatasource _tfliteDatasource;

  /// In-memory cache of recent assessments for the
  /// current ride session.
  final List<ThreatAssessment> _assessmentCache = [];

  /// Maximum number of assessments to keep in cache.
  static const int _maxCacheSize = 100;

  AiRepositoryImpl({
    required TfliteDatasource tfliteDatasource,
  }) : _tfliteDatasource = tfliteDatasource;

  @override
  Future<Either<Failure, KeywordDetection>>
      detectKeywords(Uint8List audioChunk) async {
    try {
      final result =
          await _tfliteDatasource.detectKeywords(
        audioChunk,
      );

      if (result.isDetected) {
        AppLogger.info(
          'Keyword detected via repository: '
          '"${result.keyword}" '
          '(${result.confidence.toStringAsFixed(2)})',
          tag: _tag,
        );
      }

      return Right(result.toEntity());
    } catch (e, st) {
      AppLogger.error(
        'Keyword detection failed in repository',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return Left(
        AudioFailure(
          message: 'Keyword detection failed: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ThreatAssessment>>
      calculateThreatScore(
    List<ThreatSignal> signals,
  ) async {
    try {
      // Build the model from raw signals
      final signalModels = signals
          .map(
            (s) => ThreatSignalModel(
              description: s.description,
              points: s.points,
            ),
          )
          .toList();

      final rawScore = signals.fold<int>(
        0,
        (sum, s) => sum + s.points,
      );
      final score = rawScore.clamp(0, 100);
      final now = DateTime.now();

      final model = ThreatScoreModel(
        score: score,
        signals: signalModels,
        timestamp: now,
      );

      // Cache the assessment
      final assessment = model.toEntity();
      _addToCache(assessment);

      AppLogger.debug(
        'Threat score calculated: $score '
        '(${signals.length} signals)',
        tag: _tag,
      );

      return Right(model.toEntity());
    } catch (e, st) {
      AppLogger.error(
        'Threat score calculation failed '
        'in repository',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return Left(
        ServerFailure(
          message:
              'Threat score calculation failed: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<ThreatAssessment>>>
      getRecentAssessments({int limit = 10}) async {
    try {
      final count = limit.clamp(1, _assessmentCache.length);
      final recent = _assessmentCache.length <= count
          ? List<ThreatAssessment>.from(_assessmentCache)
          : _assessmentCache
              .sublist(_assessmentCache.length - count);

      return Right(recent);
    } catch (e, st) {
      AppLogger.error(
        'Failed to retrieve recent assessments',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return Left(
        CacheFailure(
          message:
              'Failed to retrieve assessments: $e',
        ),
      );
    }
  }

  /// Add an assessment to the in-memory cache,
  /// evicting the oldest if the cache is full.
  void _addToCache(ThreatAssessment assessment) {
    if (_assessmentCache.length >= _maxCacheSize) {
      _assessmentCache.removeAt(0);
    }
    _assessmentCache.add(assessment);
  }

  /// Clear the assessment cache. Call when a ride ends.
  void clearCache() {
    _assessmentCache.clear();
    AppLogger.debug(
      'Assessment cache cleared',
      tag: _tag,
    );
  }

  /// Initialize the TFLite model. Call during ride
  /// start.
  Future<bool> initializeModel() async {
    return await _tfliteDatasource.loadModel();
  }

  /// Release model resources. Call during ride end.
  void disposeModel() {
    _tfliteDatasource.dispose();
  }
}
