import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/auth/domain/entities/user_entity.dart';
import 'package:saferide/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtp {
  final AuthRepository _repository;

  const VerifyOtp(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String verificationId,
    required String otp,
  }) async {
    return await _repository.verifyOtp(
      verificationId: verificationId,
      otp: otp,
    );
  }
}
