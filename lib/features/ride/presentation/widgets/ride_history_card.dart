import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/extensions/datetime_extensions.dart';
import 'package:saferide/features/ride/domain/entities/ride.dart';

/// A card displaying ride summary information: date,
/// duration, status badge, and alerts count.
class RideHistoryCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback? onTap;

  const RideHistoryCard({
    super.key,
    required this.ride,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingXS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusMD,
        ),
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusMD,
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(
            AppDimensions.paddingMD,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // Top row: date + status badge
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(ride.startedAt),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatusBadge(status: ride.status),
                ],
              ),
              const SizedBox(
                height: AppDimensions.paddingSM,
              ),

              // Address row
              if (ride.startAddress != null ||
                  ride.endAddress != null)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.paddingSM,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.route,
                        size: AppDimensions.iconSM,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(
                        width: AppDimensions.paddingXS,
                      ),
                      Expanded(
                        child: Text(
                          _formatRoute(),
                          style: theme
                              .textTheme.bodySmall
                              ?.copyWith(
                            color:
                                AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Bottom row: duration, distance, alerts
              Row(
                children: [
                  // Duration
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: _formatDuration(),
                  ),
                  const SizedBox(
                    width: AppDimensions.paddingMD,
                  ),

                  // Distance
                  if (ride.distanceKm != null)
                    _InfoChip(
                      icon: Icons.straighten,
                      label:
                          '${ride.distanceKm!.toStringAsFixed(1)} km',
                    ),

                  const Spacer(),

                  // Alerts count
                  if (ride.alertsTriggered > 0)
                    Container(
                      padding: const EdgeInsets
                          .symmetric(
                        horizontal:
                            AppDimensions.paddingSM,
                        vertical:
                            AppDimensions.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(
                          AppDimensions.radiusSM,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${ride.alertsTriggered}',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight:
                                  FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Rating
                  if (ride.userRating != null) ...[
                    const SizedBox(
                      width: AppDimensions.paddingSM,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < ride.userRating!
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDuration() {
    final mins = ride.durationMinutes;
    if (mins == null) return '--';
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}m';
  }

  String _formatRoute() {
    final start = ride.startAddress ?? 'Start';
    final end = ride.endAddress ?? 'End';
    return '$start  ->  $end';
  }
}

class _StatusBadge extends StatelessWidget {
  final RideStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RideStatus.active => ('Active', AppColors.safe),
      RideStatus.completed => (
          'Completed',
          AppColors.primary,
        ),
      RideStatus.emergency => (
          'Emergency',
          AppColors.danger,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSM,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusSM,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
