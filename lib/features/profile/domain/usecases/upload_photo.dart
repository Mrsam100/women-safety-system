import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/profile/domain/repositories/profile_repository.dart';

class UploadPhoto {
  final ProfileRepository _repository;

  const UploadPhoto(this._repository);

  /// Uploads a photo from [filePath] for user [uid].
  /// Returns the download URL on success.
  Future<Either<Failure, String>> call({
    required String uid,
    required String filePath,
  }) async {
    return await _repository.uploadPhoto(
      uid: uid,
      filePath: filePath,
    );
  }
}
