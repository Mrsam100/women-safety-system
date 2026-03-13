import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/route_names.dart';
import 'package:saferide/core/providers/shared_providers.dart';

/// Card showing active ride information: duration, distance,
/// route name, and safety score. Hidden when no ride active.
class RideStatusCard extends ConsumerStatefulWidget {
  const RideStatusCard({super.key});

  @override
  ConsumerState<RideStatusCard> createState() =>
      _RideStatusCardState();
}

class _RideStatusCardState
    extends ConsumerState<RideStatusCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {
            _elapsed += const Duration(seconds: 1);
          });
        }
      },
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes =
        (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds =
        (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isRideActive = ref.watch(isRideActiveProvider);
    final threatScore = ref.watch(threatScoreProvider);
    final isEmergency = ref.watch(isEmergencyProvider);

    if (!isRideActive) return const SizedBox.shrink();

    final scoreColor = isEmergency
        ? AppColors.danger
        : threatScore <= AppDimensions.greenMax
            ? AppColors.safe
            : threatScore <= AppDimensions.yellowMax
                ? AppColors.warning
                : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
      ),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusLG,
          ),
          side: BorderSide(
            color: AppColors.safe.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () => context.push(RouteNames.ride),
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusLG,
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              AppDimensions.paddingMD,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.safe,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ride Active',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        color: AppColors.safe,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(
                  height: AppDimensions.paddingMD,
                ),
                Row(
                  children: [
                    _InfoTile(
                      icon: Icons.timer_outlined,
                      label: 'Duration',
                      value: _formatDuration(_elapsed),
                    ),
                    const SizedBox(
                      width: AppDimensions.paddingLG,
                    ),
                    _InfoTile(
                      icon: Icons.shield_outlined,
                      label: 'Safety',
                      value: '$threatScore',
                      valueColor: scoreColor,
                    ),
                  ],
                ),
                if (isEmergency) ...[
                  const SizedBox(
                    height: AppDimensions.paddingSM,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingSM,
                    ),
                    decoration: BoxDecoration(
                      color:
                          AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Emergency Alert Active',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style:
                  theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    valueColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
