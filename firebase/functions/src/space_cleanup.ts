import * as functions from "firebase-functions";
import {admin, db} from "./admin";

/**
 * Triggered when a space document is deleted.
 * Recursively deletes all subcollections (boards, tasks, comments,
 * homepad_items, homepad_pending_notifications, activity) to prevent
 * orphaned data and unnecessary Firestore billing.
 */
export const onSpaceDeleted = functions.firestore
  .document("spaces/{spaceId}")
  .onDelete(async (_snapshot, context) => {
    const {spaceId} = context.params;
    const spaceRef = db.collection("spaces").doc(spaceId);

    const subcollections = [
      "boards",
      "tasks",
      "homepad_items",
      "homepad_pending_notifications",
      "activity",
    ];

    for (const subcollection of subcollections) {
      await deleteCollection(spaceRef.collection(subcollection));
    }

    // Delete comments (sub-sub-collection under tasks)
    // Tasks are already queued for deletion above, but comments need
    // explicit deletion since deleteCollection doesn't recurse.
    const tasksSnapshot = await spaceRef.collection("tasks").get();
    for (const taskDoc of tasksSnapshot.docs) {
      await deleteCollection(taskDoc.ref.collection("comments"));
    }

    functions.logger.info(
      `Cleaned up all subcollections for deleted space ${spaceId}`
    );
  });

/**
 * Deletes all documents in a Firestore collection in batches of 500.
 */
async function deleteCollection(
  collectionRef: admin.firestore.CollectionReference
): Promise<void> {
  const batchSize = 500;

  const query = collectionRef.limit(batchSize);
  let snapshot = await query.get();

  while (!snapshot.empty) {
    const batch = db.batch();
    for (const doc of snapshot.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();

    if (snapshot.size < batchSize) break;
    snapshot = await query.get();
  }
}
