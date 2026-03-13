import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/settings/domain/repositories/settings_repository.dart';

class DeleteAllData {
  final SettingsRepository _repository;

  const DeleteAllData(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.deleteAllData();
  }
}
