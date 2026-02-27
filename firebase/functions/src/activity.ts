import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/** Status labels matching the Flutter app's warm language. */
const STATUS_LABELS: Record<string, string> = {
  todo: "To Do",
  in_progress: "Working on it",
  done: "Done 🎉",
};

/**
 * Triggered on any write to a task document.
 * Creates an activity entry and sends FCM to other space members.
 */
export const onTaskWrite = functions.firestore
  .document("spaces/{spaceId}/tasks/{taskId}")
  .onWrite(async (change, context) => {
    const {spaceId, taskId} = context.params;
    const before = change.before.data();
    const after = change.after.data();

    // Task deleted — skip activity for now
    if (!after) return;

    const actorId: string = after.createdBy || "";
    const taskTitle: string = after.title || "a task";

    let activityType: string;
    let message: string;

    if (!before) {
      // Task created
      activityType = "task_created";
      message = `created "${taskTitle}"`;
    } else if (before.status !== after.status) {
      // Status changed
      if (after.status === "done") {
        activityType = "task_completed";
        message = `completed "${taskTitle}" 🎉`;
      } else {
        activityType = "task_moved";
        const newLabel = STATUS_LABELS[after.status] || after.status;
        message = `moved "${taskTitle}" to ${newLabel}`;
      }
      // Use the user who last updated (approximation — updatedAt changed)
    } else {
      // Other field changes — skip to avoid noise
      return;
    }

    // Write activity entry
    const activityRef = db
      .collection("spaces")
      .doc(spaceId)
      .collection("activity")
      .doc();

    const activityData = {
      type: activityType,
      actorId: actorId,
      taskId: taskId,
      spaceId: spaceId,
      message: message,
      reactions: {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await activityRef.set(activityData);

    // Send FCM to other space members
    await sendFcmToSpaceMembers(spaceId, actorId, message, taskTitle);
  });

/**
 * Sends FCM push notifications to all space members except the actor.
 */
async function sendFcmToSpaceMembers(
  spaceId: string,
  actorId: string,
  body: string,
  _taskTitle: string
): Promise<void> {
  // Get space to find members
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
      type: "activity",
      spaceId: spaceId,
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
      for (const token of invalidTokens) {
        for (const memberId of memberIds) {
          await db
            .collection("users")
            .doc(memberId)
            .update({
              fcmTokens: admin.firestore.FieldValue.arrayRemove([token]),
            })
            .catch(() => {/* ignore */});
        }
      }
    }
  } catch (error) {
    functions.logger.error("Error sending FCM:", error);
  }
}
