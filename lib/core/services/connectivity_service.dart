import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:saferide/core/utils/logger.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _statusController =
      StreamController<bool>.broadcast();
  bool _isOnline = true;

  Stream<bool> get onConnectivityChanged =>
      _statusController.stream;

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);

    _subscription =
        _connectivity.onConnectivityChanged.listen(
      (results) {
        final online =
            !results.contains(ConnectivityResult.none);
        if (online != _isOnline) {
          _isOnline = online;
          _statusController.add(_isOnline);
          AppLogger.info(
            'Connectivity: ${_isOnline ? "online" : "offline"}',
            tag: 'ConnectivityService',
          );
        }
      },
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _statusController.close();
  }
}
