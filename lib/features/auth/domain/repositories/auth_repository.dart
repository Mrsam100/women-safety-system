import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Send OTP to the given phone number.
  /// Returns the verification ID on success.
  Future<Either<Failure, String>> sendOtp(String phoneNumber);

  /// Verify the OTP code against the verification ID.
  /// Returns the authenticated user on success.
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String verificationId,
    required String otp,
  });

  /// Sign in with Google OAuth.
  /// Returns the authenticated user on success.
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Sign out the current user.
  Future<Either<Failure, void>> signOut();

  /// Get the current authenticated user, if any.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Stream of auth state changes.
  Stream<UserEntity?> authStateChanges();
}
