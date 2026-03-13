import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/features/safety/presentation/providers/panic_provider.dart';

/// Large red circular panic button (120x120).
///
/// Requires a 3-second long press to activate.
/// Shows a countdown animation during the hold and a
/// pulsing ripple effect when in idle state.
class PanicButton extends ConsumerStatefulWidget {
  /// Called after the 3-second hold completes.
  final VoidCallback onActivated;

  const PanicButton({
    super.key,
    required this.onActivated,
  });

  @override
  ConsumerState<PanicButton> createState() =>
      _PanicButtonState();
}

class _PanicButtonState extends ConsumerState<PanicButton>
    with TickerProviderStateMixin {
  // Countdown progress (0.0 → 1.0 over 3 seconds)
  late final AnimationController _holdController;
  late final Animation<double> _holdAnimation;

  // Pulse / ripple effect
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  Timer? _countdownTimer;
  int _countdownSeconds = AppDimensions.panicLongPressDuration;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();

    _holdController = AnimationController(
      vsync: this,
      duration: Duration(
        seconds: AppDimensions.panicLongPressDuration,
      ),
    );
    _holdAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(
      CurvedAnimation(
        parent: _holdController,
        curve: Curves.linear,
      ),
    );
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onHoldComplete();
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _onHoldStart() {
    setState(() {
      _isHolding = true;
      _countdownSeconds =
          AppDimensions.panicLongPressDuration;
    });

    _holdController.forward(from: 0.0);
    _pulseController.stop();

    HapticFeedback.heavyImpact();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          _countdownSeconds--;
        });
        HapticFeedback.mediumImpact();
        if (_countdownSeconds <= 0) {
          timer.cancel();
        }
      },
    );
  }

  void _onHoldCancel() {
    setState(() => _isHolding = false);
    _holdController.reset();
    _countdownTimer?.cancel();
    _countdownSeconds =
        AppDimensions.panicLongPressDuration;

    if (mounted) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _onHoldComplete() {
    HapticFeedback.vibrate();
    setState(() => _isHolding = false);
    _countdownTimer?.cancel();

    widget.onActivated();
  }

  @override
  void dispose() {
    _holdController.dispose();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panicState = ref.watch(panicNotifierProvider);
    final isDisabled = panicState.isPanicking;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            _holdAnimation,
            _pulseAnimation,
          ]),
          builder: (context, child) {
            final scale = _isHolding
                ? 1.0
                : _pulseAnimation.value;

            return Transform.scale(
              scale: scale,
              child: _buildButton(isDisabled),
            );
          },
        ),
        const SizedBox(height: AppDimensions.paddingSM),
        Text(
          _isHolding
              ? '$_countdownSeconds'
              : AppStrings.holdToActivate,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
                color: _isHolding
                    ? AppColors.danger
                    : AppColors.textSecondary,
                fontWeight: _isHolding
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Widget _buildButton(bool isDisabled) {
    return GestureDetector(
      onLongPressStart:
          isDisabled ? null : (_) => _onHoldStart(),
      onLongPressEnd:
          isDisabled ? null : (_) => _onHoldCancel(),
      onLongPressCancel:
          isDisabled ? null : _onHoldCancel,
      child: SizedBox(
        width: AppDimensions.panicButtonSize,
        height: AppDimensions.panicButtonSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: AppDimensions.panicButtonSize,
              height: AppDimensions.panicButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDisabled
                    ? AppColors.disabled
                    : AppColors.danger,
                border: Border.all(
                  color: isDisabled
                      ? AppColors.disabled
                      : AppColors.dangerDark,
                  width:
                      AppDimensions.panicButtonBorderWidth,
                ),
                boxShadow: isDisabled
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.danger
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
              ),
            ),

            // Progress indicator overlay (countdown)
            if (_isHolding)
              SizedBox(
                width: AppDimensions.panicButtonSize,
                height: AppDimensions.panicButtonSize,
                child: CircularProgressIndicator(
                  value: _holdAnimation.value,
                  strokeWidth: 6,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.3),
                ),
              ),

            // Panic text
            Text(
              _isHolding
                  ? '$_countdownSeconds'
                  : AppStrings.panicButton,
              style: const TextStyle(
                color: AppColors.textOnDanger,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
