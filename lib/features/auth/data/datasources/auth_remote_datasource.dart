import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:saferide/core/constants/api_constants.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/features/auth/data/models/user_model.dart';

class AuthRemoteDatasource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  GoogleSignIn? _googleSignIn;

  AuthRemoteDatasource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  /// Lazy init GoogleSignIn — only used on mobile,
  /// crashes on web without clientId.
  GoogleSignIn get _google =>
      _googleSignIn ??= GoogleSignIn();

  Future<String> sendOtp(String phoneNumber) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        if (!completer.isCompleted) {
          completer.complete('auto-verified');
        }
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (e) {
        completer.completeError(
          AuthException(
            message: e.message ?? 'Verification failed',
            code: e.code,
          ),
        );
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  Future<UserModel> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);
      return _getOrCreateUser(userCredential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'OTP verification failed',
        code: e.code,
      );
    }
  }

  /// Start Google sign-in redirect (web only).
  /// After redirect back, [checkGoogleRedirectResult]
  /// picks up the result.
  Future<void> startGoogleSignInRedirect() async {
    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');
    await _auth.signInWithRedirect(googleProvider);
  }

  /// Check if the user is returning from a Google
  /// sign-in redirect. Returns null if not.
  Future<UserModel?> checkGoogleRedirectResult() async {
    try {
      final result = await _auth.getRedirectResult();
      if (result.user != null) {
        return _getOrCreateUser(result);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final UserCredential userCredential;

      if (kIsWeb) {
        // On web, use redirect flow to avoid COOP issues
        await startGoogleSignInRedirect();
        // Page will redirect away — this won't execute.
        // The result is handled by checkGoogleRedirectResult
        // when the app reloads after redirect.
        throw const AuthException(
          message: 'Redirecting to Google sign-in...',
          code: 'sign-in-cancelled',
        );
      } else {
        // On mobile, use google_sign_in package
        final googleUser = await _google.signIn();
        if (googleUser == null) {
          throw const AuthException(
            message: 'Google sign-in was cancelled',
            code: 'sign-in-cancelled',
          );
        }

        final googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential =
            await _auth.signInWithCredential(credential);
      }

      return _getOrCreateUser(userCredential);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Google sign-in failed',
        code: e.code,
      );
    } catch (e) {
      throw AuthException(
        message: e.toString(),
        code: 'google-sign-in-failed',
      );
    }
  }

  Future<UserModel> _getOrCreateUser(
    UserCredential userCredential,
  ) async {
    final firebaseUser = userCredential.user!;

    final doc = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();

    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }

    // Create new user document
    final now = DateTime.now();
    final userModel = UserModel(
      uid: firebaseUser.uid,
      phoneNumber: firebaseUser.phoneNumber ?? '',
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(firebaseUser.uid)
        .set(userModel.toJson());

    return userModel;
  }

  Future<void> signOut() async {
    final futures = <Future>[_auth.signOut()];
    if (!kIsWeb) {
      futures.add(_google.signOut());
    }
    await Future.wait(futures);
  }

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}
