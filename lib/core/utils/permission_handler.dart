import 'package:permission_handler/permission_handler.dart';

abstract final class AppPermissionHandler {
  static Future<bool> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      await Permission.locationAlways.request();
      return true;
    }
    return false;
  }

  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestContacts() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestNotification() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestPhone() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  static Future<bool> requestSms() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<bool> requestSensors() async {
    final status = await Permission.sensors.request();
    return status.isGranted;
  }

  static Future<Map<Permission, PermissionStatus>>
      requestAllRequired() async {
    return await [
      Permission.locationWhenInUse,
      Permission.microphone,
      Permission.notification,
      Permission.phone,
      Permission.sms,
      Permission.sensors,
    ].request();
  }

  static Future<bool> isLocationGranted() async {
    return await Permission.locationWhenInUse.isGranted;
  }

  static Future<bool> isMicrophoneGranted() async {
    return await Permission.microphone.isGranted;
  }

  static Future<bool> openAppSettingsPage() async {
    return await openAppSettings();
  }
}
