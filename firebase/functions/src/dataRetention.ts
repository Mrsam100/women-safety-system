import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const RETENTION_DAYS = 30;

/**
 * Scheduled function that runs daily to delete
 * expired audio evidence (older than 30 days).
 */
export const deleteExpiredEvidence = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const db = admin.firestore();
    const storage = admin.storage().bucket();
    const now = admin.firestore.Timestamp.now();

    console.log("Running data retention cleanup...");

    // Find all users
    const usersSnap = await db.collection("users").get();
    let deletedCount = 0;

    for (const userDoc of usersSnap.docs) {
      // Find expired audio evidence
      const evidenceSnap = await userDoc.ref
        .collection("audioEvidence")
        .where("expiresAt", "<", now)
        .get();

      for (const evidenceDoc of evidenceSnap.docs) {
        const data = evidenceDoc.data();

        // Check if user has saved this evidence
        if (data.isSaved) {
          continue;
        }

        // Delete from Cloud Storage
        if (data.storageUrl) {
          try {
            const filePath = extractPathFromUrl(
              data.storageUrl
            );
            if (filePath) {
              await storage.file(filePath).delete();
              console.log(
                `Deleted storage file: ${filePath}`
              );
            }
          } catch (err) {
            console.error(
              `Failed to delete storage file: ${err}`
            );
          }
        }

        // Delete Firestore document
        await evidenceDoc.ref.delete();
        deletedCount++;
      }

      // Delete old location trail data
      const ridesSnap = await userDoc.ref
        .collection("rides")
        .where("status", "==", "completed")
        .get();

      for (const rideDoc of ridesSnap.docs) {
        const rideData = rideDoc.data();
        const endedAt = rideData.endedAt?.toDate();

        if (!endedAt) continue;

        const daysSinceEnd = Math.floor(
          (Date.now() - endedAt.getTime()) /
            (1000 * 60 * 60 * 24)
        );

        if (daysSinceEnd > RETENTION_DAYS) {
          // Delete location trail subcollection
          const trailSnap = await rideDoc.ref
            .collection("locationTrail")
            .get();

          const batch = db.batch();
          trailSnap.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });
          await batch.commit();

          console.log(
            `Deleted location trail for ride ${rideDoc.id}`
          );
        }
      }
    }

    console.log(
      `Data retention cleanup complete. ` +
        `Deleted ${deletedCount} evidence records.`
    );

    return null;
  });

function extractPathFromUrl(url: string): string | null {
  try {
    const match = url.match(
      /\/o\/(.+?)\?/
    );
    if (match && match[1]) {
      return decodeURIComponent(match[1]);
    }
    return null;
  } catch {
    return null;
  }
}
