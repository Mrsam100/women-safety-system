import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/profile/domain/entities/profile_entity.dart';
import 'package:saferide/features/profile/domain/repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository _repository;

  const GetProfile(this._repository);

  Future<Either<Failure, ProfileEntity>> call(
    String uid,
  ) async {
    return await _repository.getProfile(uid);
  }
}
