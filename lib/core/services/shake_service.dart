import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/utils/logger.dart';

class ShakeService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  final _shakeController = StreamController<void>.broadcast();
  final _shakeTimestamps = <DateTime>[];
  bool _isListening = false;

  /// Emits an event each time a shake pattern is detected.
  Stream<void> get onShake => _shakeController.stream;

  bool get isListening => _isListening;

  void startListening() {
    if (_isListening) return;

    _subscription?.cancel();
    _isListening = true;
    _subscription = accelerometerEventStream().listen(
      _handleAccelerometerEvent,
    );
    AppLogger.info(
      'Shake detection started',
      tag: 'ShakeService',
    );
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x +
          event.y * event.y +
          event.z * event.z,
    );

    // Subtract gravity (~9.8 m/s²) to get user acceleration
    final userAcceleration = (magnitude - 9.8).abs();

    if (userAcceleration >= AppDimensions.shakeThreshold) {
      final now = DateTime.now();
      _shakeTimestamps.add(now);

      // Remove old timestamps outside the detection window
      _shakeTimestamps.removeWhere(
        (ts) =>
            now.difference(ts).inMilliseconds >
            AppDimensions.shakeWindowMs,
      );

      if (_shakeTimestamps.length >=
          AppDimensions.shakeCount) {
        _shakeTimestamps.clear();
        _shakeController.add(null);
        AppLogger.info(
          'Shake detected! Triggering alert.',
          tag: 'ShakeService',
        );
      }
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    _shakeTimestamps.clear();
    AppLogger.info(
      'Shake detection stopped',
      tag: 'ShakeService',
    );
  }

  Future<void> dispose() async {
    stopListening();
    await _shakeController.close();
  }
}
