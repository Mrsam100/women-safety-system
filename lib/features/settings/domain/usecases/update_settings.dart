import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/settings/domain/entities/app_settings.dart';
import 'package:saferide/features/settings/domain/repositories/settings_repository.dart';

class UpdateSettings {
  final SettingsRepository _repository;

  const UpdateSettings(this._repository);

  Future<Either<Failure, void>> call(
    AppSettings settings,
  ) {
    return _repository.updateSettings(settings);
  }
}
