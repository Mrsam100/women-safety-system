import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/features/ride/domain/entities/route_point.dart';

/// Utility widget that renders polyline overlays on a
/// Google Map. Supports expected route (blue, dashed),
/// actual route (green/red), and deviation highlights.
///
/// This is a headless widget — it does not render any
/// visible UI by itself. Instead, it computes a set of
/// [Polyline]s that can be passed to a [GoogleMap].
class RouteOverlay extends StatelessWidget {
  /// The expected route coordinates (blue, dashed).
  final List<({double lat, double lon})> expectedRoute;

  /// Actual GPS route points from tracking.
  final List<RoutePoint> actualRoute;

  /// Current route deviation distance (km).
  final double deviationKm;

  /// Callback that receives the computed polylines.
  final ValueChanged<Set<Polyline>> onPolylinesUpdated;

  const RouteOverlay({
    super.key,
    this.expectedRoute = const [],
    this.actualRoute = const [],
    this.deviationKm = 0.0,
    required this.onPolylinesUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final polylines = <Polyline>{};

    // Expected route — blue dashed
    if (expectedRoute.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId(
            'overlay_expected',
          ),
          points: expectedRoute
              .map((p) => LatLng(p.lat, p.lon))
              .toList(),
          color: AppColors.routeExpected,
          width: 4,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(10),
          ],
        ),
      );
    }

    // Actual route — green or red on deviation
    if (actualRoute.isNotEmpty) {
      final isDeviated = deviationKm >
          AppDimensions.deviationThresholdKm;

      polylines.add(
        Polyline(
          polylineId: const PolylineId(
            'overlay_actual',
          ),
          points: actualRoute
              .map(
                (p) =>
                    LatLng(p.latitude, p.longitude),
              )
              .toList(),
          color: isDeviated
              ? AppColors.routeDeviated
              : AppColors.routeActual,
          width: 5,
        ),
      );

      // If deviated, draw a highlight segment from
      // the last on-route point to the current
      // position.
      if (isDeviated && actualRoute.length >= 2) {
        final deviationSegment =
            _extractDeviationSegment();
        if (deviationSegment.isNotEmpty) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId(
                'overlay_deviation',
              ),
              points: deviationSegment,
              color: AppColors.routeDeviated
                  .withValues(alpha: 0.6),
              width: 8,
            ),
          );
        }
      }
    }

    // Notify parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onPolylinesUpdated(polylines);
    });

    return const SizedBox.shrink();
  }

  /// Extract the trailing segment where deviation
  /// started (simplified: last 10 points or all if
  /// fewer).
  List<LatLng> _extractDeviationSegment() {
    final count = actualRoute.length;
    final start = count > 10 ? count - 10 : 0;
    return actualRoute
        .sublist(start)
        .map(
          (p) => LatLng(p.latitude, p.longitude),
        )
        .toList();
  }
}
