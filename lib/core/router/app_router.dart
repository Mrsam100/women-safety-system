import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/route_names.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/core/providers/shared_providers.dart';
import 'package:saferide/features/auth/presentation/screens/auth_wrapper.dart';
import 'package:saferide/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:saferide/features/auth/presentation/screens/phone_input_screen.dart';
import 'package:saferide/features/emergency_contacts/presentation/screens/manage_contacts_screen.dart';
import 'package:saferide/features/evidence/presentation/screens/evidence_vault_screen.dart';
import 'package:saferide/features/home/presentation/screens/home_screen.dart';
import 'package:saferide/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:saferide/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:saferide/features/ride/presentation/screens/ride_history_screen.dart';
import 'package:saferide/features/ride/presentation/screens/ride_screen.dart';
import 'package:saferide/features/ride/presentation/screens/ride_summary_screen.dart';
import 'package:saferide/features/safety/presentation/screens/fake_call_screen.dart';
import 'package:saferide/features/safety/presentation/screens/panic_screen.dart';
import 'package:saferide/features/settings/presentation/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileComplete =
      ref.watch(profileCompleteProvider);
  final onboardingComplete =
      ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: RouteNames.home,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      // Don't redirect while auth state is loading
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final isAuthRoute =
          state.matchedLocation.startsWith(RouteNames.auth);
      final isOnboardingRoute =
          state.matchedLocation == RouteNames.onboarding;
      final isProfileRoute =
          state.matchedLocation == RouteNames.profileSetup;
      final isDashboardRoute =
          state.matchedLocation
              .startsWith(RouteNames.contactDashboard);

      // Allow contact dashboard without auth
      if (isDashboardRoute) return null;

      // Not logged in → auth
      if (!isLoggedIn && !isAuthRoute) {
        return RouteNames.auth;
      }

      // Logged in but on auth page → redirect
      if (isLoggedIn && isAuthRoute) {
        if (!onboardingComplete) {
          return RouteNames.onboarding;
        }
        if (!profileComplete) {
          return RouteNames.profileSetup;
        }
        return RouteNames.home;
      }

      // Logged in, onboarding not done
      if (isLoggedIn &&
          !onboardingComplete &&
          !isOnboardingRoute &&
          !isAuthRoute) {
        return RouteNames.onboarding;
      }

      // Logged in, profile not complete
      if (isLoggedIn &&
          onboardingComplete &&
          !profileComplete &&
          !isProfileRoute &&
          !isAuthRoute) {
        return RouteNames.profileSetup;
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: RouteNames.auth,
        builder: (context, state) => const AuthWrapper(),
        routes: [
          GoRoute(
            path: 'phone',
            builder: (context, state) =>
                const PhoneInputScreen(),
          ),
          GoRoute(
            path: 'otp',
            redirect: (context, state) {
              final extra = state.extra;
              if (extra is! String || extra.isEmpty) {
                return RouteNames.auth;
              }
              return null;
            },
            builder: (context, state) {
              final verificationId =
                  state.extra as String;
              return OtpVerificationScreen(
                verificationId: verificationId,
              );
            },
          ),
        ],
      ),

      // Onboarding
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) =>
            const OnboardingScreen(),
      ),

      // Profile Setup
      GoRoute(
        path: RouteNames.profileSetup,
        builder: (context, state) =>
            const ProfileSetupScreen(),
      ),

      // Home
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),

      // Ride
      GoRoute(
        path: RouteNames.ride,
        builder: (context, state) => const RideScreen(),
      ),
      GoRoute(
        path: RouteNames.rideHistory,
        builder: (context, state) =>
            const RideHistoryScreen(),
      ),
      GoRoute(
        path: '${RouteNames.rideSummary}/:rideId',
        builder: (context, state) {
          final rideId = state.pathParameters['rideId']!;
          return RideSummaryScreen(rideId: rideId);
        },
      ),

      // Safety
      GoRoute(
        path: RouteNames.panic,
        builder: (context, state) => const PanicScreen(),
      ),
      GoRoute(
        path: RouteNames.fakeCall,
        builder: (context, state) => const FakeCallScreen(),
      ),

      // Contacts
      GoRoute(
        path: RouteNames.manageContacts,
        builder: (context, state) =>
            const ManageContactsScreen(),
      ),

      // Evidence
      GoRoute(
        path: RouteNames.evidenceVault,
        builder: (context, state) =>
            const EvidenceVaultScreen(),
      ),

      // Settings
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
