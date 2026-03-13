import 'package:flutter/foundation.dart';

/// Immutable configuration for automated alert checks
/// during an active ride.
@immutable
class AlertConfig {
  final String id;
  final bool routeDeviationEnabled;
  final bool speedAnomalyEnabled;
  final bool lowBatteryEnabled;
  final double deviationThresholdKm;
  final double speedThresholdKmh;
  final bool nightTimeOnly;
  final int batteryThreshold;

  const AlertConfig({
    required this.id,
    this.routeDeviationEnabled = true,
    this.speedAnomalyEnabled = true,
    this.lowBatteryEnabled = true,
    this.deviationThresholdKm = 1.5,
    this.speedThresholdKmh = 100.0,
    this.nightTimeOnly = false,
    this.batteryThreshold = 10,
  });

  /// Default configuration with sensible thresholds.
  const AlertConfig.defaults()
      : id = 'default',
        routeDeviationEnabled = true,
        speedAnomalyEnabled = true,
        lowBatteryEnabled = true,
        deviationThresholdKm = 1.5,
        speedThresholdKmh = 100.0,
        nightTimeOnly = false,
        batteryThreshold = 10;

  AlertConfig copyWith({
    String? id,
    bool? routeDeviationEnabled,
    bool? speedAnomalyEnabled,
    bool? lowBatteryEnabled,
    double? deviationThresholdKm,
    double? speedThresholdKmh,
    bool? nightTimeOnly,
    int? batteryThreshold,
  }) {
    return AlertConfig(
      id: id ?? this.id,
      routeDeviationEnabled:
          routeDeviationEnabled ??
              this.routeDeviationEnabled,
      speedAnomalyEnabled:
          speedAnomalyEnabled ??
              this.speedAnomalyEnabled,
      lowBatteryEnabled:
          lowBatteryEnabled ?? this.lowBatteryEnabled,
      deviationThresholdKm:
          deviationThresholdKm ??
              this.deviationThresholdKm,
      speedThresholdKmh:
          speedThresholdKmh ?? this.speedThresholdKmh,
      nightTimeOnly:
          nightTimeOnly ?? this.nightTimeOnly,
      batteryThreshold:
          batteryThreshold ?? this.batteryThreshold,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertConfig &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AlertConfig(id: $id, '
      'routeDeviation: $routeDeviationEnabled, '
      'speedAnomaly: $speedAnomalyEnabled, '
      'lowBattery: $lowBatteryEnabled)';
}
