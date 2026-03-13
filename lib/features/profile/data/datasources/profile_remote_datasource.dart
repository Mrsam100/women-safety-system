import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:saferide/core/constants/api_constants.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/features/profile/data/models/profile_model.dart';

class ProfileRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileRemoteDatasource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  /// Fetches the user profile document from Firestore.
  Future<ProfileModel> getProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw const ServerException(
          message: 'Profile not found',
          code: 'NOT_FOUND',
        );
      }

      return ProfileModel.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch profile',
        code: e.code,
      );
    }
  }

  /// Creates or updates the user profile in Firestore.
  Future<ProfileModel> updateProfile(
    ProfileModel model,
  ) async {
    try {
      final data = model.toJson();

      await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(model.uid)
          .set(data, SetOptions(merge: true));

      return model;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to update profile',
        code: e.code,
      );
    }
  }

  /// Uploads a profile photo to Cloud Storage and returns
  /// the download URL.
  Future<String> uploadPhoto({
    required String uid,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      final extension = filePath.split('.').last;
      final ref = _storage.ref().child(
            '${ApiConstants.profilePhotosPath}/$uid.'
            '$extension',
          );

      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$extension'),
      );

      final downloadUrl =
          await uploadTask.ref.getDownloadURL();

      // Update the photoUrl field in Firestore
      await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(uid)
          .update({'photoUrl': downloadUrl});

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to upload photo',
        code: e.code,
      );
    }
  }
}
