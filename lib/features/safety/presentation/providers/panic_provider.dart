import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/core/providers/service_providers.dart';
import 'package:saferide/features/safety/data/datasources/safety_local_datasource.dart';
import 'package:saferide/features/safety/data/datasources/safety_remote_datasource.dart';
import 'package:saferide/features/safety/data/repositories/safety_repository_impl.dart';
import 'package:saferide/features/safety/domain/entities/alert.dart';
import 'package:saferide/features/safety/domain/repositories/safety_repository.dart';
import 'package:saferide/features/safety/domain/usecases/trigger_panic.dart';

// ── Datasource providers ──

final safetyRemoteDatasourceProvider =
    Provider<SafetyRemoteDatasource>((ref) {
  return SafetyRemoteDatasource(
    firestore: ref.watch(firestoreProvider),
  );
});

final safetyLocalDatasourceProvider =
    Provider<SafetyLocalDatasource>((ref) {
  return SafetyLocalDatasource(
    localStorage: ref.watch(localStorageServiceProvider),
  );
});

// ── Repository provider ──

final safetyRepositoryProvider =
    Provider<SafetyRepository>((ref) {
  return SafetyRepositoryImpl(
    remoteDatasource: ref.watch(
      safetyRemoteDatasourceProvider,
    ),
    localDatasource: ref.watch(
      safetyLocalDatasourceProvider,
    ),
  );
});

// ── Use case provider ──

final triggerPanicUseCaseProvider =
    Provider<TriggerPanic>((ref) {
  return TriggerPanic(
    locationService: ref.watch(locationServiceProvider),
    audioService: ref.watch(audioServiceProvider),
    smsService: ref.watch(smsServiceProvider),
    notificationService: ref.watch(
      notificationServiceProvider,
    ),
    connectivityService: ref.watch(
      connectivityServiceProvider,
    ),
    localStorageService: ref.watch(
      localStorageServiceProvider,
    ),
    remoteDatasource: ref.watch(
      safetyRemoteDatasourceProvider,
    ),
    localDatasource: ref.watch(
      safetyLocalDatasourceProvider,
    ),
  );
});

// ── Panic state ──

enum PanicStatus {
  idle,
  countingDown,
  triggering,
  active,
  resolved,
  error,
}

class PanicState {
  final PanicStatus status;
  final Alert? alert;
  final String? errorMessage;
  final int countdownSeconds;

  const PanicState({
    this.status = PanicStatus.idle,
    this.alert,
    this.errorMessage,
    this.countdownSeconds = 0,
  });

  bool get isPanicking =>
      status == PanicStatus.triggering ||
      status == PanicStatus.active;

  PanicState copyWith({
    PanicStatus? status,
    Alert? alert,
    String? errorMessage,
    int? countdownSeconds,
  }) {
    return PanicState(
      status: status ?? this.status,
      alert: alert ?? this.alert,
      errorMessage: errorMessage ?? this.errorMessage,
      countdownSeconds:
          countdownSeconds ?? this.countdownSeconds,
    );
  }
}

class PanicNotifier extends Notifier<PanicState> {
  @override
  PanicState build() {
    return const PanicState();
  }

  TriggerPanic get _triggerPanic =>
      ref.read(triggerPanicUseCaseProvider);

  /// Start the panic countdown (3 seconds).
  void startCountdown() {
    state = state.copyWith(
      status: PanicStatus.countingDown,
      countdownSeconds: 3,
    );
  }

  /// Cancel the countdown and return to idle.
  /// Safe to call at any time — only cancels if
  /// currently counting down.
  void cancelCountdown() {
    if (state.status != PanicStatus.countingDown) return;
    state = const PanicState();
  }

  /// Update countdown tick.
  void updateCountdown(int remaining) {
    if (remaining <= 0) return;
    // If user already cancelled, don't update
    if (state.status != PanicStatus.countingDown) return;
    state = state.copyWith(countdownSeconds: remaining);
  }

  /// Execute the full panic sequence.
  Future<void> triggerPanic({
    required String userId,
    required String rideId,
    required List<String> contactPhones,
    List<String> contactFcmTokens = const [],
    required String userName,
  }) async {
    state = state.copyWith(
      status: PanicStatus.triggering,
    );

    final result = await _triggerPanic(
      userId: userId,
      rideId: rideId,
      contactPhones: contactPhones,
      contactFcmTokens: contactFcmTokens,
      userName: userName,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: PanicStatus.error,
        errorMessage: failure.message,
      ),
      (alert) => state = state.copyWith(
        status: PanicStatus.active,
        alert: alert,
      ),
    );
  }

  /// Cancel or resolve the panic.
  void resolve() {
    state = const PanicState(
      status: PanicStatus.resolved,
    );
  }

  /// Reset to idle state.
  void reset() {
    state = const PanicState();
  }
}

final panicNotifierProvider =
    NotifierProvider<PanicNotifier, PanicState>(
  PanicNotifier.new,
);
