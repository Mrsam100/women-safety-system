import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/features/ride/presentation/providers/map_provider.dart';
import 'package:saferide/features/ride/presentation/providers/ride_provider.dart';

/// Google Maps widget that displays the rider's live
/// location, the expected route (blue dashed line),
/// and the actual route (green, turning red on
/// deviation).
class RideMap extends ConsumerStatefulWidget {
  /// When true, the camera follows the rider's live
  /// position automatically.
  final bool followUser;

  const RideMap({
    super.key,
    this.followUser = true,
  });

  @override
  ConsumerState<RideMap> createState() => _RideMapState();
}

class _RideMapState extends ConsumerState<RideMap> {
  @override
  void initState() {
    super.initState();
    _syncOverlays();
  }

  void _syncOverlays() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideState = ref.read(rideNotifierProvider);
      final mapNotifier = ref.read(
        mapNotifierProvider.notifier,
      );
      final ride = rideState.currentRide;

      if (ride == null) return;

      // Set expected route
      if (ride.expectedRoute.isNotEmpty) {
        mapNotifier.setExpectedRoute(
          ride.expectedRoute,
        );
      }

      // Set destination markers
      mapNotifier.setDestinationMarkers(
        startLat: ride.startLatitude,
        startLon: ride.startLongitude,
        endLat: ride.endLatitude,
        endLon: ride.endLongitude,
      );

      // Draw actual route
      if (rideState.routePoints.isNotEmpty) {
        mapNotifier.setActualRoute(
          rideState.routePoints,
          deviationKm: rideState.deviationKm,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapNotifierProvider);
    final rideState = ref.watch(rideNotifierProvider);

    // Update actual route polyline reactively
    ref.listen<RideState>(
      rideNotifierProvider,
      (previous, next) {
        final mapNotifier = ref.read(
          mapNotifierProvider.notifier,
        );

        // Update actual route
        if (next.routePoints.isNotEmpty) {
          mapNotifier.setActualRoute(
            next.routePoints,
            deviationKm: next.deviationKm,
          );
        }

        // Update rider marker
        if (next.routePoints.isNotEmpty) {
          final latest = next.routePoints.last;
          mapNotifier.updateRiderMarker(
            latitude: latest.latitude,
            longitude: latest.longitude,
          );

          // Follow user
          if (widget.followUser) {
            mapNotifier.animateToPosition(
              LatLng(
                latest.latitude,
                latest.longitude,
              ),
            );
          }
        }
      },
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        AppDimensions.radiusLG,
      ),
      child: GoogleMap(
        initialCameraPosition:
            mapState.cameraPosition,
        markers: mapState.markers,
        polylines: mapState.polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: true,
        onMapCreated: (controller) {
          ref
              .read(mapNotifierProvider.notifier)
              .onMapCreated(controller);
        },
      ),
    );
  }
}
