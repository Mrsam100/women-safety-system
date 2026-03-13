import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/features/emergency_contacts/data/models/contact_model.dart';

abstract class ContactsRemoteDatasource {
  Future<List<ContactModel>> getContacts(String userId);
  Future<ContactModel> addContact(
    String userId,
    ContactModel contact,
  );
  Future<void> removeContact(String userId, String contactId);
}

class ContactsRemoteDatasourceImpl
    implements ContactsRemoteDatasource {
  final FirebaseFirestore _firestore;

  const ContactsRemoteDatasourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> _contactsRef(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('emergencyContacts');
  }

  @override
  Future<List<ContactModel>> getContacts(String userId) async {
    try {
      final snapshot = await _contactsRef(userId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map(
            (doc) => ContactModel.fromJson(
              doc.data(),
              id: doc.id,
            ),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch contacts',
        code: e.code,
      );
    }
  }

  @override
  Future<ContactModel> addContact(
    String userId,
    ContactModel contact,
  ) async {
    try {
      final docRef = await _contactsRef(userId).add(
        contact.toJson(),
      );

      return ContactModel(
        id: docRef.id,
        name: contact.name,
        phoneNumber: contact.phoneNumber,
        relationship: contact.relationship,
        hasApp: contact.hasApp,
        fcmToken: contact.fcmToken,
        createdAt: contact.createdAt,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to add contact',
        code: e.code,
      );
    }
  }

  @override
  Future<void> removeContact(
    String userId,
    String contactId,
  ) async {
    try {
      await _contactsRef(userId).doc(contactId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to remove contact',
        code: e.code,
      );
    }
  }
}
