import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/settings/domain/entities/app_settings.dart';
import 'package:saferide/features/settings/domain/repositories/settings_repository.dart';

class GetSettings {
  final SettingsRepository _repository;

  const GetSettings(this._repository);

  Future<Either<Failure, AppSettings>> call() {
    return _repository.getSettings();
  }
}
