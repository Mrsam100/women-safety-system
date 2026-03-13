import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';

/// Displays the current safety status as a color-coded
/// indicator with descriptive text.
///
/// Threat score ranges:
///   0–30  → green  (Safe)
///   31–60 → yellow (Caution)
///   61–80 → orange (Alert)
///   81+   → red    (Emergency)
class SafetyStatusIndicator extends StatelessWidget {
  final double threatScore;

  const SafetyStatusIndicator({
    super.key,
    required this.threatScore,
  });

  @override
  Widget build(BuildContext context) {
    final status = _resolveStatus(threatScore);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusXL,
        ),
        border: Border.all(
          color: status.color.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Colored dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status.color,
              boxShadow: [
                BoxShadow(
                  color:
                      status.color.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSM),
          // Status text
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingXS),
          // Threat score
          Text(
            '(${threatScore.toInt()})',
            style: TextStyle(
              color:
                  status.color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static _StatusInfo _resolveStatus(double score) {
    if (score <= AppDimensions.greenMax) {
      return const _StatusInfo(
        label: AppStrings.safeStatus,
        color: AppColors.safe,
      );
    } else if (score <= AppDimensions.yellowMax) {
      return const _StatusInfo(
        label: AppStrings.cautionStatus,
        color: Color(0xFFFFEB3B), // yellow
      );
    } else if (score <= AppDimensions.orangeMax) {
      return const _StatusInfo(
        label: AppStrings.alertStatus,
        color: AppColors.warning,
      );
    } else {
      return const _StatusInfo(
        label: AppStrings.emergencyStatus,
        color: AppColors.danger,
      );
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;

  const _StatusInfo({
    required this.label,
    required this.color,
  });
}
