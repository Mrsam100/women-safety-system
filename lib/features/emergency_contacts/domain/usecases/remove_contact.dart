import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/emergency_contacts/domain/repositories/contacts_repository.dart';

class RemoveContact {
  final ContactsRepository _repository;

  const RemoveContact(this._repository);

  Future<Either<Failure, void>> call(
    String userId,
    String contactId,
  ) {
    return _repository.removeContact(userId, contactId);
  }
}
