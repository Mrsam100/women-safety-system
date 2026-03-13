abstract final class ApiConstants {
  // Firebase Collections
  static const usersCollection = 'users';
  static const emergencyContactsSubcollection = 'emergencyContacts';
  static const ridesSubcollection = 'rides';
  static const locationTrailSubcollection = 'locationTrail';
  static const alertsSubcollection = 'alerts';
  static const audioEvidenceSubcollection = 'audioEvidence';
  static const liveTrackingCollection = 'liveTracking';
  static const trackingTokensCollection = 'trackingTokens';
  static const areaDataCollection = 'areaData';

  // Cloud Storage Paths
  static const profilePhotosPath = 'profile_photos';
  static const audioEvidencePath = 'audio_evidence';

  // Cloud Functions
  static const sendSmsFunction = 'sendSms';
  static const pushNotificationFunction = 'pushNotification';
  static const autoEscalateFunction = 'autoEscalate';
  static const dataRetentionFunction = 'dataRetention';
  static const userDataExportFunction = 'userDataExport';
  static const userDataDeleteFunction = 'userDataDelete';

  // Tracking URL
  static const trackingBaseUrl = 'https://saferide.web.app/track';
}
