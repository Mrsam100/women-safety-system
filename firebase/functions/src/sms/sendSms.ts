import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as twilio from "twilio";

const TWILIO_SID = functions.config().twilio?.sid || "";
const TWILIO_TOKEN = functions.config().twilio?.token || "";
const TWILIO_FROM = functions.config().twilio?.from || "";

/**
 * Triggered when a new alert is created.
 * Sends SMS to all emergency contacts with location link.
 */
export const onAlertCreated = functions.firestore
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

    // Get emergency contacts
    const contactsSnap = await db
      .collection("users")
      .doc(userId)
      .collection("emergencyContacts")
      .get();

    if (contactsSnap.empty) return;

    // Build SMS message
    const location = alertData.location;
    const lat = location?.latitude || 0;
    const lng = location?.longitude || 0;
    const mapLink = `https://maps.google.com/?q=${lat},${lng}`;

    let message = `EMERGENCY ALERT from ${userName}!\n`;
    message += `Type: ${alertData.type}\n`;
    message += `Location: ${mapLink}\n`;

    // Add tracking link if available
    const rideId = context.params.rideId;
    const tokenSnap = await db
      .collection("trackingTokens")
      .where("rideId", "==", rideId)
      .limit(1)
      .get();

    if (!tokenSnap.empty) {
      const token = tokenSnap.docs[0].id;
      message += `Live tracking: https://saferide.web.app/track?token=${token}\n`;
    }

    message += "Please call immediately!";

    // Send SMS via Twilio
    if (!TWILIO_SID || !TWILIO_TOKEN || !TWILIO_FROM) {
      console.warn("Twilio not configured, skipping SMS");
      return;
    }

    const client = twilio.default(TWILIO_SID, TWILIO_TOKEN);
    const promises = contactsSnap.docs.map((doc) => {
      const contact = doc.data();
      return client.messages
        .create({
          body: message,
          from: TWILIO_FROM,
          to: contact.phoneNumber,
        })
        .then(() => {
          console.log(`SMS sent to ${contact.phoneNumber}`);
        })
        .catch((err: Error) => {
          console.error(
            `Failed to send SMS to ${contact.phoneNumber}:`,
            err.message
          );
        });
    });

    await Promise.all(promises);

    // Update alert with notified contacts
    const notifiedNumbers = contactsSnap.docs.map(
      (doc) => doc.data().phoneNumber
    );

    await snap.ref.update({
      notifiedContacts: notifiedNumbers,
    });
  });

/**
 * HTTP callable function to send SMS on demand.
 */
export const sendSmsCallable = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }

    const { phoneNumber, message } = data;

    if (!phoneNumber || !message) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "phoneNumber and message required"
      );
    }

    if (!TWILIO_SID || !TWILIO_TOKEN || !TWILIO_FROM) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Twilio not configured"
      );
    }

    const client = twilio.default(TWILIO_SID, TWILIO_TOKEN);
    await client.messages.create({
      body: message,
      from: TWILIO_FROM,
      to: phoneNumber,
    });

    return { success: true };
  }
);
