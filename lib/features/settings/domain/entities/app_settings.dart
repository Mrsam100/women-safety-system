import 'package:flutter/foundation.dart';

/// Alert sensitivity levels for threat detection.
enum AlertSensitivity { low, medium, high }

/// Immutable application settings entity.
@immutable
class AppSettings {
  final AlertSensitivity alertSensitivity;
  final bool shakeDetectionEnabled;
  final String fakeCallCallerName;
  final int fakeCallDelay;
  final String language;
  final bool darkMode;
  final bool autoDeleteEnabled;

  const AppSettings({
    this.alertSensitivity = AlertSensitivity.medium,
    this.shakeDetectionEnabled = true,
    this.fakeCallCallerName = 'Mom',
    this.fakeCallDelay = 15,
    this.language = 'en',
    this.darkMode = false,
    this.autoDeleteEnabled = true,
  });

  /// Valid fake call delay options in seconds.
  static const List<int> fakeCallDelayOptions = [5, 15, 30];

  /// Supported languages.
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'Hindi',
  };

  AppSettings copyWith({
    AlertSensitivity? alertSensitivity,
    bool? shakeDetectionEnabled,
    String? fakeCallCallerName,
    int? fakeCallDelay,
    String? language,
    bool? darkMode,
    bool? autoDeleteEnabled,
  }) {
    return AppSettings(
      alertSensitivity:
          alertSensitivity ?? this.alertSensitivity,
      shakeDetectionEnabled:
          shakeDetectionEnabled ?? this.shakeDetectionEnabled,
      fakeCallCallerName:
          fakeCallCallerName ?? this.fakeCallCallerName,
      fakeCallDelay: fakeCallDelay ?? this.fakeCallDelay,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      autoDeleteEnabled:
          autoDeleteEnabled ?? this.autoDeleteEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          alertSensitivity == other.alertSensitivity &&
          shakeDetectionEnabled ==
              other.shakeDetectionEnabled &&
          fakeCallCallerName == other.fakeCallCallerName &&
          fakeCallDelay == other.fakeCallDelay &&
          language == other.language &&
          darkMode == other.darkMode &&
          autoDeleteEnabled == other.autoDeleteEnabled;

  @override
  int get hashCode => Object.hash(
        alertSensitivity,
        shakeDetectionEnabled,
        fakeCallCallerName,
        fakeCallDelay,
        language,
        darkMode,
        autoDeleteEnabled,
      );

  @override
  String toString() => 'AppSettings('
      'sensitivity: $alertSensitivity, '
      'shake: $shakeDetectionEnabled, '
      'caller: $fakeCallCallerName, '
      'delay: ${fakeCallDelay}s, '
      'lang: $language, '
      'dark: $darkMode, '
      'autoDelete: $autoDeleteEnabled)';
}
