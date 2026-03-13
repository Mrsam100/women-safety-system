import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/providers/service_providers.dart';

/// Whether the app is currently online.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return connectivity.onConnectivityChanged;
});

/// Whether a ride is currently active.
final isRideActiveProvider = StateProvider<bool>(
  (ref) => false,
);

/// Current active ride ID.
final activeRideIdProvider = StateProvider<String?>(
  (ref) => null,
);

/// Whether the app is in emergency state.
final isEmergencyProvider = StateProvider<bool>(
  (ref) => false,
);

/// Current threat score (0-100).
final threatScoreProvider = StateProvider<int>(
  (ref) => 0,
);

/// Whether onboarding has been completed.
final onboardingCompleteProvider = StateProvider<bool>(
  (ref) => false,
);

/// Whether profile setup is complete.
final profileCompleteProvider = StateProvider<bool>(
  (ref) => false,
);
