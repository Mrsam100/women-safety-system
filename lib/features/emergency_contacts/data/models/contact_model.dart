import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/features/emergency_contacts/domain/entities/emergency_contact.dart';

class ContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool hasApp;
  final String? fcmToken;
  final DateTime createdAt;

  const ContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.hasApp = false,
    this.fcmToken,
    required this.createdAt,
  });

  factory ContactModel.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return ContactModel(
      id: id,
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      hasApp: json['hasApp'] as bool? ?? false,
      fcmToken: json['fcmToken'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'hasApp': hasApp,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  EmergencyContact toEntity() {
    return EmergencyContact(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
      hasApp: hasApp,
      fcmToken: fcmToken,
      createdAt: createdAt,
    );
  }

  factory ContactModel.fromEntity(EmergencyContact entity) {
    return ContactModel(
      id: entity.id,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      relationship: entity.relationship,
      hasApp: entity.hasApp,
      fcmToken: entity.fcmToken,
      createdAt: entity.createdAt,
    );
  }
}
