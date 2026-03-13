import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saferide/core/constants/api_constants.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/features/auth/data/models/user_model.dart';

class AuthRemoteDatasource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDatasource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  Future<String> sendOtp(String phoneNumber) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
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
      final firebaseUser = userCredential.user!;

      // Check if user exists in Firestore
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
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(userModel.toJson());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'OTP verification failed',
        code: e.code,
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
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
