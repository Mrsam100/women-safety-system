import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/core/providers/service_providers.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/alerts/data/datasources/alerts_remote_datasource.dart';
import 'package:saferide/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:saferide/features/alerts/domain/entities/alert_config.dart';
import 'package:saferide/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:saferide/features/alerts/domain/usecases/check_low_battery.dart';
import 'package:saferide/features/alerts/domain/usecases/check_route_deviation.dart';
import 'package:saferide/features/alerts/domain/usecases/check_speed_anomaly.dart';
import 'package:saferide/features/safety/domain/entities/alert.dart';

// ── Datasource provider ──

final alertsRemoteDatasourceProvider =
    Provider<AlertsRemoteDatasource>((ref) {
  return AlertsRemoteDatasource(
    firestore: ref.watch(firestoreProvider),
  );
});

// ── Repository provider ──

final alertsRepositoryProvider =
    Provider<AlertsRepository>((ref) {
  return AlertsRepositoryImpl(
    remoteDatasource: ref.watch(
      alertsRemoteDatasourceProvider,
    ),
  );
});

// ── Use case providers ──

final checkRouteDeviationProvider =
    Provider<CheckRouteDeviation>((ref) {
  return CheckRouteDeviation();
});

final checkSpeedAnomalyProvider =
    Provider<CheckSpeedAnomaly>((ref) {
  return CheckSpeedAnomaly();
});

final checkLowBatteryProvider =
    Provider<CheckLowBattery>((ref) {
  return CheckLowBattery(
    batteryService: ref.watch(batteryServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    smsService: ref.watch(smsServiceProvider),
  );
});

// ── Alert config provider ──

final alertConfigProvider =
    FutureProvider.family<AlertConfig, String>(
  (ref, userId) async {
    final repo = ref.watch(alertsRepositoryProvider);
    final result = await repo.getAlertConfig(
      userId: userId,
    );
    return result.fold(
      (failure) => const AlertConfig.defaults(),
      (config) => config,
    );
  },
);

// ── Alert state ──

/// Severity of an automated alert — determines the
/// UI response and whether escalation is needed.
enum AlertThreatLevel {
  /// Informational — show a banner, no action needed.
  low,

  /// Warning — show a banner and prompt "Are you
  /// safe?" dialog.
  medium,

  /// Danger — show dialog with countdown. If user
  /// does not respond, escalate to panic.
  high,

  /// Critical — immediately escalate to panic.
  critical,
}

/// An active alert detected by the monitoring system.
class ActiveAlert {
  final String id;
  final AlertType type;
  final AlertThreatLevel threatLevel;
  final String message;
  final DateTime detectedAt;
  final Map<String, dynamic> metadata;

  const ActiveAlert({
    required this.id,
    required this.type,
    required this.threatLevel,
    required this.message,
    required this.detectedAt,
    this.metadata = const {},
  });
}

/// State for the alerts monitoring system.
class AlertsState {
  final bool isMonitoring;
  final List<ActiveAlert> activeAlerts;
  final ActiveAlert? currentPrompt;
  final int safetyCountdown;
  final AlertConfig config;
  final String? errorMessage;

  const AlertsState({
    this.isMonitoring = false,
    this.activeAlerts = const [],
    this.currentPrompt,
    this.safetyCountdown = 0,
    this.config = const AlertConfig.defaults(),
    this.errorMessage,
  });

  bool get hasActiveAlerts => activeAlerts.isNotEmpty;

  bool get isCountingDown => safetyCountdown > 0;

  AlertsState copyWith({
    bool? isMonitoring,
    List<ActiveAlert>? activeAlerts,
    ActiveAlert? currentPrompt,
    bool clearPrompt = false,
    int? safetyCountdown,
    AlertConfig? config,
    String? errorMessage,
  }) {
    return AlertsState(
      isMonitoring:
          isMonitoring ?? this.isMonitoring,
      activeAlerts:
          activeAlerts ?? this.activeAlerts,
      currentPrompt: clearPrompt
          ? null
          : (currentPrompt ?? this.currentPrompt),
      safetyCountdown:
          safetyCountdown ?? this.safetyCountdown,
      config: config ?? this.config,
      errorMessage:
          errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier that runs periodic route, speed, and
/// battery checks during an active ride. Triggers
/// appropriate responses based on threat level.
class AlertsNotifier extends Notifier<AlertsState> {
  static const _tag = 'AlertsNotifier';

  Timer? _monitoringTimer;
  Timer? _countdownTimer;

  /// Callback invoked when an alert escalates to
  /// panic level (countdown expired or critical
  /// threat). The parent widget/provider should wire
  /// this to [TriggerPanic].
  void Function()? onEscalate;

  /// Previous GPS reading for speed calculations.
  double? _prevLat;
  double? _prevLon;
  DateTime? _prevTimestamp;

  /// Ride context set by [startMonitoring].
  String? _userId;
  String? _rideId;
  String? _userName;
  List<String> _contactPhones = const [];
  List<({double lat, double lon})> _expectedRoute =
      const [];

  @override
  AlertsState build() {
    ref.onDispose(() {
      _monitoringTimer?.cancel();
      _countdownTimer?.cancel();
    });
    return const AlertsState();
  }

  CheckRouteDeviation get _checkRouteDeviation =>
      ref.read(checkRouteDeviationProvider);

  CheckSpeedAnomaly get _checkSpeedAnomaly =>
      ref.read(checkSpeedAnomalyProvider);

  CheckLowBattery get _checkLowBattery =>
      ref.read(checkLowBatteryProvider);

  AlertsRepository get _repository =>
      ref.read(alertsRepositoryProvider);

  /// Start periodic monitoring for an active ride.
  Future<void> startMonitoring({
    required String userId,
    required String rideId,
    required String userName,
    required List<String> contactPhones,
    List<({double lat, double lon})> expectedRoute =
        const [],
  }) async {
    _userId = userId;
    _rideId = rideId;
    _userName = userName;
    _contactPhones = contactPhones;
    _expectedRoute = expectedRoute;

    // Reset use case state
    _checkRouteDeviation.reset();
    _checkSpeedAnomaly.reset();
    _checkLowBattery.reset();
    _prevLat = null;
    _prevLon = null;
    _prevTimestamp = null;

    // Load alert config
    final configResult = await _repository.getAlertConfig(
      userId: userId,
    );
    final config = configResult.fold(
      (_) => const AlertConfig.defaults(),
      (c) => c,
    );

    state = AlertsState(
      isMonitoring: true,
      config: config,
    );

    // Run checks every 30 seconds (routeCheckInterval)
    _monitoringTimer = Timer.periodic(
      Duration(
        seconds: AppDimensions.routeCheckInterval,
      ),
      (_) => _runChecks(),
    );

    AppLogger.info(
      'Alert monitoring started for ride $rideId',
      tag: _tag,
    );
  }

  /// Stop all monitoring. Call when the ride ends.
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;

    _checkRouteDeviation.reset();
    _checkSpeedAnomaly.reset();
    _checkLowBattery.reset();

    state = const AlertsState();

    AppLogger.info(
      'Alert monitoring stopped',
      tag: _tag,
    );
  }

  /// Update the current GPS position. Called by the
  /// ride tracking system each time a new location
  /// reading arrives.
  void updatePosition({
    required double latitude,
    required double longitude,
  }) {
    _prevLat = latitude;
    _prevLon = longitude;
    _prevTimestamp = DateTime.now();
  }

  /// User responded "Yes, I'm safe" to the safety
  /// prompt — dismiss the alert.
  void confirmSafe() {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    if (state.currentPrompt != null) {
      final resolved = state.activeAlerts
          .where(
            (a) => a.id != state.currentPrompt!.id,
          )
          .toList();

      state = state.copyWith(
        clearPrompt: true,
        safetyCountdown: 0,
        activeAlerts: resolved,
      );
    }

    AppLogger.info(
      'User confirmed safe',
      tag: _tag,
    );
  }

  /// Dismiss a specific alert banner.
  void dismissAlert(String alertId) {
    final updated = state.activeAlerts
        .where((a) => a.id != alertId)
        .toList();
    state = state.copyWith(activeAlerts: updated);
  }

  /// Update alert configuration.
  Future<void> updateConfig(AlertConfig config) async {
    state = state.copyWith(config: config);

    if (_userId != null) {
      await _repository.updateAlertConfig(
        userId: _userId!,
        config: config,
      );
    }
  }

  // ────────────────────────────────────────────────
  // Private helpers
  // ────────────────────────────────────────────────

  /// Run all enabled checks in parallel.
  Future<void> _runChecks() async {
    if (!state.isMonitoring) return;
    if (_prevLat == null || _prevLon == null) return;

    final config = state.config;
    final now = DateTime.now();

    await Future.wait<void>([
      if (config.routeDeviationEnabled)
        _runRouteDeviationCheck(now),
      if (config.speedAnomalyEnabled)
        _runSpeedAnomalyCheck(now),
      if (config.lowBatteryEnabled)
        _runLowBatteryCheck(),
    ]);
  }

  Future<void> _runRouteDeviationCheck(
    DateTime now,
  ) async {
    if (_prevLat == null || _prevLon == null) return;

    final result = await _checkRouteDeviation(
      currentLat: _prevLat!,
      currentLon: _prevLon!,
      expectedRoute: _expectedRoute,
      thresholdKm: state.config.deviationThresholdKm,
    );

    result.fold(
      (failure) => AppLogger.error(
        failure.message,
        tag: _tag,
      ),
      (deviation) {
        if (deviation.shouldAlert) {
          _addAlert(
            type: AlertType.routeDeviation,
            threatLevel: AlertThreatLevel.high,
            message: 'Route deviation detected: '
                '${deviation.deviationKm.toStringAsFixed(1)}'
                ' km off route for '
                '${deviation.sustainedDuration.inMinutes}'
                ' min',
            metadata: {
              'deviationKm': deviation.deviationKm,
              'sustainedMinutes':
                  deviation.sustainedDuration.inMinutes,
            },
          );
        }
      },
    );
  }

  Future<void> _runSpeedAnomalyCheck(
    DateTime now,
  ) async {
    if (_prevLat == null ||
        _prevLon == null ||
        _prevTimestamp == null) {
      return;
    }

    // We need two readings to calculate speed.
    // Use the stored previous position and current
    // position. On first call, skip.
    final timeDiff =
        now.difference(_prevTimestamp!).inSeconds;
    if (timeDiff <= 0) return;

    final result = await _checkSpeedAnomaly(
      currentLat: _prevLat!,
      currentLon: _prevLon!,
      previousLat: _prevLat!,
      previousLon: _prevLon!,
      timeDiffSeconds: timeDiff,
      timestamp: now,
      speedThresholdKmh:
          state.config.speedThresholdKmh,
      nightTimeOnly: state.config.nightTimeOnly,
    );

    result.fold(
      (failure) => AppLogger.error(
        failure.message,
        tag: _tag,
      ),
      (anomaly) {
        if (anomaly.shouldAlert) {
          final threatLevel =
              anomaly.anomalyType ==
                      SpeedAnomalyType
                          .stoppedIsolatedNight
                  ? AlertThreatLevel.high
                  : AlertThreatLevel.medium;

          _addAlert(
            type: AlertType.speedAnomaly,
            threatLevel: threatLevel,
            message: anomaly.reason ??
                'Speed anomaly detected',
            metadata: {
              'speedKmh': anomaly.speedKmh,
              'anomalyType':
                  anomaly.anomalyType?.name,
              if (anomaly.stoppedDuration != null)
                'stoppedMinutes':
                    anomaly.stoppedDuration!.inMinutes,
            },
          );
        }
      },
    );
  }

  Future<void> _runLowBatteryCheck() async {
    if (_userName == null) return;

    final result = await _checkLowBattery(
      userName: _userName!,
      contactPhones: _contactPhones,
      threshold: state.config.batteryThreshold,
    );

    result.fold(
      (failure) => AppLogger.error(
        failure.message,
        tag: _tag,
      ),
      (battery) {
        if (battery.shouldAlert) {
          _addAlert(
            type: AlertType.lowBattery,
            threatLevel: AlertThreatLevel.low,
            message: 'Battery at ${battery.batteryLevel}%'
                ' — last location sent to contacts',
            metadata: {
              'batteryLevel': battery.batteryLevel,
              'contactsNotified':
                  battery.contactsNotified,
            },
          );
        }
      },
    );
  }

  /// Add an alert and optionally trigger a safety
  /// prompt based on threat level.
  void _addAlert({
    required AlertType type,
    required AlertThreatLevel threatLevel,
    required String message,
    Map<String, dynamic> metadata = const {},
  }) {
    // Avoid duplicate alerts of the same type
    final hasSameType = state.activeAlerts.any(
      (a) => a.type == type,
    );
    if (hasSameType) return;

    final alert = ActiveAlert(
      id: '${type.name}_'
          '${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      threatLevel: threatLevel,
      message: message,
      detectedAt: DateTime.now(),
      metadata: metadata,
    );

    final updatedAlerts = [
      ...state.activeAlerts,
      alert,
    ];

    state = state.copyWith(
      activeAlerts: updatedAlerts,
    );

    AppLogger.warning(
      'Alert added: ${alert.type.name} '
      '(${alert.threatLevel.name})',
      tag: _tag,
    );

    // Trigger appropriate response based on threat
    // level.
    switch (threatLevel) {
      case AlertThreatLevel.low:
        // Banner only — no prompt needed.
        break;
      case AlertThreatLevel.medium:
        // Show "Are you safe?" prompt without
        // countdown.
        state = state.copyWith(
          currentPrompt: alert,
        );
        break;
      case AlertThreatLevel.high:
        // Show "Are you safe?" with countdown.
        _startSafetyCountdown(alert);
        break;
      case AlertThreatLevel.critical:
        // Immediately escalate — no prompt.
        _escalate();
        break;
    }
  }

  /// Start the "Are you safe?" countdown timer.
  /// If the user does not respond within 60 seconds,
  /// escalate to panic.
  void _startSafetyCountdown(ActiveAlert alert) {
    _countdownTimer?.cancel();

    state = state.copyWith(
      currentPrompt: alert,
      safetyCountdown:
          AppDimensions.safetyPromptTimeout,
    );

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        final remaining = state.safetyCountdown - 1;

        if (remaining <= 0) {
          timer.cancel();
          _escalate();
          return;
        }

        state = state.copyWith(
          safetyCountdown: remaining,
        );
      },
    );
  }

  /// Escalate to panic — notify the parent via
  /// callback.
  void _escalate() {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    AppLogger.critical(
      'Alert escalated to panic',
      tag: _tag,
    );

    state = state.copyWith(
      clearPrompt: true,
      safetyCountdown: 0,
    );

    onEscalate?.call();
  }
}

// ── Provider ──

final alertsNotifierProvider =
    NotifierProvider<AlertsNotifier, AlertsState>(
  AlertsNotifier.new,
);
