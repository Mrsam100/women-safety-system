import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/services/local_storage_service.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/settings/data/models/settings_model.dart';
import 'package:saferide/features/settings/domain/entities/app_settings.dart';
import 'package:saferide/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final LocalStorageService _storage;

  static const _settingsKey = 'app_settings';

  SettingsRepositoryImpl(this._storage);

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      final raw = _storage.getSetting<String>(_settingsKey);
      if (raw == null) {
        return const Right(AppSettings());
      }
      final json =
          jsonDecode(raw) as Map<String, dynamic>;
      final model = SettingsModel.fromJson(json);
      return Right(model.toEntity());
    } catch (e, st) {
      AppLogger.error(
        'Failed to load settings',
        tag: 'SettingsRepository',
        error: e,
        stackTrace: st,
      );
      return Left(CacheFailure(
        message: 'Failed to load settings: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> updateSettings(
    AppSettings settings,
  ) async {
    try {
      final model = SettingsModel.fromEntity(settings);
      final json = jsonEncode(model.toJson());
      await _storage.saveSetting(_settingsKey, json);
      AppLogger.info(
        'Settings saved',
        tag: 'SettingsRepository',
      );
      return const Right(null);
    } catch (e, st) {
      AppLogger.error(
        'Failed to save settings',
        tag: 'SettingsRepository',
        error: e,
        stackTrace: st,
      );
      return Left(CacheFailure(
        message: 'Failed to save settings: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllData() async {
    try {
      await _storage.clearAll();
      AppLogger.info(
        'All data deleted',
        tag: 'SettingsRepository',
      );
      return const Right(null);
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete all data',
        tag: 'SettingsRepository',
        error: e,
        stackTrace: st,
      );
      return Left(CacheFailure(
        message: 'Failed to delete data: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, String>> exportData() async {
    try {
      final settingsResult = await getSettings();
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          final model = SettingsModel.fromEntity(settings);
          final exportPayload = {
            'exportedAt': DateTime.now().toIso8601String(),
            'settings': model.toJson(),
          };
          final encoded = jsonEncode(exportPayload);
          AppLogger.info(
            'Data exported (${encoded.length} bytes)',
            tag: 'SettingsRepository',
          );
          return Right(encoded);
        },
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to export data',
        tag: 'SettingsRepository',
        error: e,
        stackTrace: st,
      );
      return Left(CacheFailure(
        message: 'Failed to export data: $e',
      ));
    }
  }
}
