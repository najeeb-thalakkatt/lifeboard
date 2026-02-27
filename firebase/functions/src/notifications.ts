import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Triggered when a comment is created on a task.
 * Creates an activity entry and sends FCM to other space members.
 */
export const onCommentCreate = functions.firestore
  .document("spaces/{spaceId}/tasks/{taskId}/comments/{commentId}")
  .onCreate(async (snapshot, context) => {
    const {spaceId, taskId} = context.params;
    const commentData = snapshot.data();

    if (!commentData) return;

    const authorId: string = commentData.authorId || "";
    const commentText: string = commentData.text || "";

    // Get the task title for the activity message
    const taskDoc = await db
      .collection("spaces")
      .doc(spaceId)
      .collection("tasks")
      .doc(taskId)
      .get();

    const taskTitle: string = taskDoc.exists
      ? (taskDoc.data()?.title || "a task")
      : "a task";

    // Truncate comment for activity message
    const preview =
      commentText.length > 40
        ? commentText.substring(0, 40) + "..."
        : commentText;

    const message = `commented on "${taskTitle}": "${preview}"`;

    // Write activity entry
    const activityRef = db
      .collection("spaces")
      .doc(spaceId)
      .collection("activity")
      .doc();

    const activityData = {
      type: "comment_added",
      actorId: authorId,
      taskId: taskId,
      spaceId: spaceId,
      message: message,
      reactions: {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await activityRef.set(activityData);

    // Send FCM to other space members
    await sendFcmToSpaceMembers(spaceId, authorId, message);
  });

/**
 * Sends FCM push notifications to all space members except the actor.
 */
async function sendFcmToSpaceMembers(
  spaceId: string,
  actorId: string,
  body: string
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

  // Collect FCM tokens
  const tokens: string[] = [];
  for (const memberId of memberIds) {
    const userDoc = await db.collection("users").doc(memberId).get();
    if (!userDoc.exists) continue;

    const userData = userDoc.data();
    if (!userData) continue;

    const prefs = userData.notificationPrefs;
    if (prefs && prefs.pushEnabled === false) continue;

    const userTokens: string[] = userData.fcmTokens || [];
    tokens.push(...userTokens);
  }

  if (tokens.length === 0) return;

  const payload: admin.messaging.MulticastMessage = {
    tokens: tokens,
    notification: {
      title: "Lifeboard",
      body: `${actorName} ${body}`,
    },
    data: {
      type: "comment",
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
