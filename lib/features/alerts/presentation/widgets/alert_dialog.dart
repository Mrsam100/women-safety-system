import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:saferide/features/safety/domain/entities/alert.dart';

/// Modal dialog that prompts the user with "Are you
/// safe?" and includes a countdown timer (default 60s).
///
/// - Pressing "Yes, I'm safe" dismisses the dialog.
/// - Pressing "No, send help" immediately escalates.
/// - If the timer reaches zero, the dialog auto-
///   escalates to the panic sequence.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   builder: (_) => SafetyAlertDialog(
///     alert: activeAlert,
///     countdownSeconds: 60,
///     onConfirmSafe: () => notifier.confirmSafe(),
///     onEscalate: () => panicNotifier.triggerPanic(...),
///   ),
/// );
/// ```
class SafetyAlertDialog extends StatefulWidget {
  final ActiveAlert alert;
  final int countdownSeconds;
  final VoidCallback onConfirmSafe;
  final VoidCallback onEscalate;

  const SafetyAlertDialog({
    super.key,
    required this.alert,
    this.countdownSeconds =
        AppDimensions.safetyPromptTimeout,
    required this.onConfirmSafe,
    required this.onEscalate,
  });

  @override
  State<SafetyAlertDialog> createState() =>
      _SafetyAlertDialogState();
}

class _SafetyAlertDialogState
    extends State<SafetyAlertDialog>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remaining = widget.countdownSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _remaining--;
        });

        if (_remaining <= 0) {
          timer.cancel();
          _handleTimeout();
        }
      },
    );
  }

  void _handleTimeout() {
    if (mounted) {
      Navigator.of(context).pop();
    }
    widget.onEscalate();
  }

  void _handleConfirmSafe() {
    _timer?.cancel();
    Navigator.of(context).pop();
    widget.onConfirmSafe();
  }

  void _handleEscalate() {
    _timer?.cancel();
    Navigator.of(context).pop();
    widget.onEscalate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _remaining / widget.countdownSeconds;
    final isUrgent = _remaining <= 15;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusXL,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            AppDimensions.paddingLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Alert icon with countdown ring ──
              ScaleTransition(
                scale: isUrgent
                    ? _pulseAnimation
                    : const AlwaysStoppedAnimation(1.0),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child:
                            CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor:
                              AppColors.divider,
                          valueColor:
                              AlwaysStoppedAnimation(
                            isUrgent
                                ? AppColors.danger
                                : AppColors.warning,
                          ),
                        ),
                      ),
                      Icon(
                        _alertIcon,
                        size: AppDimensions.iconXL,
                        color: isUrgent
                            ? AppColors.danger
                            : AppColors.warning,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: AppDimensions.paddingMD,
              ),

              // ── Title ──
              const Text(
                'Are you safe?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(
                height: AppDimensions.paddingSM,
              ),

              // ── Alert message ──
              Text(
                widget.alert.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(
                height: AppDimensions.paddingMD,
              ),

              // ── Countdown ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMD,
                  vertical: AppDimensions.paddingSM,
                ),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? AppColors.danger
                          .withValues(alpha: 0.1)
                      : AppColors.warning
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMD,
                  ),
                ),
                child: Text(
                  _formatCountdown(_remaining),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isUrgent
                        ? AppColors.danger
                        : AppColors.warningDark,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: AppDimensions.paddingSM,
              ),

              Text(
                isUrgent
                    ? 'Escalating to emergency soon!'
                    : 'Auto-escalation if no response',
                style: TextStyle(
                  fontSize: 12,
                  color: isUrgent
                      ? AppColors.danger
                      : AppColors.textSecondary,
                ),
              ),

              const SizedBox(
                height: AppDimensions.paddingLG,
              ),

              // ── Actions ──
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleConfirmSafe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safe,
                    foregroundColor:
                        AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        AppDimensions.radiusLG,
                      ),
                    ),
                  ),
                  child: const Text(
                    "Yes, I'm safe",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: AppDimensions.paddingSM,
              ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _handleEscalate,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(
                      color: AppColors.danger,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        AppDimensions.radiusLG,
                      ),
                    ),
                  ),
                  child: const Text(
                    'No, send help!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _alertIcon {
    switch (widget.alert.type) {
      case AlertType.routeDeviation:
        return Icons.alt_route;
      case AlertType.speedAnomaly:
        return Icons.speed;
      case AlertType.lowBattery:
        return Icons.battery_alert;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}
