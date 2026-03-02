import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {sendFcmToSpaceMembers} from "./fcm";

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
    await sendFcmToSpaceMembers(spaceId, authorId, message, "comment", taskId);
  });
