import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/features/profile/domain/entities/profile_entity.dart';

class ProfileModel {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? bloodGroup;
  final String? medicalNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.bloodGroup,
    this.medicalNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      medicalNotes: json['medicalNotes'] as String?,
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
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bloodGroup': bloodGroup,
      'medicalNotes': medicalNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProfileEntity toEntity() {
    return ProfileEntity(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      bloodGroup: bloodGroup,
      medicalNotes: medicalNotes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ProfileModel.fromEntity(ProfileEntity entity) {
    return ProfileModel(
      uid: entity.uid,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      bloodGroup: entity.bloodGroup,
      medicalNotes: entity.medicalNotes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
