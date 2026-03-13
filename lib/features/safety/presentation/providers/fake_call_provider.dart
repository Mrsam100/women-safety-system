import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/features/safety/domain/usecases/trigger_fake_call.dart';

// ── Use case provider ──

final triggerFakeCallUseCaseProvider =
    Provider<TriggerFakeCall>((ref) {
  return const TriggerFakeCall();
});

// ── Fake call state ──

enum FakeCallStatus {
  idle,
  scheduled,
  ringing,
  answered,
  ended,
}

class FakeCallState {
  final FakeCallStatus status;
  final String callerName;
  final int delaySeconds;
  final int remainingSeconds;
  final Timer? timer;
  final Timer? countdownTimer;

  const FakeCallState({
    this.status = FakeCallStatus.idle,
    this.callerName = 'Mom',
    this.delaySeconds = 15,
    this.remainingSeconds = 0,
    this.timer,
    this.countdownTimer,
  });

  bool get isScheduled => status == FakeCallStatus.scheduled;
  bool get isRinging => status == FakeCallStatus.ringing;
  bool get isAnswered => status == FakeCallStatus.answered;

  FakeCallState copyWith({
    FakeCallStatus? status,
    String? callerName,
    int? delaySeconds,
    int? remainingSeconds,
    Timer? timer,
    Timer? countdownTimer,
  }) {
    return FakeCallState(
      status: status ?? this.status,
      callerName: callerName ?? this.callerName,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      remainingSeconds:
          remainingSeconds ?? this.remainingSeconds,
      timer: timer ?? this.timer,
      countdownTimer:
          countdownTimer ?? this.countdownTimer,
    );
  }
}

class FakeCallNotifier extends Notifier<FakeCallState> {
  /// Callback invoked when the fake call fires.
  /// The presentation layer should navigate to the
  /// fake-call screen.
  void Function()? onFakeCallTriggered;

  @override
  FakeCallState build() {
    ref.onDispose(() {
      state.timer?.cancel();
      state.countdownTimer?.cancel();
    });
    return const FakeCallState();
  }

  TriggerFakeCall get _triggerFakeCall =>
      ref.read(triggerFakeCallUseCaseProvider);

  /// Update the caller name shown on the fake call.
  void setCallerName(String name) {
    state = state.copyWith(callerName: name);
  }

  /// Update the delay in seconds.
  void setDelay(int seconds) {
    state = state.copyWith(delaySeconds: seconds);
  }

  /// Schedule a fake call after the configured delay.
  void schedule() {
    cancel(); // cancel any existing schedule

    final delay = Duration(seconds: state.delaySeconds);

    final result = _triggerFakeCall(
      delay: delay,
      onTrigger: () {
        state = state.copyWith(
          status: FakeCallStatus.ringing,
        );
        onFakeCallTriggered?.call();
      },
    );

    result.fold(
      (_) {},
      (timer) {
        // Start a countdown timer for UI feedback
        final countdown = Timer.periodic(
          const Duration(seconds: 1),
          (_) {
            final remaining = state.remainingSeconds - 1;
            if (remaining <= 0) {
              state.countdownTimer?.cancel();
            } else {
              state = state.copyWith(
                remainingSeconds: remaining,
              );
            }
          },
        );

        state = FakeCallState(
          status: FakeCallStatus.scheduled,
          callerName: state.callerName,
          delaySeconds: state.delaySeconds,
          remainingSeconds: state.delaySeconds,
          timer: timer,
          countdownTimer: countdown,
        );
      },
    );
  }

  /// Cancel a scheduled fake call.
  void cancel() {
    state.timer?.cancel();
    state.countdownTimer?.cancel();
    state = FakeCallState(
      callerName: state.callerName,
      delaySeconds: state.delaySeconds,
    );
  }

  /// Accept the fake call.
  void answer() {
    state = state.copyWith(
      status: FakeCallStatus.answered,
    );
  }

  /// Decline or end the fake call.
  void end() {
    state.timer?.cancel();
    state.countdownTimer?.cancel();
    state = FakeCallState(
      status: FakeCallStatus.ended,
      callerName: state.callerName,
      delaySeconds: state.delaySeconds,
    );
  }

  /// Reset to idle.
  void reset() {
    cancel();
    state = FakeCallState(
      callerName: state.callerName,
      delaySeconds: state.delaySeconds,
    );
  }
}

final fakeCallNotifierProvider =
    NotifierProvider<FakeCallNotifier, FakeCallState>(
  FakeCallNotifier.new,
);
