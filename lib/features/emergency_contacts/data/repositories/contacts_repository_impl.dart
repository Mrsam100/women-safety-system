import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/exceptions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/emergency_contacts/data/datasources/contacts_remote_datasource.dart';
import 'package:saferide/features/emergency_contacts/data/models/contact_model.dart';
import 'package:saferide/features/emergency_contacts/domain/entities/emergency_contact.dart';
import 'package:saferide/features/emergency_contacts/domain/repositories/contacts_repository.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  final ContactsRemoteDatasource _remoteDatasource;

  const ContactsRepositoryImpl(this._remoteDatasource);

  @override
  Future<Either<Failure, List<EmergencyContact>>> getContacts(
    String userId,
  ) async {
    try {
      final models = await _remoteDatasource.getContacts(userId);
      final entities =
          models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    }
  }

  @override
  Future<Either<Failure, EmergencyContact>> addContact(
    String userId,
    EmergencyContact contact,
  ) async {
    try {
      final model = ContactModel.fromEntity(contact);
      final result =
          await _remoteDatasource.addContact(userId, model);
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    }
  }

  @override
  Future<Either<Failure, void>> removeContact(
    String userId,
    String contactId,
  ) async {
    try {
      await _remoteDatasource.removeContact(userId, contactId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message, code: e.code),
      );
    }
  }
}
