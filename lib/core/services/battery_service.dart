import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/utils/logger.dart';

class BatteryService {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _subscription;
  final _lowBatteryController = StreamController<int>.broadcast();
  bool _hasAlerted = false;

  /// Emits battery level when it drops below threshold.
  Stream<int> get onLowBattery => _lowBatteryController.stream;

  Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }

  void startMonitoring() {
    _hasAlerted = false;
    _subscription = _battery.onBatteryStateChanged.listen(
      (_) async {
        final level = await getBatteryLevel();
        if (level <= AppDimensions.lowBatteryThreshold &&
            !_hasAlerted) {
          _hasAlerted = true;
          _lowBatteryController.add(level);
          AppLogger.warning(
            'Low battery: $level%',
            tag: 'BatteryService',
          );
        }
      },
    );
    AppLogger.info(
      'Battery monitoring started',
      tag: 'BatteryService',
    );
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _hasAlerted = false;
    AppLogger.info(
      'Battery monitoring stopped',
      tag: 'BatteryService',
    );
  }

  Future<void> dispose() async {
    stopMonitoring();
    await _lowBatteryController.close();
  }
}
