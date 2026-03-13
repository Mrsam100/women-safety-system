// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SafeRide';

  @override
  String get enterPhone => 'Enter your phone number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get enterOtp => 'Enter verification code';

  @override
  String get verifyOtp => 'Verify';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get setupProfile => 'Set up your profile';

  @override
  String get fullName => 'Full Name';

  @override
  String get bloodGroup => 'Blood Group';

  @override
  String get medicalNotes => 'Medical Notes (optional)';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get addContact => 'Add Contact';

  @override
  String get removeContact => 'Remove';

  @override
  String get panicButton => 'PANIC';

  @override
  String get holdToActivate => 'Hold for 3 seconds to activate';

  @override
  String get alertTriggered => 'Emergency alert triggered!';

  @override
  String get fakeCall => 'Fake Call';

  @override
  String get startRide => 'Start Ride';

  @override
  String get endRide => 'End Ride';

  @override
  String get rideActive => 'Ride Active';

  @override
  String get rideHistory => 'Ride History';

  @override
  String get settings => 'Settings';

  @override
  String get safeStatus => 'Safe';

  @override
  String get cautionStatus => 'Caution';

  @override
  String get alertStatus => 'Alert';

  @override
  String get emergencyStatus => 'Emergency';

  @override
  String get genericError => 'Something went wrong';

  @override
  String get networkError => 'No internet connection';
}
