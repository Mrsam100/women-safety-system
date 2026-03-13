import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:saferide/features/profile/data/models/profile_model.dart';
import 'package:saferide/features/profile/domain/entities/profile_entity.dart';
import 'package:saferide/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _remoteDatasource;

  ProfileRepositoryImpl(this._remoteDatasource);

  @override
  Future<Either<Failure, ProfileEntity>> getProfile(
    String uid,
  ) async {
    try {
      final model =
          await _remoteDatasource.getProfile(uid);
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
  Future<Either<Failure, ProfileEntity>> updateProfile(
    ProfileEntity entity,
  ) async {
    try {
      final model = ProfileModel.fromEntity(entity);
      final updated =
          await _remoteDatasource.updateProfile(model);
      return Right(updated.toEntity());
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
  Future<Either<Failure, String>> uploadPhoto({
    required String uid,
    required String filePath,
  }) async {
    try {
      final url = await _remoteDatasource.uploadPhoto(
        uid: uid,
        filePath: filePath,
      );
      return Right(url);
    } on ServerException catch (e) {
      return Left(
        StorageFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        StorageFailure(message: e.toString()),
      );
    }
  }
}
