import * as functions from "firebase-functions";
import {db} from "./admin";

/**
 * Callable Cloud Function to look up a space by invite code.
 * Returns the space ID if found, without exposing the full space document.
 *
 * This allows Firestore rules to restrict space reads to members only,
 * while still supporting the join-by-invite-code flow.
 */
export const lookupInviteCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be signed in to look up an invite code."
    );
  }

  const inviteCode: string | undefined = data?.inviteCode;
  if (!inviteCode || typeof inviteCode !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "inviteCode is required."
    );
  }

  const snapshot = await db
    .collection("spaces")
    .where("inviteCode", "==", inviteCode.toUpperCase())
    .limit(1)
    .get();

  if (snapshot.empty) {
    throw new functions.https.HttpsError(
      "not-found",
      "No space found with that invite code."
    );
  }

  const doc = snapshot.docs[0];
  const spaceData = doc.data();
  const userId = context.auth.uid;

  // Check if user is already a member
  if (spaceData.members && spaceData.members[userId]) {
    throw new functions.https.HttpsError(
      "already-exists",
      "You are already a member of this space."
    );
  }

  return {
    spaceId: doc.id,
    spaceName: spaceData.name || "Unnamed Space",
  };
});
