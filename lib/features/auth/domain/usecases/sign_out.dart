import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/auth/domain/repositories/auth_repository.dart';

class SignOut {
  final AuthRepository _repository;

  const SignOut(this._repository);

  Future<Either<Failure, void>> call() async {
    return await _repository.signOut();
  }
}
