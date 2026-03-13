import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/constants/route_names.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/core/providers/shared_providers.dart';
import 'package:saferide/features/home/presentation/widgets/quick_actions.dart';
import 'package:saferide/features/home/presentation/widgets/ride_status_card.dart';
import 'package:saferide/features/home/presentation/widgets/safety_dashboard.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isRideActive = ref.watch(isRideActiveProvider);
    final theme = Theme.of(context);

    final userName = authState.valueOrNull?.displayName;
    final greeting = _greeting();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.settings,
            onPressed: () =>
                context.push(RouteNames.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger re-read of providers
          ref.invalidate(authStateProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppDimensions.paddingMD,
            bottom: AppDimensions.paddingXXL,
          ),
          children: [
            // Greeting
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLG,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (userName != null &&
                      userName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(
                    height: AppDimensions.paddingXS,
                  ),
                  Text(
                    AppStrings.appTagline,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: AppDimensions.paddingLG,
            ),

            // Safety Dashboard
            const SafetyDashboard(),

            const SizedBox(
              height: AppDimensions.paddingLG,
            ),

            // Active Ride Status (hidden if no ride)
            if (isRideActive) ...[
              const RideStatusCard(),
              const SizedBox(
                height: AppDimensions.paddingLG,
              ),
            ],

            // Quick Actions
            const QuickActions(),

            const SizedBox(
              height: AppDimensions.paddingLG,
            ),

            // Ride History shortcut
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMD,
              ),
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push(RouteNames.rideHistory),
                icon: const Icon(Icons.history),
                label: const Text('View Ride History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusLG,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
