import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Server-side auto-escalation backup.
 * Monitors liveTracking documents for high threat scores
 * and triggers emergency protocol if the app goes offline.
 */
export const monitorLiveTracking = functions.firestore
  .document("liveTracking/{rideId}")
  .onUpdate(async (change, context) => {
    const { rideId } = context.params;
    const before = change.before.data();
    const after = change.after.data();

    if (!after) return;

    const threatScore = after.threatScore || 0;
    const isEmergency = after.isEmergency || false;
    const wasEmergency = before?.isEmergency || false;
    const userId = after.userId;

    // Already in emergency — skip
    if (wasEmergency) return;

    // Check if threat score crossed critical threshold
    if (threatScore >= 81 && !isEmergency) {
      console.log(
        `Auto-escalation: ride ${rideId}, ` +
          `score ${threatScore}`
      );

      const db = admin.firestore();

      // Mark as emergency
      await change.after.ref.update({
        isEmergency: true,
      });

      // Create alert in ride
      const ridesSnap = await db
        .collection("users")
        .doc(userId)
        .collection("rides")
        .where("status", "==", "active")
        .limit(1)
        .get();

      if (!ridesSnap.empty) {
        const rideDoc = ridesSnap.docs[0];

        await rideDoc.ref.collection("alerts").add({
          type: "auto_escalation",
          severity: "critical",
          location: after.currentLocation,
          details: {
            threatScore,
            reason: "Server-side auto-escalation",
            activeAlerts: after.activeAlerts || [],
          },
          threatScore,
          resolved: false,
          notifiedContacts: [],
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update ride status
        await rideDoc.ref.update({
          status: "emergency",
        });
      }
    }
  });

/**
 * Scheduled function to check for stale liveTracking.
 * If a ride hasn't updated in >5 minutes during emergency,
 * send a follow-up alert.
 */
export const checkStaleTracking = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async () => {
    const db = admin.firestore();
    const fiveMinAgo = new Date(
      Date.now() - 5 * 60 * 1000
    );

    const staleSnap = await db
      .collection("liveTracking")
      .where("isEmergency", "==", true)
      .where(
        "updatedAt",
        "<",
        admin.firestore.Timestamp.fromDate(fiveMinAgo)
      )
      .get();

    for (const doc of staleSnap.docs) {
      const data = doc.data();
      console.warn(
        `Stale emergency tracking: ${doc.id}, ` +
          `last update: ${data.updatedAt?.toDate()}`
      );

      // Could trigger additional SMS/calls here
    }

    return null;
  });
