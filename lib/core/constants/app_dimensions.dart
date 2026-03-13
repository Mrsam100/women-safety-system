abstract final class AppDimensions {
  // Padding
  static const paddingXS = 4.0;
  static const paddingSM = 8.0;
  static const paddingMD = 16.0;
  static const paddingLG = 24.0;
  static const paddingXL = 32.0;
  static const paddingXXL = 48.0;

  // Border Radius
  static const radiusSM = 4.0;
  static const radiusMD = 8.0;
  static const radiusLG = 16.0;
  static const radiusXL = 24.0;
  static const radiusRound = 999.0;

  // Icon Sizes
  static const iconSM = 16.0;
  static const iconMD = 24.0;
  static const iconLG = 32.0;
  static const iconXL = 48.0;

  // Panic Button
  static const panicButtonSize = 120.0;
  static const panicButtonBorderWidth = 4.0;
  static const panicLongPressDuration = 3; // seconds

  // Map
  static const defaultZoom = 15.0;
  static const locationUpdateInterval = 10; // seconds
  static const batchUploadInterval = 60; // seconds
  static const routeCheckInterval = 30; // seconds
  static const deviationThresholdKm = 1.5;
  static const deviationTimeLimitMin = 2;
  static const speedThresholdKmh = 100.0;

  // Audio
  static const audioBufferSeconds = 30;
  static const audioChunkSeconds = 3;

  // Shake Detection
  static const shakeThreshold = 15.0; // m/s²
  static const shakeCount = 3;
  static const shakeWindowMs = 2000;

  // OTP
  static const otpLength = 6;
  static const otpResendSeconds = 60;

  // Contacts
  static const minContacts = 3;
  static const maxContacts = 5;

  // Threat Score
  static const greenMax = 30;
  static const yellowMax = 60;
  static const orangeMax = 80;
  static const redMin = 81;
  static const safetyPromptTimeout = 60; // seconds

  // Data Retention
  static const dataRetentionDays = 30;

  // Battery
  static const lowBatteryThreshold = 10; // percent
}
