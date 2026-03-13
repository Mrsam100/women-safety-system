import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/auth/domain/entities/user_entity.dart';
import 'package:saferide/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository _repository;

  const SignInWithGoogle(this._repository);

  Future<Either<Failure, UserEntity>> call() async {
    return await _repository.signInWithGoogle();
  }
}
