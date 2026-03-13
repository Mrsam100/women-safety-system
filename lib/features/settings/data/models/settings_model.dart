import 'package:saferide/features/settings/domain/entities/app_settings.dart';

/// Serializable settings model bridging JSON and domain entity.
class SettingsModel {
  final String alertSensitivity;
  final bool shakeDetectionEnabled;
  final String fakeCallCallerName;
  final int fakeCallDelay;
  final String language;
  final bool darkMode;
  final bool autoDeleteEnabled;

  const SettingsModel({
    required this.alertSensitivity,
    required this.shakeDetectionEnabled,
    required this.fakeCallCallerName,
    required this.fakeCallDelay,
    required this.language,
    required this.darkMode,
    required this.autoDeleteEnabled,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      alertSensitivity:
          json['alertSensitivity'] as String? ?? 'medium',
      shakeDetectionEnabled:
          json['shakeDetectionEnabled'] as bool? ?? true,
      fakeCallCallerName:
          json['fakeCallCallerName'] as String? ?? 'Mom',
      fakeCallDelay:
          json['fakeCallDelay'] as int? ?? 15,
      language: json['language'] as String? ?? 'en',
      darkMode: json['darkMode'] as bool? ?? false,
      autoDeleteEnabled:
          json['autoDeleteEnabled'] as bool? ?? true,
    );
  }

  factory SettingsModel.fromEntity(AppSettings entity) {
    return SettingsModel(
      alertSensitivity: entity.alertSensitivity.name,
      shakeDetectionEnabled: entity.shakeDetectionEnabled,
      fakeCallCallerName: entity.fakeCallCallerName,
      fakeCallDelay: entity.fakeCallDelay,
      language: entity.language,
      darkMode: entity.darkMode,
      autoDeleteEnabled: entity.autoDeleteEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertSensitivity': alertSensitivity,
      'shakeDetectionEnabled': shakeDetectionEnabled,
      'fakeCallCallerName': fakeCallCallerName,
      'fakeCallDelay': fakeCallDelay,
      'language': language,
      'darkMode': darkMode,
      'autoDeleteEnabled': autoDeleteEnabled,
    };
  }

  AppSettings toEntity() {
    return AppSettings(
      alertSensitivity: AlertSensitivity.values.firstWhere(
        (e) => e.name == alertSensitivity,
        orElse: () => AlertSensitivity.medium,
      ),
      shakeDetectionEnabled: shakeDetectionEnabled,
      fakeCallCallerName: fakeCallCallerName,
      fakeCallDelay: fakeCallDelay,
      language: language,
      darkMode: darkMode,
      autoDeleteEnabled: autoDeleteEnabled,
    );
  }
}
