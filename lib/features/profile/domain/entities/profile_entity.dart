import 'package:flutter/foundation.dart';

@immutable
class ProfileEntity {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? bloodGroup;
  final String? medicalNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileEntity({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.bloodGroup,
    this.medicalNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  ProfileEntity copyWith({
    String? uid,
    String? displayName,
    String? photoUrl,
    String? bloodGroup,
    String? medicalNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileEntity &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
