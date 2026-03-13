import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:saferide/core/utils/logger.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<Position>.broadcast();

  Stream<Position> get locationStream => _locationController.stream;

  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  Future<void> initialize() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }
  }

  Future<Position> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    _lastPosition = position;
    return position;
  }

  void startTracking({
    int intervalMs = 10000,
    double distanceFilter = 5,
  }) {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (position) {
        _lastPosition = position;
        _locationController.add(position);
      },
      onError: (error) {
        AppLogger.error(
          'Location tracking error',
          error: error,
          tag: 'LocationService',
        );
      },
    );
    AppLogger.info(
      'Location tracking started',
      tag: 'LocationService',
    );
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    AppLogger.info(
      'Location tracking stopped',
      tag: 'LocationService',
    );
  }

  Future<void> dispose() async {
    stopTracking();
    await _locationController.close();
  }
}
