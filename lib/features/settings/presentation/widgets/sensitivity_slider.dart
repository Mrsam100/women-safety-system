import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/features/settings/domain/entities/app_settings.dart';

/// Custom slider for selecting alert sensitivity level.
///
/// Displays Low / Medium / High labels with a color-coded
/// track that transitions from green to orange to red.
class SensitivitySlider extends StatelessWidget {
  final AlertSensitivity value;
  final ValueChanged<AlertSensitivity> onChanged;

  const SensitivitySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  double get _sliderValue {
    switch (value) {
      case AlertSensitivity.low:
        return 0;
      case AlertSensitivity.medium:
        return 1;
      case AlertSensitivity.high:
        return 2;
    }
  }

  Color get _activeColor {
    switch (value) {
      case AlertSensitivity.low:
        return AppColors.safe;
      case AlertSensitivity.medium:
        return AppColors.warning;
      case AlertSensitivity.high:
        return AppColors.danger;
    }
  }

  String get _label {
    switch (value) {
      case AlertSensitivity.low:
        return 'Low';
      case AlertSensitivity.medium:
        return 'Medium';
      case AlertSensitivity.high:
        return 'High';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alert Sensitivity',
              style: theme.textTheme.titleSmall,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSM,
                vertical: AppDimensions.paddingXS,
              ),
              decoration: BoxDecoration(
                color: _activeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusMD,
                ),
              ),
              child: Text(
                _label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _activeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSM),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _activeColor,
            inactiveTrackColor:
                _activeColor.withOpacity(0.2),
            thumbColor: _activeColor,
            overlayColor: _activeColor.withOpacity(0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
            ),
          ),
          child: Slider(
            value: _sliderValue,
            min: 0,
            max: 2,
            divisions: 2,
            onChanged: (val) {
              onChanged(
                AlertSensitivity.values[val.round()],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMD,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.safe,
                ),
              ),
              Text(
                'Medium',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.warning,
                ),
              ),
              Text(
                'High',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
