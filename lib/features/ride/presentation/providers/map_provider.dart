import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/features/ride/domain/entities/ride.dart';
import 'package:saferide/features/ride/domain/entities/route_point.dart';
import 'package:saferide/features/ride/presentation/providers/ride_provider.dart';

// ── Map state ──

class MapState {
  final CameraPosition cameraPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const MapState({
    required this.cameraPosition,
    this.markers = const {},
    this.polylines = const {},
  });

  MapState copyWith({
    CameraPosition? cameraPosition,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
  }) {
    return MapState(
      cameraPosition:
          cameraPosition ?? this.cameraPosition,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  GoogleMapController? _mapController;

  MapNotifier()
      : super(
          const MapState(
            cameraPosition: CameraPosition(
              target: LatLng(28.6139, 77.2090),
              zoom: AppDimensions.defaultZoom,
            ),
          ),
        );

  /// Store the map controller for camera animations.
  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Move the camera to a specific position.
  Future<void> animateToPosition(LatLng target) async {
    final newPosition = CameraPosition(
      target: target,
      zoom: AppDimensions.defaultZoom,
    );
    state = state.copyWith(
      cameraPosition: newPosition,
    );
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(newPosition),
    );
  }

  /// Update the rider's live marker on the map.
  void updateRiderMarker({
    required double latitude,
    required double longitude,
  }) {
    final riderMarker = Marker(
      markerId: const MarkerId('rider'),
      position: LatLng(latitude, longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueViolet,
      ),
      infoWindow: const InfoWindow(
        title: 'Your Location',
      ),
    );

    final updatedMarkers = {
      ...state.markers
          .where((m) => m.markerId.value != 'rider'),
      riderMarker,
    };

    state = state.copyWith(markers: updatedMarkers);
  }

  /// Set start and end destination markers.
  void setDestinationMarkers({
    required double startLat,
    required double startLon,
    double? endLat,
    double? endLon,
  }) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(startLat, startLon),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
        infoWindow: const InfoWindow(title: 'Start'),
      ),
    };

    if (endLat != null && endLon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(endLat, endLon),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(
            title: 'Destination',
          ),
        ),
      );
    }

    state = state.copyWith(
      markers: {
        ...state.markers.where(
          (m) =>
              m.markerId.value != 'start' &&
              m.markerId.value != 'destination',
        ),
        ...markers,
      },
    );
  }

  /// Draw the expected route polyline (blue).
  void setExpectedRoute(
    List<({double lat, double lon})> routePoints,
  ) {
    if (routePoints.isEmpty) return;

    final polyline = Polyline(
      polylineId: const PolylineId('expected_route'),
      points: routePoints
          .map((p) => LatLng(p.lat, p.lon))
          .toList(),
      color: AppColors.routeExpected,
      width: 4,
      patterns: [
        PatternItem.dash(20),
        PatternItem.gap(10),
      ],
    );

    state = state.copyWith(
      polylines: {
        ...state.polylines.where(
          (p) =>
              p.polylineId.value != 'expected_route',
        ),
        polyline,
      },
    );
  }

  /// Draw the actual route polyline. Changes from
  /// green to red when deviation exceeds the threshold.
  void setActualRoute(
    List<RoutePoint> routePoints, {
    double deviationKm = 0.0,
  }) {
    if (routePoints.isEmpty) return;

    final isDeviated = deviationKm >
        AppDimensions.deviationThresholdKm;

    final polyline = Polyline(
      polylineId: const PolylineId('actual_route'),
      points: routePoints
          .map(
            (p) => LatLng(p.latitude, p.longitude),
          )
          .toList(),
      color: isDeviated
          ? AppColors.routeDeviated
          : AppColors.routeActual,
      width: 5,
    );

    state = state.copyWith(
      polylines: {
        ...state.polylines.where(
          (p) => p.polylineId.value != 'actual_route',
        ),
        polyline,
      },
    );
  }

  /// Clear all map overlays.
  void clearOverlays() {
    state = state.copyWith(
      markers: const {},
      polylines: const {},
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

final mapNotifierProvider =
    StateNotifierProvider<MapNotifier, MapState>(
  (ref) => MapNotifier(),
);
