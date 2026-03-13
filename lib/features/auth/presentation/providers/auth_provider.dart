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
  final String? phoneNumber;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.verificationId,
    this.phoneNumber,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? verificationId,
    String? phoneNumber,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      verificationId:
          verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  SendOtp get _sendOtp => ref.read(sendOtpProvider);
  VerifyOtp get _verifyOtp =>
      ref.read(verifyOtpProvider);
  sign_out_usecase.SignOut get _signOut =>
      ref.read(signOutProvider);

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      status: AuthStatus.sendingOtp,
      phoneNumber: phoneNumber,
    );

    final result = await _sendOtp(phoneNumber);
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapErrorMessage(failure.message),
      ),
      (verificationId) => state = state.copyWith(
        status: AuthStatus.otpSent,
        verificationId: verificationId,
      ),
    );
  }

  Future<void> resendOtp() async {
    final phone = state.phoneNumber;
    if (phone == null || phone.isEmpty) return;
    await sendOtp(phone);
  }

  Future<void> verifyOtp(String otp) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Verification session not found. '
            'Please request a new OTP.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.verifying);

    final result = await _verifyOtp(
      verificationId: state.verificationId!,
      otp: otp,
    );
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapErrorMessage(failure.message),
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

  String _mapErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'The phone number entered is invalid. '
            'Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. '
            'Please wait a moment and try again.';
      case 'session-expired':
        return 'Your verification session has expired. '
            'Please request a new OTP.';
      case 'invalid-verification-code':
        return 'The OTP you entered is incorrect. '
            'Please try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. '
            'Please try again later.';
      case 'network-request-failed':
        return 'Network error. '
            'Please check your connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled. '
            'Please contact support.';
      case 'invalid-verification-id':
        return 'Verification session expired. '
            'Please request a new OTP.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. '
            'Please contact support.';
      case 'credential-already-in-use':
        return 'This phone number is already linked '
            'to another account.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  void clearError() {
    state = AuthState(
      status: state.verificationId != null
          ? AuthStatus.otpSent
          : AuthStatus.initial,
      verificationId: state.verificationId,
      phoneNumber: state.phoneNumber,
      user: state.user,
    );
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
