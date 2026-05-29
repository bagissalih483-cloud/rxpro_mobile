const functions = require('firebase-functions');
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { registerAccountingFunctions } = require("./modules/accounting");
const { registerBulkMessagingFunctions } = require("./modules/bulk_messaging");
const { registerNotificationFunctions } = require("./modules/notifications");
const { registerAiGenerationFunctions } = require("./modules/ai_generation");
const { registerDirectoryFunctions } = require("./modules/directory");

admin.initializeApp();

const db = admin.firestore();
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const GOOGLE_PLACES_API_KEY = defineSecret("GOOGLE_PLACES_API_KEY");
const FUNCTION_RATE_LIMITS_COLLECTION = "functionRateLimits";
const FUNCTION_ABUSE_LOGS_COLLECTION = "functionAbuseLogs";

function cleanText(value, fallback = "") {
  if (value === undefined || value === null) return fallback;
  return String(value).trim() || fallback;
}

function callableUid(request) {
  return cleanText(request && request.auth && request.auth.uid);
}

function legacyCallableUid(context) {
  return cleanText(context && context.auth && context.auth.uid);
}

function requireCallableAuth(request, functionName) {
  const uid = callableUid(request);
  if (!uid) {
    throw new HttpsError("unauthenticated", `${functionName}: oturum gerekli.`);
  }
  return uid;
}

function requireLegacyCallableAuth(context, functionName) {
  const uid = legacyCallableUid(context);
  if (!uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      `${functionName}: oturum gerekli.`,
    );
  }
  return uid;
}

async function requireHttpAuth(req, functionName) {
  const header = cleanText(req.headers.authorization || req.headers.Authorization);
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    throw new HttpsError("unauthenticated", `${functionName}: oturum gerekli.`);
  }

  try {
    const decoded = await admin.auth().verifyIdToken(match[1]);
    const uid = cleanText(decoded && decoded.uid);
    if (!uid) throw new Error("uid missing");
    return uid;
  } catch (error) {
    await writeFunctionAbuseLog({
      functionName,
      uid: "",
      reason: "invalid_http_auth",
      detail: error && error.message ? error.message : String(error),
    });
    throw new HttpsError("unauthenticated", `${functionName}: oturum dogrulanamadi.`);
  }
}

function rateLimitDocId(uid, functionName, windowSeconds) {
  const bucket = Math.floor(Date.now() / (windowSeconds * 1000));
  return [uid, functionName, bucket]
    .join("_")
    .replace(/[^a-zA-Z0-9_-]/g, "_")
    .slice(0, 240);
}

async function enforceFunctionRateLimit({
  uid,
  functionName,
  limit,
  windowSeconds,
}) {
  const docRef = db
    .collection(FUNCTION_RATE_LIMITS_COLLECTION)
    .doc(rateLimitDocId(uid, functionName, windowSeconds));
  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + windowSeconds * 1000 * 2,
  );

  let exceededDetail = "";
  try {
    await db.runTransaction(async (transaction) => {
      const snap = await transaction.get(docRef);
      const current = snap.exists ? Number(snap.data().count || 0) : 0;
      if (current >= limit) {
        exceededDetail = `${current}/${limit}/${windowSeconds}s`;
        throw new HttpsError(
          "resource-exhausted",
          "Kisa surede cok fazla istek yapildi. Lutfen biraz sonra tekrar deneyin.",
        );
      }

      transaction.set(
        docRef,
        {
          uid,
          functionName,
          count: current + 1,
          limit,
          windowSeconds,
          updatedAt: now,
          expiresAt,
        },
        { merge: true },
      );
    });
  } catch (error) {
    if (error instanceof HttpsError && error.code === "resource-exhausted") {
      await writeFunctionAbuseLog({
        functionName,
        uid,
        reason: "rate_limit_exceeded",
        detail: exceededDetail,
      });
    }
    throw error;
  }
}

async function writeFunctionAbuseLog({ functionName, uid, reason, detail }) {
  try {
    await db.collection(FUNCTION_ABUSE_LOGS_COLLECTION).add({
      functionName: cleanText(functionName),
      uid: cleanText(uid),
      reason: cleanText(reason),
      detail: cleanText(detail).slice(0, 500),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error("function abuse log yazilamadi:", {
      functionName,
      reason,
      message: error && error.message ? error.message : String(error),
    });
  }
}

function safeSecretValue(secret, name) {
  try {
    return cleanText(secret.value() || process.env[name]);
  } catch (error) {
    console.error(`${name} secret okunamadi:`, {
      message: error && error.message ? error.message : String(error)
    });
    return cleanText(process.env[name]);
  }
}

registerNotificationFunctions({
  exportsTarget: exports,
  onDocumentCreated,
  onSchedule,
  admin,
  db,
});

registerAiGenerationFunctions({
  exportsTarget: exports,
  onRequest,
  HttpsError,
  functions,
  OPENAI_API_KEY,
  cleanText,
  requireHttpAuth,
  requireLegacyCallableAuth,
  enforceFunctionRateLimit,
});

registerDirectoryFunctions({
  exportsTarget: exports,
  onCall,
  HttpsError,
  admin,
  db,
  GOOGLE_PLACES_API_KEY,
  cleanText,
  safeSecretValue,
  requireCallableAuth,
  enforceFunctionRateLimit,
  enablePlacesDirectorySearch: false,
});

registerBulkMessagingFunctions({
  exportsTarget: exports,
  onCall,
  HttpsError,
  admin,
  db,
});

registerAccountingFunctions({
  exportsTarget: exports,
  functions,
  admin,
  db,
});
