import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/providers/service_providers.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:saferide/features/settings/domain/entities/app_settings.dart';
import 'package:saferide/features/settings/domain/repositories/settings_repository.dart';
import 'package:saferide/features/settings/domain/usecases/delete_all_data.dart';
import 'package:saferide/features/settings/domain/usecases/export_data.dart';
import 'package:saferide/features/settings/domain/usecases/get_settings.dart';
import 'package:saferide/features/settings/domain/usecases/update_settings.dart';

// Repository provider
final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    ref.watch(localStorageServiceProvider),
  );
});

// Use case providers
final getSettingsProvider = Provider<GetSettings>((ref) {
  return GetSettings(ref.watch(settingsRepositoryProvider));
});

final updateSettingsProvider =
    Provider<UpdateSettings>((ref) {
  return UpdateSettings(
    ref.watch(settingsRepositoryProvider),
  );
});

final deleteAllDataProvider =
    Provider<DeleteAllData>((ref) {
  return DeleteAllData(
    ref.watch(settingsRepositoryProvider),
  );
});

final exportDataProvider = Provider<ExportData>((ref) {
  return ExportData(ref.watch(settingsRepositoryProvider));
});

// Settings state
class SettingsState {
  final AppSettings settings;
  final bool isLoading;
  final String? errorMessage;

  const SettingsState({
    this.settings = const AppSettings(),
    this.isLoading = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  GetSettings get _getSettings =>
      ref.read(getSettingsProvider);
  UpdateSettings get _updateSettings =>
      ref.read(updateSettingsProvider);
  DeleteAllData get _deleteAllData =>
      ref.read(deleteAllDataProvider);
  ExportData get _exportData =>
      ref.read(exportDataProvider);

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    final result = await _getSettings();
    result.fold(
      (failure) {
        AppLogger.error(
          'Load settings failed: ${failure.message}',
          tag: 'SettingsNotifier',
        );
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (settings) {
        state = state.copyWith(
          settings: settings,
          isLoading: false,
        );
      },
    );
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = state.copyWith(settings: settings);
    final result = await _updateSettings(settings);
    result.fold(
      (failure) {
        state = state.copyWith(
          errorMessage: failure.message,
        );
      },
      (_) {},
    );
  }

  Future<void> updateAlertSensitivity(
    AlertSensitivity sensitivity,
  ) async {
    final updated = state.settings.copyWith(
      alertSensitivity: sensitivity,
    );
    await updateSettings(updated);
  }

  Future<void> toggleShakeDetection() async {
    final updated = state.settings.copyWith(
      shakeDetectionEnabled:
          !state.settings.shakeDetectionEnabled,
    );
    await updateSettings(updated);
  }

  Future<void> updateFakeCallCallerName(
    String name,
  ) async {
    if (name.trim().isEmpty) return;
    final updated = state.settings.copyWith(
      fakeCallCallerName: name.trim(),
    );
    await updateSettings(updated);
  }

  Future<void> updateFakeCallDelay(int delay) async {
    if (!AppSettings.fakeCallDelayOptions.contains(delay)) {
      return;
    }
    final updated = state.settings.copyWith(
      fakeCallDelay: delay,
    );
    await updateSettings(updated);
  }

  Future<void> updateLanguage(String language) async {
    final updated = state.settings.copyWith(
      language: language,
    );
    await updateSettings(updated);
  }

  Future<void> toggleDarkMode() async {
    final updated = state.settings.copyWith(
      darkMode: !state.settings.darkMode,
    );
    await updateSettings(updated);
  }

  Future<void> toggleAutoDelete() async {
    final updated = state.settings.copyWith(
      autoDeleteEnabled:
          !state.settings.autoDeleteEnabled,
    );
    await updateSettings(updated);
  }

  Future<bool> deleteAllData() async {
    state = state.copyWith(isLoading: true);
    final result = await _deleteAllData();
    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = const SettingsState();
        return true;
      },
    );
  }

  Future<String?> exportData() async {
    state = state.copyWith(isLoading: true);
    final result = await _exportData();
    state = state.copyWith(isLoading: false);
    return result.fold(
      (failure) {
        state = state.copyWith(
          errorMessage: failure.message,
        );
        return null;
      },
      (data) => data,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

/// Convenience provider for current settings.
final appSettingsProvider = Provider<AppSettings>((ref) {
  return ref.watch(settingsNotifierProvider).settings;
});

/// Whether dark mode is enabled.
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).darkMode;
});
