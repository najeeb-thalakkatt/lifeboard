import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {sendFcmToSpaceMembers} from "./fcm";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Triggered when a HomePad item is written (created or updated).
 *
 * Handles two notification scenarios:
 * 1. "Items Added" — batched via a pendingNotification doc (5-min debounce)
 * 2. "All Done" — when the last to_buy item is marked purchased
 */
export const onHomePadItemWrite = functions.firestore
  .document("spaces/{spaceId}/homepad_items/{itemId}")
  .onWrite(async (change, context) => {
    const {spaceId} = context.params;
    const before = change.before.data();
    const after = change.after.data();

    // Item deleted — skip
    if (!after) return;

    const newStatus: string = after.status || "available";
    const oldStatus: string = before?.status || "available";

    // ── Case 1: Item marked as "to_buy" ─────────────────────────
    if (newStatus === "to_buy" && oldStatus !== "to_buy") {
      const addedBy: string = after.addedBy || "";
      const itemName: string = after.name || "an item";

      if (!addedBy) return;

      // Debounce: use a pending notification doc per space + user
      const pendingRef = db
        .collection("spaces")
        .doc(spaceId)
        .collection("homepad_pending_notifications")
        .doc(addedBy);

      await db.runTransaction(async (tx) => {
        const pendingDoc = await tx.get(pendingRef);

        if (pendingDoc.exists) {
          // Append item to existing pending notification
          const data = pendingDoc.data()!;
          const items: string[] = data.items || [];
          items.push(itemName);
          tx.update(pendingRef, {items, updatedAt: admin.firestore.FieldValue.serverTimestamp()});
        } else {
          // Create new pending notification with 5-min window
          tx.set(pendingRef, {
            addedBy,
            items: [itemName],
            spaceId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });

      return;
    }

    // ── Case 2: Item marked as "purchased" — check if all done ──
    if (newStatus === "purchased" && oldStatus === "to_buy") {
      const purchasedBy: string = after.purchasedBy || "";

      // Check if there are any remaining to_buy items
      const remainingSnapshot = await db
        .collection("spaces")
        .doc(spaceId)
        .collection("homepad_items")
        .where("status", "==", "to_buy")
        .limit(1)
        .get();

      if (remainingSnapshot.empty && purchasedBy) {
        // All items purchased — send "All Done" notification
        await sendFcmToSpaceMembers(
          spaceId,
          purchasedBy,
          "finished the shopping! All items checked off. 🎉",
          "homepad_all_done"
        );

        // Write activity entry
        const activityRef = db
          .collection("spaces")
          .doc(spaceId)
          .collection("activity")
          .doc();

        await activityRef.set({
          type: "homepad_all_done",
          actorId: purchasedBy,
          spaceId,
          message: "finished the shopping! All items checked off. 🎉",
          reactions: {},
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
  });

/**
 * Scheduled function that runs every 5 minutes to flush pending
 * HomePad "items added" notifications.
 *
 * This implements the batching/debounce strategy:
 * - Collects all pending notification docs older than 5 minutes
 * - Sends a single batched push notification per actor
 * - Deletes the pending doc
 */
export const flushHomePadNotifications = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async () => {
    const fiveMinutesAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 5 * 60 * 1000)
    );

    // Query all pending notifications across all spaces
    const pendingQuery = await db
      .collectionGroup("homepad_pending_notifications")
      .where("updatedAt", "<=", fiveMinutesAgo)
      .get();

    if (pendingQuery.empty) {
      functions.logger.info("No pending HomePad notifications to flush.");
      return;
    }

    const promises: Promise<void>[] = [];

    for (const doc of pendingQuery.docs) {
      const data = doc.data();
      const spaceId: string = data.spaceId || "";
      const addedBy: string = data.addedBy || "";
      const items: string[] = data.items || [];

      if (!spaceId || !addedBy || items.length === 0) {
        promises.push(doc.ref.delete().then(() => undefined));
        continue;
      }

      // Build notification message
      let message: string;
      if (items.length === 1) {
        message = `added ${items[0]} to HomePad`;
      } else if (items.length <= 3) {
        const last = items.pop()!;
        message = `added ${items.join(", ")}, and ${last} to HomePad`;
      } else {
        const preview = items.slice(0, 3).join(", ");
        message = `added ${items.length} items to HomePad: ${preview}...`;
      }

      // Send notification and write activity entry, then delete pending doc
      const sendPromise = (async () => {
        await sendFcmToSpaceMembers(spaceId, addedBy, message, "homepad_items_added");

        // Write activity entry
        const activityRef = db
          .collection("spaces")
          .doc(spaceId)
          .collection("activity")
          .doc();

        await activityRef.set({
          type: "homepad_items_added",
          actorId: addedBy,
          spaceId,
          message,
          reactions: {},
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await doc.ref.delete();
      })();

      promises.push(sendPromise);
    }

    await Promise.all(promises);
    functions.logger.info(`Flushed ${pendingQuery.size} pending HomePad notifications.`);
  });
