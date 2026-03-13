import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:saferide/features/safety/domain/entities/alert.dart';

/// Animated banner that slides down from the top of
/// the screen showing alert type, severity, and a
/// dismiss action.
///
/// Usage:
/// ```dart
/// AlertBanner(
///   alert: activeAlert,
///   onDismiss: () => notifier.dismissAlert(id),
/// )
/// ```
class AlertBanner extends StatefulWidget {
  final ActiveAlert alert;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const AlertBanner({
    super.key,
    required this.alert,
    this.onDismiss,
    this.onTap,
  });

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMD,
              vertical: AppDimensions.paddingSM,
            ),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(
                AppDimensions.radiusLG,
              ),
              color: _bannerColor,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusLG,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    AppDimensions.paddingMD,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _alertIcon,
                        color: Colors.white,
                        size: AppDimensions.iconLG,
                      ),
                      const SizedBox(
                        width: AppDimensions.paddingSM,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _alertTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.alert.message,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: AppDimensions.paddingSM,
                      ),
                      _SeverityBadge(
                        threatLevel:
                            widget.alert.threatLevel,
                      ),
                      if (widget.onDismiss != null) ...[
                        const SizedBox(
                          width: AppDimensions.paddingXS,
                        ),
                        IconButton(
                          onPressed: _dismiss,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: AppDimensions.iconMD,
                          ),
                          constraints:
                              const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _bannerColor {
    switch (widget.alert.threatLevel) {
      case AlertThreatLevel.low:
        return AppColors.warning;
      case AlertThreatLevel.medium:
        return AppColors.warningDark;
      case AlertThreatLevel.high:
        return AppColors.danger;
      case AlertThreatLevel.critical:
        return AppColors.dangerDark;
    }
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

  String get _alertTitle {
    switch (widget.alert.type) {
      case AlertType.routeDeviation:
        return 'Route Deviation';
      case AlertType.speedAnomaly:
        return 'Speed Anomaly';
      case AlertType.lowBattery:
        return 'Low Battery';
      default:
        return 'Safety Alert';
    }
  }
}

/// Small badge showing the threat level label.
class _SeverityBadge extends StatelessWidget {
  final AlertThreatLevel threatLevel;

  const _SeverityBadge({required this.threatLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSM,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusRound,
        ),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String get _label {
    switch (threatLevel) {
      case AlertThreatLevel.low:
        return 'LOW';
      case AlertThreatLevel.medium:
        return 'MEDIUM';
      case AlertThreatLevel.high:
        return 'HIGH';
      case AlertThreatLevel.critical:
        return 'CRITICAL';
    }
  }
}
