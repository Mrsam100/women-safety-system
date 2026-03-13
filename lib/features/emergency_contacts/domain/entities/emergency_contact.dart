import 'package:flutter/foundation.dart';

@immutable
class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool hasApp;
  final String? fcmToken;
  final DateTime createdAt;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.hasApp = false,
    this.fcmToken,
    required this.createdAt,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? hasApp,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      hasApp: hasApp ?? this.hasApp,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyContact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phoneNumber == other.phoneNumber &&
          relationship == other.relationship &&
          hasApp == other.hasApp &&
          fcmToken == other.fcmToken &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      phoneNumber.hashCode ^
      relationship.hashCode ^
      hasApp.hashCode ^
      fcmToken.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'EmergencyContact(id: $id, name: $name, '
      'phone: $phoneNumber, relationship: $relationship)';
}
