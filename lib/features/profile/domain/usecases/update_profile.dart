import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/profile/domain/entities/profile_entity.dart';
import 'package:saferide/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository _repository;

  const UpdateProfile(this._repository);

  Future<Either<Failure, ProfileEntity>> call(
    ProfileEntity entity,
  ) async {
    return await _repository.updateProfile(entity);
  }
}
