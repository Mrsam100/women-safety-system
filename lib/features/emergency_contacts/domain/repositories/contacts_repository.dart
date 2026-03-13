import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/emergency_contacts/domain/entities/emergency_contact.dart';

abstract class ContactsRepository {
  Future<Either<Failure, List<EmergencyContact>>> getContacts(
    String userId,
  );

  Future<Either<Failure, EmergencyContact>> addContact(
    String userId,
    EmergencyContact contact,
  );

  Future<Either<Failure, void>> removeContact(
    String userId,
    String contactId,
  );
}
