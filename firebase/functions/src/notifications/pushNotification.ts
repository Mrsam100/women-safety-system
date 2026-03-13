import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Send push notification to all emergency contacts
 * who have the app installed (have FCM tokens).
 */
export const onAlertCreatedPush = functions.firestore
  .document("users/{userId}/rides/{rideId}/alerts/{alertId}")
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const alertData = snap.data();

    if (!alertData) return;

    const db = admin.firestore();

    // Get user profile
    const userDoc = await db
      .collection("users")
      .doc(userId)
      .get();

    if (!userDoc.exists) return;
    const user = userDoc.data()!;
    const userName = user.displayName || "SafeRide User";

    // Get emergency contacts with FCM tokens
    const contactsSnap = await db
      .collection("users")
      .doc(userId)
      .collection("emergencyContacts")
      .where("hasApp", "==", true)
      .get();

    const tokens: string[] = [];
    contactsSnap.docs.forEach((doc) => {
      const contact = doc.data();
      if (contact.fcmToken) {
        tokens.push(contact.fcmToken);
      }
    });

    if (tokens.length === 0) return;

    // Build notification
    const location = alertData.location;
    const lat = location?.latitude || 0;
    const lng = location?.longitude || 0;

    const severityMap: Record<string, string> = {
      low: "Low",
      medium: "Medium",
      high: "High",
      critical: "CRITICAL",
    };

    const severity =
      severityMap[alertData.severity] || "Unknown";

    const notification: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title: `EMERGENCY: ${userName}`,
        body: `${severity} alert triggered. Tap for live location.`,
      },
      data: {
        type: "emergency_alert",
        userId,
        rideId: context.params.rideId,
        alertId: context.params.alertId,
        alertType: alertData.type || "",
        severity: alertData.severity || "",
        latitude: lat.toString(),
        longitude: lng.toString(),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "emergency_channel",
          priority: "max",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: `EMERGENCY: ${userName}`,
              body: `${severity} alert triggered.`,
            },
            sound: "default",
            badge: 1,
            "content-available": 1,
            "interruption-level": "critical",
          },
        },
      },
    };

    try {
      const response = await admin
        .messaging()
        .sendEachForMulticast(notification);

      console.log(
        `Push sent: ${response.successCount} success, ` +
          `${response.failureCount} failed`
      );

      // Clean up invalid tokens
      response.responses.forEach((resp, idx) => {
        if (resp.error) {
          const errorCode = resp.error.code;
          if (
            errorCode ===
              "messaging/invalid-registration-token" ||
            errorCode ===
              "messaging/registration-token-not-registered"
          ) {
            console.log(
              `Removing invalid token: ${tokens[idx]}`
            );
          }
        }
      });
    } catch (error) {
      console.error("Push notification error:", error);
    }
  });

/**
 * Callable function to send a push notification.
 */
export const sendPushCallable = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }

    const { token, title, body, data: payload } = data;

    if (!token || !title) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "token and title required"
      );
    }

    await admin.messaging().send({
      token,
      notification: { title, body },
      data: payload || {},
    });

    return { success: true };
  }
);
