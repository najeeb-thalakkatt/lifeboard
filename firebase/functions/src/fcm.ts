import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Sends FCM push notifications to all space members except the actor.
 *
 * @param spaceId - The space whose members should be notified.
 * @param actorId - The user who performed the action (excluded from notifications).
 * @param body - The notification body text (actor name is prepended automatically).
 * @param dataType - The `type` field in the FCM data payload (e.g. "activity", "comment").
 */
export async function sendFcmToSpaceMembers(
  spaceId: string,
  actorId: string,
  body: string,
  dataType: string = "activity",
  taskId?: string
): Promise<void> {
  const spaceDoc = await db.collection("spaces").doc(spaceId).get();
  if (!spaceDoc.exists) return;

  const spaceData = spaceDoc.data();
  if (!spaceData || !spaceData.members) return;

  const memberIds: string[] = Object.keys(spaceData.members).filter(
    (id) => id !== actorId
  );
  if (memberIds.length === 0) return;

  // Get actor's display name
  const actorDoc = await db.collection("users").doc(actorId).get();
  const actorName: string = actorDoc.exists
    ? (actorDoc.data()?.displayName || "Someone")
    : "Someone";

  // Collect FCM tokens from members
  const tokens: string[] = [];
  for (const memberId of memberIds) {
    const userDoc = await db.collection("users").doc(memberId).get();
    if (!userDoc.exists) continue;

    const userData = userDoc.data();
    if (!userData) continue;

    // Check notification preferences
    const prefs = userData.notificationPrefs;
    if (prefs && prefs.pushEnabled === false) continue;

    const userTokens: string[] = userData.fcmTokens || [];
    tokens.push(...userTokens);
  }

  if (tokens.length === 0) return;

  // Send multicast message
  const payload: admin.messaging.MulticastMessage = {
    tokens: tokens,
    notification: {
      title: "Lifeboard",
      body: `${actorName} ${body}`,
    },
    data: {
      type: dataType,
      spaceId: spaceId,
      ...(taskId ? {taskId} : {}),
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
    android: {
      notification: {
        channelId: "lifeboard_updates",
        sound: "default",
      },
    },
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(payload);
    // Clean up invalid tokens
    if (response.failureCount > 0) {
      const invalidTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (resp.error) {
          const code = resp.error.code;
          if (
            code === "messaging/invalid-registration-token" ||
            code === "messaging/registration-token-not-registered"
          ) {
            invalidTokens.push(tokens[idx]);
          }
        }
      });
      // Remove invalid tokens from user docs
      if (invalidTokens.length > 0) {
        const removePromises = invalidTokens.flatMap((token) =>
          memberIds.map((memberId) =>
            db
              .collection("users")
              .doc(memberId)
              .update({
                fcmTokens: admin.firestore.FieldValue.arrayRemove([token]),
              })
              .catch(() => {/* ignore — token may not belong to this user */})
          )
        );
        await Promise.all(removePromises);
      }
    }
  } catch (error) {
    functions.logger.error("Error sending FCM:", error);
  }
}
