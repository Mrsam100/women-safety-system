import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/providers/service_providers.dart';
import 'package:saferide/features/safety/domain/usecases/start_shake_detection.dart';
import 'package:saferide/features/safety/presentation/providers/panic_provider.dart';

// ── Use case provider ──

final startShakeDetectionProvider =
    Provider<StartShakeDetection>((ref) {
  return StartShakeDetection(
    ref.watch(shakeServiceProvider),
  );
});

// ── Shake state ──

class ShakeState {
  final bool isActive;
  final int shakeCount;
  final StreamSubscription<void>? subscription;

  const ShakeState({
    this.isActive = false,
    this.shakeCount = 0,
    this.subscription,
  });

  ShakeState copyWith({
    bool? isActive,
    int? shakeCount,
    StreamSubscription<void>? subscription,
  }) {
    return ShakeState(
      isActive: isActive ?? this.isActive,
      shakeCount: shakeCount ?? this.shakeCount,
      subscription: subscription ?? this.subscription,
    );
  }
}

class ShakeNotifier extends Notifier<ShakeState> {
  @override
  ShakeState build() {
    ref.onDispose(() {
      stop();
    });
    return const ShakeState();
  }

  StartShakeDetection get _startShakeDetection =>
      ref.read(startShakeDetectionProvider);

  /// Start shake detection. Shake events will forward to
  /// the panic trigger.
  void start() {
    if (state.isActive) return;

    final result = _startShakeDetection(
      onShake: () {
        state = state.copyWith(
          shakeCount: state.shakeCount + 1,
        );
        ref.read(panicNotifierProvider.notifier).startCountdown();
      },
    );

    result.fold(
      (_) {},
      (subscription) {
        state = ShakeState(
          isActive: true,
          shakeCount: 0,
          subscription: subscription,
        );
      },
    );
  }

  /// Stop shake detection.
  void stop() {
    state.subscription?.cancel();
    _startShakeDetection.stop();
    state = const ShakeState();
  }
}

final shakeNotifierProvider =
    NotifierProvider<ShakeNotifier, ShakeState>(
  ShakeNotifier.new,
);
