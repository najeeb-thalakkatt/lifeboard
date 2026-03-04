#!/usr/bin/env npx ts-node
/**
 * Standalone script to send a test push notification to a Lifeboard user.
 *
 * Usage (from firebase/functions/):
 *   npx ts-node src/test-push.ts <userId>
 *   npx ts-node src/test-push.ts --token <fcmToken>
 *
 * Prerequisites:
 *   - Firebase Admin SDK credentials (GOOGLE_APPLICATION_CREDENTIALS env var
 *     or default Application Default Credentials via `gcloud auth application-default login`)
 *   - npm install in firebase/functions/
 */

import * as admin from "firebase-admin";

// ── Initialise Firebase Admin ────────────────────────────────
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "lifeboard-8cd26" });
}

const db = admin.firestore();

// ── Helpers ──────────────────────────────────────────────────

async function getTokensForUser(userId: string): Promise<string[]> {
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    console.error(`❌ User document not found for userId: ${userId}`);
    process.exit(1);
  }

  const data = userDoc.data()!;
  const tokens: string[] = data.fcmTokens || [];

  console.log(`👤 User: ${data.displayName || "(no name)"} (${userId})`);
  console.log(`📱 FCM tokens found: ${tokens.length}`);

  if (tokens.length === 0) {
    console.error(
      "❌ No FCM tokens stored for this user. " +
        "Make sure the app has been opened and push permissions granted."
    );
    process.exit(1);
  }

  tokens.forEach((t, i) =>
    console.log(`   [${i}] ${t.substring(0, 30)}...`)
  );

  return tokens;
}

async function sendTestPush(tokens: string[]): Promise<void> {
  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: {
      title: "🧪 Lifeboard Test Push",
      body: `Test notification sent at ${new Date().toLocaleTimeString()}`,
    },
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

  console.log("\n📤 Sending test push notification...");

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(
      `\n✅ Success: ${response.successCount} | ❌ Failure: ${response.failureCount}`
    );

    response.responses.forEach((resp, idx) => {
      if (resp.success) {
        console.log(`   [${idx}] ✅ Delivered (messageId: ${resp.messageId})`);
      } else {
        console.log(
          `   [${idx}] ❌ Failed: ${resp.error?.code} — ${resp.error?.message}`
        );
        if (
          resp.error?.code === "messaging/invalid-registration-token" ||
          resp.error?.code === "messaging/registration-token-not-registered"
        ) {
          console.log(
            `        ↳ Token is invalid/expired. Remove it from Firestore.`
          );
        }
      }
    });
  } catch (error) {
    console.error("❌ Fatal error sending push:", error);
    process.exit(1);
  }
}

// ── Main ─────────────────────────────────────────────────────

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log(
      "Usage:\n" +
        "  npx ts-node src/test-push.ts <userId>\n" +
        "  npx ts-node src/test-push.ts --token <fcmToken>\n"
    );
    process.exit(1);
  }

  let tokens: string[];

  if (args[0] === "--token") {
    if (!args[1]) {
      console.error("❌ Please provide an FCM token after --token");
      process.exit(1);
    }
    tokens = [args[1]];
    console.log(`📱 Using direct token: ${tokens[0].substring(0, 30)}...`);
  } else {
    const userId = args[0];
    tokens = await getTokensForUser(userId);
  }

  await sendTestPush(tokens);
  process.exit(0);
}

main().catch((err) => {
  console.error("Unhandled error:", err);
  process.exit(1);
});
