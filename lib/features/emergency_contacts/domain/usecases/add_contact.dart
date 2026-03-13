import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/emergency_contacts/domain/entities/emergency_contact.dart';
import 'package:saferide/features/emergency_contacts/domain/repositories/contacts_repository.dart';

class AddContact {
  final ContactsRepository _repository;

  const AddContact(this._repository);

  Future<Either<Failure, EmergencyContact>> call(
    String userId,
    EmergencyContact contact,
  ) {
    return _repository.addContact(userId, contact);
  }
}
