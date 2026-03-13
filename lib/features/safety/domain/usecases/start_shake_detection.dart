import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/services/shake_service.dart';
import 'package:saferide/core/utils/logger.dart';

/// Starts the shake detection service and connects it to
/// the panic trigger callback.
///
/// When the required shake pattern is detected, [onShake]
/// is invoked so the presentation layer can initiate the
/// panic sequence.
class StartShakeDetection {
  final ShakeService _shakeService;

  static const _tag = 'StartShakeDetection';

  const StartShakeDetection(this._shakeService);

  /// Begin listening for shake events.
  ///
  /// Returns a [StreamSubscription] that the caller should
  /// cancel when the ride ends or the user disables shake
  /// detection.
  Either<Failure, StreamSubscription<void>> call({
    required void Function() onShake,
  }) {
    try {
      if (!_shakeService.isListening) {
        _shakeService.startListening();
      }

      final subscription = _shakeService.onShake.listen(
        (_) {
          AppLogger.info(
            'Shake detected — forwarding to panic',
            tag: _tag,
          );
          onShake();
        },
      );

      AppLogger.info(
        'Shake detection started and connected to panic',
        tag: _tag,
      );

      return Right(subscription);
    } catch (e) {
      AppLogger.error(
        'Failed to start shake detection',
        tag: _tag,
        error: e,
      );
      return Left(
        ServerFailure(
          message: 'Shake detection failed: $e',
          code: 'SHAKE_FAILED',
        ),
      );
    }
  }

  /// Stop the shake service entirely.
  void stop() {
    _shakeService.stopListening();
    AppLogger.info(
      'Shake detection stopped',
      tag: _tag,
    );
  }
}
