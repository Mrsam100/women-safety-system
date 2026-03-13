import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/features/auth/domain/entities/user_entity.dart';

class UserModel {
  final String uid;
  final String phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final String? bloodGroup;
  final String? medicalNotes;
  final String? fcmToken;
  final String language;
  final String alertSensitivity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.phoneNumber,
    this.displayName,
    this.photoUrl,
    this.bloodGroup,
    this.medicalNotes,
    this.fcmToken,
    this.language = 'en',
    this.alertSensitivity = 'medium',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      medicalNotes: json['medicalNotes'] as String?,
      fcmToken: json['fcmToken'] as String?,
      language: json['language'] as String? ?? 'en',
      alertSensitivity:
          json['alertSensitivity'] as String? ?? 'medium',
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      updatedAt:
          (json['updatedAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bloodGroup': bloodGroup,
      'medicalNotes': medicalNotes,
      'fcmToken': fcmToken,
      'language': language,
      'alertSensitivity': alertSensitivity,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      phoneNumber: phoneNumber,
      displayName: displayName,
      photoUrl: photoUrl,
      bloodGroup: bloodGroup,
      medicalNotes: medicalNotes,
      fcmToken: fcmToken,
      language: language,
      alertSensitivity: alertSensitivity,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      phoneNumber: entity.phoneNumber,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      bloodGroup: entity.bloodGroup,
      medicalNotes: entity.medicalNotes,
      fcmToken: entity.fcmToken,
      language: entity.language,
      alertSensitivity: entity.alertSensitivity,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
