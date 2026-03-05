import * as functions from "firebase-functions";
import {admin, db} from "./admin";

/**
 * HTTP Cloud Function to send a test push notification.
 *
 * Usage:
 *   curl "https://us-central1-lifeboard-8cd26.cloudfunctions.net/sendTestPush?userId=<USER_ID>"
 *
 * Query params:
 *   - userId (required): Firestore user ID to send the push to.
 *   - title  (optional): Custom notification title.
 *   - body   (optional): Custom notification body.
 */
export const sendTestPush = functions.https.onRequest(async (req, res) => {
  // Only allow in non-production or with a valid Firebase ID token
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({error: "Missing or invalid Authorization header. Use: Bearer <Firebase ID token>"});
    return;
  }

  try {
    const idToken = authHeader.split("Bearer ")[1];
    await admin.auth().verifyIdToken(idToken);
  } catch (_e) {
    res.status(403).json({error: "Invalid or expired Firebase ID token"});
    return;
  }

  const userId = req.query.userId as string | undefined;

  if (!userId) {
    res.status(400).json({error: "Missing required query param: userId"});
    return;
  }

  // Look up user doc
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    res.status(404).json({error: `User not found: ${userId}`});
    return;
  }

  const userData = userDoc.data()!;
  const tokens: string[] = userData.fcmTokens || [];
  const displayName = userData.displayName || "(no name)";

  functions.logger.info(
    `Test push for user ${displayName} (${userId}), tokens: ${tokens.length}`
  );

  if (tokens.length === 0) {
    res.status(404).json({
      error: "No FCM tokens found for this user",
      userId,
      displayName,
    });
    return;
  }

  const title = (req.query.title as string) || "🧪 Lifeboard Test Push";
  const body =
    (req.query.body as string) ||
    `Test notification sent at ${new Date().toLocaleTimeString()}`;

  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: {title, body},
    data: {
      type: "test",
      timestamp: Date.now().toString(),
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
    const response = await admin.messaging().sendEachForMulticast(message);

    const results = response.responses.map((resp, idx) => ({
      token: tokens[idx].substring(0, 25) + "...",
      success: resp.success,
      messageId: resp.messageId || null,
      error: resp.error
        ? {code: resp.error.code, message: resp.error.message}
        : null,
    }));

    functions.logger.info("Test push results:", JSON.stringify(results));

    res.json({
      userId,
      displayName,
      tokenCount: tokens.length,
      successCount: response.successCount,
      failureCount: response.failureCount,
      results,
    });
  } catch (error) {
    functions.logger.error("Test push error:", error);
    res.status(500).json({error: String(error)});
  }
});
