import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/auth/domain/repositories/auth_repository.dart';

class SendOtp {
  final AuthRepository _repository;

  const SendOtp(this._repository);

  Future<Either<Failure, String>> call(
    String phoneNumber,
  ) async {
    return await _repository.sendOtp(phoneNumber);
  }
}
