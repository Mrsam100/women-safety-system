import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/constants/route_names.dart';
import 'package:saferide/core/providers/shared_providers.dart';
import 'package:saferide/features/emergency_contacts/presentation/providers/contacts_provider.dart';
import 'package:saferide/features/ride/presentation/providers/ride_provider.dart';
import 'package:saferide/features/ride/presentation/widgets/ride_controls.dart';
import 'package:saferide/features/ride/presentation/widgets/ride_map.dart';
import 'package:saferide/features/safety/presentation/providers/panic_provider.dart';
import 'package:saferide/features/safety/presentation/widgets/panic_button.dart';
import 'package:saferide/features/safety/presentation/widgets/safety_status_indicator.dart';

/// Full ride monitoring screen combining the live map,
/// ride controls, panic button, and safety indicator.
class RideScreen extends ConsumerWidget {
  const RideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId =
        FirebaseAuth.instance.currentUser?.uid ?? '';
    final rideState = ref.watch(rideNotifierProvider);
    final threatScore = ref.watch(threatScoreProvider);
    final isActive = rideState.isActive;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          const Positioned.fill(
            child: RideMap(),
          ),

          // Top bar with safety indicator + back
          Positioned(
            top: MediaQuery.of(context).padding.top +
                AppDimensions.paddingSM,
            left: AppDimensions.paddingMD,
            right: AppDimensions.paddingMD,
            child: Row(
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () =>
                        Navigator.of(context).pop(),
                  ),
                ),
                const Spacer(),

                // Safety status indicator
                if (isActive)
                  SafetyStatusIndicator(
                    threatScore:
                        threatScore.toDouble(),
                  ),
              ],
            ),
          ),

          // Ride info overlay (deviation warning)
          if (isActive &&
              rideState.deviationKm >
                  AppDimensions.deviationThresholdKm)
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  AppDimensions.paddingXXL +
                  AppDimensions.paddingMD,
              left: AppDimensions.paddingLG,
              right: AppDimensions.paddingLG,
              child: Container(
                padding: const EdgeInsets.all(
                  AppDimensions.paddingSM,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger
                      .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMD,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.textOnDanger,
                    ),
                    const SizedBox(
                      width: AppDimensions.paddingSM,
                    ),
                    Expanded(
                      child: Text(
                        'Route deviation detected: '
                        '${rideState.deviationKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: AppColors.textOnDanger,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom panel: controls + panic button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: AppDimensions.paddingMD,
                bottom:
                    MediaQuery.of(context).padding.bottom +
                        AppDimensions.paddingMD,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(
                    AppDimensions.radiusXL,
                  ),
                  topRight: Radius.circular(
                    AppDimensions.radiusXL,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ride status label
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.paddingSM,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration:
                                const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.safe,
                            ),
                          ),
                          const SizedBox(
                            width:
                                AppDimensions.paddingSM,
                          ),
                          Text(
                            AppStrings.rideActive,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: AppColors.safe,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          if (rideState.routePoints
                              .isNotEmpty) ...[
                            const SizedBox(
                              width: AppDimensions
                                  .paddingMD,
                            ),
                            Text(
                              '${rideState.routePoints.length} pts',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: AppColors
                                    .textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Ride controls
                  RideControls(
                    userId: userId,
                    onRideEnded: () {
                      final ride =
                          rideState.currentRide;
                      if (ride != null) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),

                  // Panic button (only during ride)
                  if (isActive) ...[
                    const SizedBox(
                      height: AppDimensions.paddingMD,
                    ),
                    PanicButton(
                      onActivated: () {
                        final ride =
                            rideState.currentRide;
                        if (ride == null) return;

                        final user = FirebaseAuth
                            .instance.currentUser;
                        if (user == null) return;

                        final contactsState =
                            ref.read(contactsProvider);
                        final phones = contactsState
                            .contacts
                            .map((c) => c.phoneNumber)
                            .toList();
                        final tokens = contactsState
                            .contacts
                            .where(
                              (c) => c.fcmToken != null,
                            )
                            .map((c) => c.fcmToken!)
                            .toList();

                        ref
                            .read(panicNotifierProvider
                                .notifier)
                            .triggerPanic(
                              userId: user.uid,
                              rideId: ride.id,
                              contactPhones: phones,
                              contactFcmTokens: tokens,
                              userName:
                                  user.displayName ??
                                      'User',
                            );

                        context.push(RouteNames.panic);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
