import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/evidence/data/datasources/evidence_local_datasource.dart';
import 'package:saferide/features/evidence/data/datasources/evidence_remote_datasource.dart';
import 'package:saferide/features/evidence/domain/entities/audio_evidence.dart';
import 'package:saferide/features/evidence/domain/entities/location_trail.dart';
import 'package:saferide/features/evidence/domain/repositories/evidence_repository.dart';

class EvidenceRepositoryImpl implements EvidenceRepository {
  final EvidenceRemoteDatasource _remoteDatasource;
  final EvidenceLocalDatasource _localDatasource;

  EvidenceRepositoryImpl({
    required EvidenceRemoteDatasource remoteDatasource,
    required EvidenceLocalDatasource localDatasource,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;

  @override
  Future<Either<Failure, AudioEvidence>> saveAudioEvidence({
    required String rideId,
    required String? alertId,
    required List<String> audioFilePaths,
    required int durationSeconds,
  }) async {
    try {
      final model =
          await _remoteDatasource.saveAudioEvidence(
        rideId: rideId,
        alertId: alertId,
        audioFilePaths: audioFilePaths,
        durationSeconds: durationSeconds,
      );

      // Cache metadata locally
      await _localDatasource.cacheAudioEvidenceMetadata(
        model.toJson(),
      );

      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(
        AuthFailure(message: e.message),
      );
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } on CacheException catch (e) {
      // Upload succeeded but caching failed — still
      // return success since evidence is saved remotely
      return Left(
        CacheFailure(message: e.message),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, List<AudioEvidence>>>
      getAudioEvidence(String rideId) async {
    try {
      final models =
          await _remoteDatasource.getAudioEvidence(
        rideId,
      );
      final entities =
          models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      // Fall back to cache
      try {
        final cached =
            await _localDatasource
                .getCachedAudioEvidence(rideId);
        if (cached.isNotEmpty) {
          final entities = cached
              .map((json) {
                // Re-parse timestamps from cached Hive
                // data which stores them differently
                return AudioEvidence(
                  id: json['id'] as String,
                  rideId: json['rideId'] as String,
                  alertId: json['alertId'] as String?,
                  storageUrl:
                      json['storageUrl'] as String?,
                  durationSeconds:
                      json['durationSeconds'] as int,
                  encryptionKey:
                      json['encryptionKey'] as String,
                  createdAt: DateTime.parse(
                    json['createdAt'].toString(),
                  ),
                  expiresAt: DateTime.parse(
                    json['expiresAt'].toString(),
                  ),
                  isSaved:
                      json['isSaved'] as bool? ?? false,
                );
              })
              .toList();
          return Right(entities);
        }
        return Left(
          ServerFailure(
            message: e.message,
            code: e.code,
          ),
        );
      } catch (_) {
        return Left(
          ServerFailure(
            message: e.message,
            code: e.code,
          ),
        );
      }
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, LocationTrail>> getLocationTrail(
    String rideId,
  ) async {
    try {
      // Try cache first
      final cached =
          await _localDatasource.getCachedLocationTrail(
        rideId,
      );
      if (cached != null) {
        return Right(cached.toEntity());
      }
    } on CacheException {
      // Cache miss, continue to remote
    }

    try {
      final model =
          await _remoteDatasource.getLocationTrail(
        rideId,
      );

      // Cache for future use
      try {
        await _localDatasource.cacheLocationTrail(model);
      } on CacheException {
        // Non-critical, ignore cache failure
      }

      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvidence(
    String evidenceId,
  ) async {
    try {
      await _remoteDatasource.deleteEvidence(evidenceId);

      // Clean up local cache
      try {
        await _localDatasource.clearCachedEvidence(
          evidenceId,
        );
      } on CacheException {
        // Non-critical
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, AudioEvidence>> markAsSaved(
    String evidenceId,
  ) async {
    try {
      final model =
          await _remoteDatasource.markAsSaved(
        evidenceId,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, int>> deleteExpiredEvidence() async {
    try {
      final count =
          await _remoteDatasource.deleteExpiredEvidence();
      return Right(count);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, String>> downloadEvidence(
    String evidenceId,
  ) async {
    try {
      final path =
          await _remoteDatasource.downloadEvidence(
        evidenceId,
      );
      return Right(path);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
