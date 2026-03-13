import 'package:saferide/features/alerts/domain/entities/alert_config.dart';

class AlertConfigModel {
  final String id;
  final bool routeDeviationEnabled;
  final bool speedAnomalyEnabled;
  final bool lowBatteryEnabled;
  final double deviationThresholdKm;
  final double speedThresholdKmh;
  final bool nightTimeOnly;
  final int batteryThreshold;

  const AlertConfigModel({
    required this.id,
    required this.routeDeviationEnabled,
    required this.speedAnomalyEnabled,
    required this.lowBatteryEnabled,
    required this.deviationThresholdKm,
    required this.speedThresholdKmh,
    required this.nightTimeOnly,
    required this.batteryThreshold,
  });

  factory AlertConfigModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AlertConfigModel(
      id: json['id'] as String? ?? 'default',
      routeDeviationEnabled:
          json['routeDeviationEnabled'] as bool? ?? true,
      speedAnomalyEnabled:
          json['speedAnomalyEnabled'] as bool? ?? true,
      lowBatteryEnabled:
          json['lowBatteryEnabled'] as bool? ?? true,
      deviationThresholdKm:
          (json['deviationThresholdKm'] as num?)
                  ?.toDouble() ??
              1.5,
      speedThresholdKmh:
          (json['speedThresholdKmh'] as num?)
                  ?.toDouble() ??
              100.0,
      nightTimeOnly:
          json['nightTimeOnly'] as bool? ?? false,
      batteryThreshold:
          json['batteryThreshold'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeDeviationEnabled': routeDeviationEnabled,
      'speedAnomalyEnabled': speedAnomalyEnabled,
      'lowBatteryEnabled': lowBatteryEnabled,
      'deviationThresholdKm': deviationThresholdKm,
      'speedThresholdKmh': speedThresholdKmh,
      'nightTimeOnly': nightTimeOnly,
      'batteryThreshold': batteryThreshold,
    };
  }

  AlertConfig toEntity() {
    return AlertConfig(
      id: id,
      routeDeviationEnabled: routeDeviationEnabled,
      speedAnomalyEnabled: speedAnomalyEnabled,
      lowBatteryEnabled: lowBatteryEnabled,
      deviationThresholdKm: deviationThresholdKm,
      speedThresholdKmh: speedThresholdKmh,
      nightTimeOnly: nightTimeOnly,
      batteryThreshold: batteryThreshold,
    );
  }

  factory AlertConfigModel.fromEntity(
    AlertConfig entity,
  ) {
    return AlertConfigModel(
      id: entity.id,
      routeDeviationEnabled:
          entity.routeDeviationEnabled,
      speedAnomalyEnabled: entity.speedAnomalyEnabled,
      lowBatteryEnabled: entity.lowBatteryEnabled,
      deviationThresholdKm:
          entity.deviationThresholdKm,
      speedThresholdKmh: entity.speedThresholdKmh,
      nightTimeOnly: entity.nightTimeOnly,
      batteryThreshold: entity.batteryThreshold,
    );
  }
}
