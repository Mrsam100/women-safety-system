import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// SMS Functions (Twilio)
export {
  onAlertCreated,
  sendSmsCallable,
} from "./sms/sendSms";

// Push Notification Functions (FCM)
export {
  onAlertCreatedPush,
  sendPushCallable,
} from "./notifications/pushNotification";

// Auto-Escalation Functions
export {
  monitorLiveTracking,
  checkStaleTracking,
} from "./escalation/autoEscalate";

// Data Retention Functions
export {
  deleteExpiredEvidence,
} from "./dataRetention";

// User Data Functions (GDPR)
export {
  exportUserData,
  deleteUserData,
} from "./userData";
