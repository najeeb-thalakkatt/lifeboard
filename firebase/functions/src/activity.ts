import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {sendFcmToSpaceMembers} from "./fcm";

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
    await sendFcmToSpaceMembers(spaceId, actorId, message, "activity", taskId);

    // ── Recurring task: auto-create next occurrence on completion ──
    if (
      activityType === "task_completed" &&
      after.recurrenceRule &&
      after.recurrenceRule !== "never"
    ) {
      const nextDue = computeNextDueDate(
        after.dueDate ? after.dueDate.toDate() : new Date(),
        after.recurrenceRule
      );

      const newTaskData: Record<string, unknown> = {
        title: after.title,
        description: after.description || null,
        status: "todo",
        boardId: after.boardId,
        assignees: after.assignees || [],
        dueDate: nextDue
          ? admin.firestore.Timestamp.fromDate(nextDue)
          : null,
        emojiTag: after.emojiTag || null,
        subtasks: (after.subtasks || []).map(
          (s: {id: string; title: string}) => ({
            ...s,
            completed: false,
          })
        ),
        attachments: [],
        isWeeklyTask: false,
        weekStart: null,
        order: 0,
        completedAt: null,
        archivedAt: null,
        isBlocked: false,
        blockedReason: null,
        recurrenceRule: after.recurrenceRule,
        createdBy: actorId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await db
        .collection("spaces")
        .doc(spaceId)
        .collection("tasks")
        .add(newTaskData);
    }
  });

/**
 * Computes the next due date based on the recurrence rule.
 */
function computeNextDueDate(
  currentDue: Date,
  rule: string
): Date | null {
  const next = new Date(currentDue);
  switch (rule) {
    case "daily":
      next.setDate(next.getDate() + 1);
      break;
    case "weekly":
      next.setDate(next.getDate() + 7);
      break;
    case "biweekly":
      next.setDate(next.getDate() + 14);
      break;
    case "monthly":
      next.setMonth(next.getMonth() + 1);
      break;
    default:
      return null;
  }
  // If the computed date is in the past, jump to the next occurrence from today
  const now = new Date();
  while (next <= now) {
    switch (rule) {
      case "daily":
        next.setDate(next.getDate() + 1);
        break;
      case "weekly":
        next.setDate(next.getDate() + 7);
        break;
      case "biweekly":
        next.setDate(next.getDate() + 14);
        break;
      case "monthly":
        next.setMonth(next.getMonth() + 1);
        break;
    }
  }
  return next;
}
