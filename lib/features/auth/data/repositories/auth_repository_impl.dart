import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:saferide/features/auth/domain/entities/user_entity.dart';
import 'package:saferide/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;

  AuthRepositoryImpl(this._remoteDatasource);

  @override
  Future<Either<Failure, String>> sendOtp(
    String phoneNumber,
  ) async {
    try {
      final verificationId =
          await _remoteDatasource.sendOtp(phoneNumber);
      return Right(verificationId);
    } on AuthException catch (e) {
      return Left(
        AuthFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final userModel = await _remoteDatasource.verifyOtp(
        verificationId: verificationId,
        otp: otp,
      );
      return Right(userModel.toEntity());
    } on AuthException catch (e) {
      return Left(
        AuthFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final userModel =
          await _remoteDatasource.signInWithGoogle();
      return Right(userModel.toEntity());
    } on AuthException catch (e) {
      return Left(
        AuthFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDatasource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final userModel =
          await _remoteDatasource.getCurrentUser();
      return Right(userModel?.toEntity());
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return _remoteDatasource.authStateChanges().asyncMap(
      (firebaseUser) async {
        if (firebaseUser == null) return null;
        final result = await getCurrentUser();
        return result.fold((_) => null, (user) => user);
      },
    );
  }
}
