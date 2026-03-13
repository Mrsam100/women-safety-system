import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/profile/domain/entities/profile_entity.dart';

abstract class ProfileRepository {
  /// Fetch the user profile by [uid].
  Future<Either<Failure, ProfileEntity>> getProfile(
    String uid,
  );

  /// Update (or create) the user profile.
  Future<Either<Failure, ProfileEntity>> updateProfile(
    ProfileEntity entity,
  );

  /// Upload a profile photo from [filePath] for the given
  /// [uid]. Returns the download URL on success.
  Future<Either<Failure, String>> uploadPhoto({
    required String uid,
    required String filePath,
  });
}
