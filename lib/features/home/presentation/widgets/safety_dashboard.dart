import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/providers/service_providers.dart';
import 'package:saferide/core/providers/shared_providers.dart';

/// Dashboard card showing current safety status,
/// threat score (if ride active), connectivity status,
/// and battery level.
class SafetyDashboard extends ConsumerWidget {
  const SafetyDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRideActive = ref.watch(isRideActiveProvider);
    final isEmergency = ref.watch(isEmergencyProvider);
    final threatScore = ref.watch(threatScoreProvider);
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.valueOrNull ?? true;

    final statusColor = _statusColor(
      isEmergency: isEmergency,
      threatScore: threatScore,
      isRideActive: isRideActive,
    );
    final statusLabel = _statusLabel(
      isEmergency: isEmergency,
      threatScore: threatScore,
      isRideActive: isRideActive,
    );
    final statusIcon = _statusIcon(
      isEmergency: isEmergency,
      threatScore: threatScore,
      isRideActive: isRideActive,
    );

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusLG,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusLG,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(
          AppDimensions.paddingLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(
                    AppDimensions.paddingSM,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: AppDimensions.iconLG,
                  ),
                ),
                const SizedBox(
                  width: AppDimensions.paddingMD,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRideActive
                            ? 'Ride in progress'
                            : 'No active ride',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Threat score bar (only during ride)
            if (isRideActive) ...[
              const SizedBox(
                height: AppDimensions.paddingMD,
              ),
              _ThreatScoreBar(
                score: threatScore,
                color: statusColor,
              ),
            ],

            const SizedBox(
              height: AppDimensions.paddingMD,
            ),
            const Divider(height: 1),
            const SizedBox(
              height: AppDimensions.paddingMD,
            ),

            // Status indicators row
            Row(
              children: [
                _StatusChip(
                  icon: isOnline
                      ? Icons.wifi
                      : Icons.wifi_off,
                  label: isOnline ? 'Online' : 'Offline',
                  color: isOnline
                      ? AppColors.safe
                      : AppColors.danger,
                ),
                const SizedBox(
                  width: AppDimensions.paddingMD,
                ),
                _BatteryChip(ref: ref),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor({
    required bool isEmergency,
    required int threatScore,
    required bool isRideActive,
  }) {
    if (isEmergency) return AppColors.danger;
    if (!isRideActive) return AppColors.safe;
    if (threatScore <= AppDimensions.greenMax) {
      return AppColors.safe;
    }
    if (threatScore <= AppDimensions.yellowMax) {
      return AppColors.warning;
    }
    if (threatScore <= AppDimensions.orangeMax) {
      return AppColors.warningDark;
    }
    return AppColors.danger;
  }

  String _statusLabel({
    required bool isEmergency,
    required int threatScore,
    required bool isRideActive,
  }) {
    if (isEmergency) return 'Emergency';
    if (!isRideActive) return 'Safe';
    if (threatScore <= AppDimensions.greenMax) {
      return 'Safe';
    }
    if (threatScore <= AppDimensions.yellowMax) {
      return 'Caution';
    }
    if (threatScore <= AppDimensions.orangeMax) {
      return 'Alert';
    }
    return 'Emergency';
  }

  IconData _statusIcon({
    required bool isEmergency,
    required int threatScore,
    required bool isRideActive,
  }) {
    if (isEmergency) return Icons.warning_amber_rounded;
    if (!isRideActive) return Icons.shield;
    if (threatScore <= AppDimensions.greenMax) {
      return Icons.shield;
    }
    if (threatScore <= AppDimensions.yellowMax) {
      return Icons.shield_outlined;
    }
    return Icons.warning_amber_rounded;
  }
}

class _ThreatScoreBar extends StatelessWidget {
  final int score;
  final Color color;

  const _ThreatScoreBar({
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Threat Score',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$score / 100',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingXS),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusSM,
          ),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor:
                AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BatteryChip extends StatelessWidget {
  final WidgetRef ref;

  const _BatteryChip({required this.ref});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: ref
          .read(batteryServiceProvider)
          .getBatteryLevel(),
      builder: (context, snapshot) {
        final level = snapshot.data ?? 100;
        final color = level <= AppDimensions
                .lowBatteryThreshold
            ? AppColors.danger
            : level <= 30
                ? AppColors.warning
                : AppColors.safe;
        final icon = level <= AppDimensions
                .lowBatteryThreshold
            ? Icons.battery_alert
            : level <= 30
                ? Icons.battery_3_bar
                : Icons.battery_full;

        return _StatusChip(
          icon: icon,
          label: '$level%',
          color: color,
        );
      },
    );
  }
}
