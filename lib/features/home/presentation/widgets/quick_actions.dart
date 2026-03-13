import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/route_names.dart';

/// Grid of quick action buttons for the home screen.
///
/// Actions: Start Ride, Fake Call, Emergency Contacts,
/// Ride History. Each navigates via go_router.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppDimensions.paddingMD,
            mainAxisSpacing: AppDimensions.paddingMD,
            childAspectRatio: 1.6,
            children: const [
              _ActionCard(
                icon: Icons.directions_car,
                label: 'Start Ride',
                color: AppColors.safe,
                route: RouteNames.ride,
              ),
              _ActionCard(
                icon: Icons.phone,
                label: 'Fake Call',
                color: Color(0xFF2196F3),
                route: RouteNames.fakeCall,
              ),
              _ActionCard(
                icon: Icons.contacts,
                label: 'Contacts',
                color: AppColors.warning,
                route: RouteNames.manageContacts,
              ),
              _ActionCard(
                icon: Icons.history,
                label: 'Ride History',
                color: AppColors.primary,
                route: RouteNames.rideHistory,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusLG,
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusLG,
            ),
            border: Border.all(
              color: color.withOpacity(0.25),
            ),
          ),
          padding: const EdgeInsets.all(
            AppDimensions.paddingMD,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: AppDimensions.iconLG,
              ),
              const SizedBox(
                height: AppDimensions.paddingSM,
              ),
              Text(
                label,
                style:
                    theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
