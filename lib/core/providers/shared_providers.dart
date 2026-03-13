import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/providers/service_providers.dart';

/// Whether the app is currently online.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return connectivity.onConnectivityChanged;
});

/// Whether a ride is currently active.
class IsRideActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final isRideActiveProvider =
    NotifierProvider<IsRideActiveNotifier, bool>(
  IsRideActiveNotifier.new,
);

/// Current active ride ID.
class ActiveRideIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final activeRideIdProvider =
    NotifierProvider<ActiveRideIdNotifier, String?>(
  ActiveRideIdNotifier.new,
);

/// Whether the app is in emergency state.
class IsEmergencyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final isEmergencyProvider =
    NotifierProvider<IsEmergencyNotifier, bool>(
  IsEmergencyNotifier.new,
);

/// Current threat score (0-100).
class ThreatScoreNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value.clamp(0, 100);
}

final threatScoreProvider =
    NotifierProvider<ThreatScoreNotifier, int>(
  ThreatScoreNotifier.new,
);

/// Whether onboarding has been completed.
class OnboardingCompleteNotifier extends Notifier<bool> {
  @override
  bool build() {
    final localStorage =
        ref.read(localStorageServiceProvider);
    return localStorage.getSetting<bool>(
            'onboarding_complete') ??
        false;
  }

  void set(bool value) {
    state = value;
    ref
        .read(localStorageServiceProvider)
        .saveSetting('onboarding_complete', value);
  }
}

final onboardingCompleteProvider =
    NotifierProvider<OnboardingCompleteNotifier, bool>(
  OnboardingCompleteNotifier.new,
);

/// Whether profile setup is complete.
class ProfileCompleteNotifier extends Notifier<bool> {
  @override
  bool build() {
    final localStorage =
        ref.read(localStorageServiceProvider);
    return localStorage.getSetting<bool>(
            'profile_complete') ??
        false;
  }

  void set(bool value) {
    state = value;
    ref
        .read(localStorageServiceProvider)
        .saveSetting('profile_complete', value);
  }
}

final profileCompleteProvider =
    NotifierProvider<ProfileCompleteNotifier, bool>(
  ProfileCompleteNotifier.new,
);
