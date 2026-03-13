import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/services/audio_service.dart';
import 'package:saferide/core/services/battery_service.dart';
import 'package:saferide/core/services/connectivity_service.dart';
import 'package:saferide/core/services/local_storage_service.dart';
import 'package:saferide/core/services/location_service.dart';
import 'package:saferide/core/services/notification_service.dart';
import 'package:saferide/core/services/permission_service.dart';
import 'package:saferide/core/services/shake_service.dart';
import 'package:saferide/core/services/offline_sync_service.dart';
import 'package:saferide/core/services/sms_service.dart';
import 'package:saferide/features/safety/data/datasources/safety_local_datasource.dart';
import 'package:saferide/features/safety/data/datasources/safety_remote_datasource.dart';
import 'package:saferide/core/providers/firebase_providers.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final audioServiceProvider = Provider<AudioService>(
  (ref) => AudioService(),
);

final shakeServiceProvider = Provider<ShakeService>(
  (ref) => ShakeService(),
);

final smsServiceProvider = Provider<SmsService>(
  (ref) => SmsService(),
);

final batteryServiceProvider = Provider<BatteryService>(
  (ref) => BatteryService(),
);

final connectivityServiceProvider =
    Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final notificationServiceProvider =
    Provider<NotificationService>(
  (ref) => NotificationService(),
);

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(),
);

final localStorageServiceProvider =
    Provider<LocalStorageService>(
  (ref) => LocalStorageService(),
);

final offlineSyncServiceProvider =
    Provider<OfflineSyncService>((ref) {
  final service = OfflineSyncService(
    connectivity: ref.watch(connectivityServiceProvider),
    remoteDatasource: SafetyRemoteDatasource(
      firestore: ref.watch(firestoreProvider),
    ),
    localDatasource: SafetyLocalDatasource(
      localStorage: ref.watch(localStorageServiceProvider),
    ),
    smsService: ref.watch(smsServiceProvider),
  );
  service.startListening();
  ref.onDispose(() => service.dispose());
  return service;
});
