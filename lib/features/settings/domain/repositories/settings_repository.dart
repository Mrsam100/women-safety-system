import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/settings/domain/entities/app_settings.dart';

/// Abstract settings repository contract.
abstract class SettingsRepository {
  /// Retrieve persisted app settings.
  /// Returns default settings if none are stored.
  Future<Either<Failure, AppSettings>> getSettings();

  /// Persist the given [settings] to local storage.
  Future<Either<Failure, void>> updateSettings(
    AppSettings settings,
  );

  /// Delete all user data (settings, cache, offline queue).
  Future<Either<Failure, void>> deleteAllData();

  /// Export user data as a JSON-encoded string.
  Future<Either<Failure, String>> exportData();
}
