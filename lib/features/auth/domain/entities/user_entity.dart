import 'package:flutter/foundation.dart';

@immutable
class UserEntity {
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

  const UserEntity({
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

  bool get isProfileComplete =>
      displayName != null && displayName!.isNotEmpty;

  UserEntity copyWith({
    String? uid,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    String? bloodGroup,
    String? medicalNotes,
    String? fcmToken,
    String? language,
    String? alertSensitivity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      fcmToken: fcmToken ?? this.fcmToken,
      language: language ?? this.language,
      alertSensitivity:
          alertSensitivity ?? this.alertSensitivity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
