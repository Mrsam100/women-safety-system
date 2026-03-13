import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/settings/domain/repositories/settings_repository.dart';

class ExportData {
  final SettingsRepository _repository;

  const ExportData(this._repository);

  Future<Either<Failure, String>> call() {
    return _repository.exportData();
  }
}
