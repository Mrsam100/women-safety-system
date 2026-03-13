import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/features/ride/domain/entities/ride.dart';
import 'package:saferide/features/ride/domain/entities/route_point.dart';
import 'package:saferide/features/ride/presentation/providers/ride_provider.dart';

/// Displays a post-ride summary with a static map of
/// the route, timeline of events, and safety score.
class RideSummaryScreen extends ConsumerStatefulWidget {
  final String userId;
  final String rideId;

  const RideSummaryScreen({
    super.key,
    required this.userId,
    required this.rideId,
  });

  @override
  ConsumerState<RideSummaryScreen> createState() =>
      _RideSummaryScreenState();
}

class _RideSummaryScreenState
    extends ConsumerState<RideSummaryScreen> {
  Ride? _ride;
  List<RoutePoint> _routePoints = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRideData();
  }

  Future<void> _loadRideData() async {
    final repo = ref.read(rideRepositoryProvider);

    final rideResult = await repo.getRide(
      userId: widget.userId,
      rideId: widget.rideId,
    );

    rideResult.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
      },
      (ride) async {
        final pointsResult = await repo.getRoutePoints(
          userId: widget.userId,
          rideId: widget.rideId,
        );

        pointsResult.fold(
          (failure) {
            setState(() {
              _ride = ride;
              _error = failure.message;
              _isLoading = false;
            });
          },
          (points) {
            setState(() {
              _ride = ride;
              _routePoints = points;
              _isLoading = false;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Summary'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null && _ride == null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final ride = _ride!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // Route map
          SizedBox(
            height: 280,
            child: _buildSummaryMap(ride),
          ),

          // Safety score card
          Padding(
            padding: const EdgeInsets.all(
              AppDimensions.paddingMD,
            ),
            child: _SafetyScoreCard(
              score: ride.safetyScore,
            ),
          ),

          // Ride details
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMD,
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusMD,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(
                  AppDimensions.paddingMD,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Details',
                      style:
                          theme.textTheme.titleMedium
                              ?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: AppDimensions.paddingMD,
                    ),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: 'Started',
                      value: _formatDateTime(
                        ride.startedAt,
                      ),
                    ),
                    if (ride.endedAt != null)
                      _DetailRow(
                        icon:
                            Icons.access_time_filled,
                        label: 'Ended',
                        value: _formatDateTime(
                          ride.endedAt!,
                        ),
                      ),
                    if (ride.durationMinutes != null)
                      _DetailRow(
                        icon: Icons.timer_outlined,
                        label: 'Duration',
                        value: _formatDuration(
                          ride.durationMinutes!,
                        ),
                      ),
                    if (ride.distanceKm != null)
                      _DetailRow(
                        icon: Icons.straighten,
                        label: 'Distance',
                        value:
                            '${ride.distanceKm!.toStringAsFixed(1)} km',
                      ),
                    _DetailRow(
                      icon: Icons.shield_outlined,
                      label: 'Status',
                      value: ride.status.name
                          .toUpperCase(),
                    ),
                    _DetailRow(
                      icon: Icons.location_on,
                      label: 'GPS Points',
                      value:
                          '${_routePoints.length}',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Timeline of events
          if (ride.alertsTriggered > 0)
            Padding(
              padding: const EdgeInsets.all(
                AppDimensions.paddingMD,
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMD,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    AppDimensions.paddingMD,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Events',
                        style: theme
                            .textTheme.titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height:
                            AppDimensions.paddingSM,
                      ),
                      _EventTile(
                        icon:
                            Icons.warning_amber_rounded,
                        color: AppColors.danger,
                        title:
                            '${ride.alertsTriggered} '
                            'alert(s) triggered',
                        subtitle:
                            'During this ride',
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Route addresses
          if (ride.startAddress != null ||
              ride.endAddress != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMD,
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMD,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    AppDimensions.paddingMD,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route',
                        style: theme
                            .textTheme.titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height:
                            AppDimensions.paddingSM,
                      ),
                      if (ride.startAddress != null)
                        _DetailRow(
                          icon: Icons.trip_origin,
                          label: 'From',
                          value: ride.startAddress!,
                        ),
                      if (ride.endAddress != null)
                        _DetailRow(
                          icon: Icons.flag,
                          label: 'To',
                          value: ride.endAddress!,
                        ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(
            height: AppDimensions.paddingXL,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMap(Ride ride) {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // Start marker
    markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(
          ride.startLatitude,
          ride.startLongitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
        infoWindow: const InfoWindow(title: 'Start'),
      ),
    );

    // End marker
    if (ride.endLatitude != null &&
        ride.endLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(
            ride.endLatitude!,
            ride.endLongitude!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(
            title: 'Destination',
          ),
        ),
      );
    }

    // Expected route
    if (ride.expectedRoute.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId(
            'summary_expected',
          ),
          points: ride.expectedRoute
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

    // Actual route
    if (_routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId(
            'summary_actual',
          ),
          points: _routePoints
              .map(
                (p) =>
                    LatLng(p.latitude, p.longitude),
              )
              .toList(),
          color: ride.status == RideStatus.emergency
              ? AppColors.routeDeviated
              : AppColors.routeActual,
          width: 5,
        ),
      );
    }

    // Determine camera bounds
    final target = LatLng(
      ride.startLatitude,
      ride.startLongitude,
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: target,
        zoom: 13,
      ),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      liteModeEnabled: true,
    );
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }
}

class _SafetyScoreCard extends StatelessWidget {
  final double score;

  const _SafetyScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final safetyPercent =
        ((100 - score) / 100).clamp(0.0, 1.0);
    final color = score <= AppDimensions.greenMax
        ? AppColors.safe
        : score <= AppDimensions.yellowMax
            ? AppColors.warning
            : AppColors.danger;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusMD,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          AppDimensions.paddingLG,
        ),
        child: Column(
          children: [
            Text(
              'Safety Score',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: AppDimensions.paddingMD,
            ),
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: safetyPercent,
                      strokeWidth: 8,
                      backgroundColor: AppColors.divider,
                      valueColor:
                          AlwaysStoppedAnimation(color),
                    ),
                  ),
                  Text(
                    '${(safetyPercent * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: AppDimensions.paddingSM,
            ),
            Text(
              score <= AppDimensions.greenMax
                  ? 'Safe ride'
                  : score <= AppDimensions.yellowMax
                      ? 'Some concerns'
                      : 'Unsafe ride',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.paddingSM,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconSM,
            color: AppColors.textSecondary,
          ),
          const SizedBox(
            width: AppDimensions.paddingSM,
          ),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _EventTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(
            AppDimensions.paddingSM,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(
          width: AppDimensions.paddingMD,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
