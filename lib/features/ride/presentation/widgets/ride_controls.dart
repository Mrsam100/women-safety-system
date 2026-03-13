import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/widgets/app_button.dart';
import 'package:saferide/core/widgets/app_text_field.dart';
import 'package:saferide/features/ride/presentation/providers/ride_provider.dart';

/// Start / end ride toggle with an optional destination
/// input field. When a ride is active the button
/// changes to "End Ride" with a red colour.
class RideControls extends ConsumerStatefulWidget {
  /// The current user's ID.
  final String userId;

  /// Called after a ride is successfully started.
  final VoidCallback? onRideStarted;

  /// Called after a ride is successfully ended.
  final VoidCallback? onRideEnded;

  const RideControls({
    super.key,
    required this.userId,
    this.onRideStarted,
    this.onRideEnded,
  });

  @override
  ConsumerState<RideControls> createState() =>
      _RideControlsState();
}

class _RideControlsState
    extends ConsumerState<RideControls> {
  final _destinationController = TextEditingController();
  bool _showDestination = false;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _handleStartRide() async {
    await ref.read(rideNotifierProvider.notifier).startRide(
      userId: widget.userId,
      endAddress: _destinationController.text.isNotEmpty
          ? _destinationController.text
          : null,
    );

    final state = ref.read(rideNotifierProvider);
    if (state.isActive) {
      widget.onRideStarted?.call();
    }
  }

  Future<void> _handleEndRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Ride'),
        content: const Text(
          'Are you sure you want to end this ride?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text(
              'End Ride',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(rideNotifierProvider.notifier)
        .endRide(userId: widget.userId);

    widget.onRideEnded?.call();
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideNotifierProvider);
    final isLoading =
        rideState.status == RideLifecycleStatus.starting ||
            rideState.status ==
                RideLifecycleStatus.ending;
    final isActive = rideState.isActive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Destination input (only before ride starts)
        if (!isActive) ...[
          GestureDetector(
            onTap: () => setState(
              () => _showDestination = !_showDestination,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  _showDestination
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: AppDimensions.iconMD,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(
                  width: AppDimensions.paddingXS,
                ),
                Text(
                  AppStrings.enterDestination,
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
          if (_showDestination)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMD,
                vertical: AppDimensions.paddingSM,
              ),
              child: AppTextField(
                controller: _destinationController,
                hint: AppStrings.enterDestination,
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                ),
              ),
            ),
          const SizedBox(
            height: AppDimensions.paddingSM,
          ),
        ],

        // Start / End button
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMD,
          ),
          child: AppButton(
            text: isActive
                ? AppStrings.endRide
                : AppStrings.startRide,
            onPressed: isLoading
                ? null
                : isActive
                    ? _handleEndRide
                    : _handleStartRide,
            isLoading: isLoading,
            backgroundColor: isActive
                ? AppColors.danger
                : AppColors.safe,
            textColor: AppColors.textOnPrimary,
            icon: isActive
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outline,
          ),
        ),

        // Error message
        if (rideState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppDimensions.paddingSM,
              left: AppDimensions.paddingMD,
              right: AppDimensions.paddingMD,
            ),
            child: Text(
              rideState.errorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
