import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/emergency_contacts/domain/entities/emergency_contact.dart';
import 'package:saferide/features/emergency_contacts/domain/repositories/contacts_repository.dart';

class GetContacts {
  final ContactsRepository _repository;

  const GetContacts(this._repository);

  Future<Either<Failure, List<EmergencyContact>>> call(
    String userId,
  ) {
    return _repository.getContacts(userId);
  }
}
