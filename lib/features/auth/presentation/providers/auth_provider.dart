import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:saferide/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:saferide/features/auth/domain/entities/user_entity.dart';
import 'package:saferide/features/auth/domain/repositories/auth_repository.dart';
import 'package:saferide/features/auth/domain/usecases/send_otp.dart';
import 'package:saferide/features/auth/domain/usecases/sign_out.dart'
    as sign_out_usecase;
import 'package:saferide/features/auth/domain/usecases/verify_otp.dart';

// Datasource
final authRemoteDatasourceProvider =
    Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

// Repository
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authRemoteDatasourceProvider),
  ),
);

// Use cases
final sendOtpProvider = Provider<SendOtp>(
  (ref) => SendOtp(ref.watch(authRepositoryProvider)),
);

final verifyOtpProvider = Provider<VerifyOtp>(
  (ref) => VerifyOtp(ref.watch(authRepositoryProvider)),
);

final signOutProvider =
    Provider<sign_out_usecase.SignOut>(
  (ref) => sign_out_usecase.SignOut(
    ref.watch(authRepositoryProvider),
  ),
);

// Auth state
enum AuthStatus {
  initial,
  sendingOtp,
  otpSent,
  verifying,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? verificationId;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.verificationId,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? verificationId,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      verificationId:
          verificationId ?? this.verificationId,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SendOtp _sendOtp;
  final VerifyOtp _verifyOtp;
  final sign_out_usecase.SignOut _signOut;

  AuthNotifier({
    required SendOtp sendOtp,
    required VerifyOtp verifyOtp,
    required sign_out_usecase.SignOut signOut,
  })  : _sendOtp = sendOtp,
        _verifyOtp = verifyOtp,
        _signOut = signOut,
        super(const AuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.sendingOtp);

    final result = await _sendOtp(phoneNumber);
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (verificationId) => state = state.copyWith(
        status: AuthStatus.otpSent,
        verificationId: verificationId,
      ),
    );
  }

  Future<void> verifyOtp(String otp) async {
    if (state.verificationId == null) return;

    state = state.copyWith(status: AuthStatus.verifying);

    final result = await _verifyOtp(
      verificationId: state.verificationId!,
      otp: otp,
    );
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> signOut() async {
    await _signOut();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
    );
  }

  void clearError() {
    state = state.copyWith(
      status: AuthStatus.initial,
      errorMessage: null,
    );
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    sendOtp: ref.watch(sendOtpProvider),
    verifyOtp: ref.watch(verifyOtpProvider),
    signOut: ref.watch(signOutProvider),
  );
});
