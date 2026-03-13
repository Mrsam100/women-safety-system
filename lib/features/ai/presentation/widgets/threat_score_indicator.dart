import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/features/ai/domain/entities/threat_assessment.dart';
import 'package:saferide/features/ai/presentation/providers/ai_provider.dart';

/// Circular gauge widget that displays the current
/// threat score (0–100) with animated color transitions.
///
/// Color mapping:
///   Green  (0–30)  → [AppColors.safe]
///   Yellow (31–60) → [AppColors.warning]
///   Orange (61–80) → Orange shade
///   Red    (81–100)→ [AppColors.danger]
class ThreatScoreIndicator extends ConsumerWidget {
  /// Optional fixed size override. Defaults to 120.
  final double size;

  /// Optional stroke width for the arc. Defaults to 10.
  final double strokeWidth;

  /// Whether to show the text label below the score.
  final bool showLabel;

  const ThreatScoreIndicator({
    super.key,
    this.size = 120.0,
    this.strokeWidth = 10.0,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessment = ref.watch(
      currentThreatAssessmentProvider,
    );

    return _AnimatedThreatGauge(
      score: assessment.score,
      level: assessment.level,
      size: size,
      strokeWidth: strokeWidth,
      showLabel: showLabel,
    );
  }
}

/// Stateful widget that handles the score animation.
class _AnimatedThreatGauge extends StatefulWidget {
  final int score;
  final ThreatLevel level;
  final double size;
  final double strokeWidth;
  final bool showLabel;

  const _AnimatedThreatGauge({
    required this.score,
    required this.level,
    required this.size,
    required this.strokeWidth,
    required this.showLabel,
  });

  @override
  State<_AnimatedThreatGauge> createState() =>
      _AnimatedThreatGaugeState();
}

class _AnimatedThreatGaugeState
    extends State<_AnimatedThreatGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scoreAnimation;
  late Animation<Color?> _colorAnimation;

  int _previousScore = 0;
  Color _previousColor = AppColors.safe;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.score.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _colorAnimation = ColorTween(
      begin: AppColors.safe,
      end: _colorForLevel(widget.level),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedThreatGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score ||
        old.level != widget.level) {
      _previousScore = old.score;
      _previousColor = _colorForLevel(old.level);

      _scoreAnimation = Tween<double>(
        begin: _previousScore.toDouble(),
        end: widget.score.toDouble(),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );
      _colorAnimation = ColorTween(
        begin: _previousColor,
        end: _colorForLevel(widget.level),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorForLevel(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.green:
        return AppColors.safe;
      case ThreatLevel.yellow:
        return AppColors.warning;
      case ThreatLevel.orange:
        return const Color(0xFFFF9800);
      case ThreatLevel.red:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentScore =
            _scoreAnimation.value.round();
        final currentColor =
            _colorAnimation.value ?? AppColors.safe;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _GaugePainter(
                  score: _scoreAnimation.value,
                  color: currentColor,
                  strokeWidth: widget.strokeWidth,
                ),
                child: Center(
                  child: Text(
                    '$currentScore',
                    style: TextStyle(
                      fontSize: widget.size * 0.28,
                      fontWeight: FontWeight.bold,
                      color: currentColor,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(
                height: AppDimensions.paddingSM,
              ),
              Text(
                widget.level.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: currentColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Custom painter that draws the circular gauge arc.
class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final double strokeWidth;

  const _GaugePainter({
    required this.score,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );
    final radius =
        (math.min(size.width, size.height) / 2) -
            strokeWidth;

    // Background track
    final trackPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Score arc — sweeps from top (270 degrees)
    // clockwise. Full circle = score 100.
    final sweepAngle =
        (score / 100.0) * 2 * math.pi;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2, // start at top
      sweepAngle,
      false,
      arcPaint,
    );

    // Glow effect for high scores
    if (score > AppDimensions.orangeMax) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          4,
        );

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.score != score ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
