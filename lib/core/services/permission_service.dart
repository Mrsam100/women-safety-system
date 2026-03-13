import 'package:permission_handler/permission_handler.dart';
import 'package:saferide/core/utils/logger.dart';

class PermissionService {
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location':
          await Permission.locationWhenInUse.isGranted,
      'locationAlways':
          await Permission.locationAlways.isGranted,
      'microphone': await Permission.microphone.isGranted,
      'notification':
          await Permission.notification.isGranted,
      'phone': await Permission.phone.isGranted,
      'sms': await Permission.sms.isGranted,
      'sensors': await Permission.sensors.isGranted,
      'contacts': await Permission.contacts.isGranted,
    };
  }

  Future<bool> requestPermission(Permission permission) async {
    final status = await permission.request();
    AppLogger.info(
      'Permission ${permission.toString()}: $status',
      tag: 'PermissionService',
    );
    return status.isGranted;
  }

  Future<bool> requestLocationPermissions() async {
    var status =
        await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      final always =
          await Permission.locationAlways.request();
      return always.isGranted || status.isGranted;
    }
    return false;
  }

  Future<bool> requestRidePermissions() async {
    final results = await [
      Permission.locationWhenInUse,
      Permission.microphone,
      Permission.sensors,
    ].request();

    return results.values.every(
      (status) => status.isGranted,
    );
  }

  Future<bool> isPermissionPermanentlyDenied(
    Permission permission,
  ) async {
    return await permission.isPermanentlyDenied;
  }
}
