import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Export all user data (GDPR compliance).
 */
export const exportUserData = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }

    const userId = context.auth.uid;
    const db = admin.firestore();

    // Collect all user data
    const userData: Record<string, unknown> = {};

    // User profile
    const userDoc = await db
      .collection("users")
      .doc(userId)
      .get();

    if (userDoc.exists) {
      userData.profile = userDoc.data();
    }

    // Emergency contacts
    const contactsSnap = await db
      .collection("users")
      .doc(userId)
      .collection("emergencyContacts")
      .get();

    userData.emergencyContacts = contactsSnap.docs.map(
      (doc) => ({ id: doc.id, ...doc.data() })
    );

    // Rides
    const ridesSnap = await db
      .collection("users")
      .doc(userId)
      .collection("rides")
      .orderBy("startedAt", "desc")
      .get();

    const rides = [];
    for (const rideDoc of ridesSnap.docs) {
      const rideData = { id: rideDoc.id, ...rideDoc.data() };

      // Get alerts for this ride
      const alertsSnap = await rideDoc.ref
        .collection("alerts")
        .get();

      (rideData as Record<string, unknown>).alerts =
        alertsSnap.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));

      // Get location trail
      const trailSnap = await rideDoc.ref
        .collection("locationTrail")
        .orderBy("timestamp")
        .get();

      (rideData as Record<string, unknown>).locationTrail =
        trailSnap.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));

      rides.push(rideData);
    }
    userData.rides = rides;

    // Audio evidence metadata
    const evidenceSnap = await db
      .collection("users")
      .doc(userId)
      .collection("audioEvidence")
      .get();

    userData.audioEvidence = evidenceSnap.docs.map(
      (doc) => ({ id: doc.id, ...doc.data() })
    );

    userData.exportedAt = new Date().toISOString();

    return userData;
  }
);

/**
 * Delete all user data (GDPR right to erasure).
 */
export const deleteUserData = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }

    const userId = context.auth.uid;
    const db = admin.firestore();
    const storage = admin.storage().bucket();

    // Delete audio files from Storage
    try {
      await storage.deleteFiles({
        prefix: `audio_evidence/${userId}/`,
      });
      await storage.deleteFiles({
        prefix: `profile_photos/${userId}/`,
      });
    } catch (err) {
      console.error("Storage cleanup error:", err);
    }

    // Delete Firestore subcollections
    const userRef = db.collection("users").doc(userId);

    // Delete emergency contacts
    await deleteCollection(
      userRef.collection("emergencyContacts")
    );

    // Delete rides and their subcollections
    const ridesSnap = await userRef
      .collection("rides")
      .get();

    for (const rideDoc of ridesSnap.docs) {
      await deleteCollection(
        rideDoc.ref.collection("locationTrail")
      );
      await deleteCollection(
        rideDoc.ref.collection("alerts")
      );
      await rideDoc.ref.delete();
    }

    // Delete audio evidence
    await deleteCollection(
      userRef.collection("audioEvidence")
    );

    // Delete live tracking
    const trackingSnap = await db
      .collection("liveTracking")
      .where("userId", "==", userId)
      .get();

    for (const doc of trackingSnap.docs) {
      await doc.ref.delete();
    }

    // Delete tracking tokens
    const tokensSnap = await db
      .collection("trackingTokens")
      .where("userId", "==", userId)
      .get();

    for (const doc of tokensSnap.docs) {
      await doc.ref.delete();
    }

    // Delete user document
    await userRef.delete();

    // Delete Firebase Auth account
    try {
      await admin.auth().deleteUser(userId);
    } catch (err) {
      console.error("Auth deletion error:", err);
    }

    return { success: true, deletedAt: new Date().toISOString() };
  }
);

async function deleteCollection(
  collectionRef: admin.firestore.CollectionReference
): Promise<void> {
  const snapshot = await collectionRef.get();
  if (snapshot.empty) return;

  const batch = admin.firestore().batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();
}
