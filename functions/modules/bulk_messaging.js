"use strict";

const BULK_TARGET_PAGE_SIZE = 100;
const BULK_TARGET_PAGE_CAP = 1000;

function registerBulkMessagingFunctions({
  exportsTarget,
  onCall,
  HttpsError,
  admin,
  db,
}) {
  function clean(value, fallback = "") {
    if (value === undefined || value === null) return fallback;
    const text = String(value).trim();
    return text || fallback;
  }

  function safeDocId(value) {
    return clean(value).replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 420);
  }

  function dateValue(value) {
    if (!value) return null;
    if (typeof value.toDate === "function") return value.toDate();
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }

  function sendingIsStale(draftData) {
    const startedAt = dateValue(draftData.sendStartedAt);
    if (!startedAt) return false;
    return Date.now() - startedAt.getTime() > 10 * 60 * 1000;
  }

  function canSendDraft(draftData) {
    const status = clean(draftData.status, "draft").toLowerCase();
    const sendStatus = clean(draftData.sendStatus, "draft_ready").toLowerCase();

    return (
      status === "draft" &&
      ["draft_ready", "ready", "scheduled", "send_failed"].includes(sendStatus)
    );
  }

  function consentAllowed(data, consentOnly) {
    if (!consentOnly) return false;

    if (
      data.bulkMessageOptOut === true ||
      data.marketingOptOut === true ||
      data.notificationOptOut === true ||
      data.campaignOptOut === true
    ) {
      return false;
    }

    return (
      data.bulkMessageConsent === true ||
      data.marketingConsent === true ||
      data.notificationConsent === true ||
      data.campaignConsent === true ||
      data.campaignPermission === true ||
      data.allowCampaignMessages === true
    );
  }

  async function assertDraftOwner(uid, draftData) {
    const ownerUid = clean(draftData.ownerUid || draftData.createdBy);
    if (ownerUid && ownerUid === uid) return;

    const businessId = clean(draftData.businessId);
    if (!businessId) {
      throw new HttpsError("permission-denied", "Taslak işletme bilgisi eksik.");
    }

    const businessDoc = await db.collection("businesses").doc(businessId).get();
    const business = businessDoc.exists ? businessDoc.data() || {} : {};
    const ownerCandidates = [
      business.ownerUid,
      business.ownerId,
      business.businessOwnerUid,
      business.userId,
      business.uid,
      business.createdBy,
      business.createdByUid,
      business.adminUid,
      business.managerUid,
    ].map((value) => clean(value));

    const ownerLists = [
      business.ownerUids,
      business.adminUids,
      business.managerUids,
      business.authorizedUids,
    ].filter(Array.isArray);

    if (
      ownerCandidates.includes(uid) ||
      ownerLists.some((list) => list.map((value) => clean(value)).includes(uid))
    ) {
      return;
    }

    throw new HttpsError(
      "permission-denied",
      "Bu toplu mesaj taslağı için yetkiniz yok.",
    );
  }

  async function collectTargetCustomers(draftData) {
    const businessId = clean(draftData.businessId);
    const metadata =
      draftData.audienceMetadata && typeof draftData.audienceMetadata === "object"
        ? draftData.audienceMetadata
        : {};
    const segmentId = clean(metadata.segmentId || draftData.segmentId || "all");

    if (!businessId) return [];

    const docs = [];
    let lastDoc = null;
    while (docs.length < BULK_TARGET_PAGE_CAP) {
      let query = db
        .collection("businessCustomers")
        .where("businessId", "==", businessId)
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(BULK_TARGET_PAGE_SIZE);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snap = await query.get();
      if (snap.empty) break;

      for (const doc of snap.docs) {
        if (docs.length >= BULK_TARGET_PAGE_CAP) break;
        docs.push(doc);
      }

      lastDoc = snap.docs[snap.docs.length - 1];
      if (snap.size < BULK_TARGET_PAGE_SIZE) break;
    }

    const byUid = new Map();
    const consentOnly = draftData.consentOnly !== false;

    docs.forEach((doc) => {
      const data = doc.data() || {};
      const customerUid = clean(
        data.customerUid || data.customerId || data.userId || data.uid || data.clientUid,
      );

      if (!customerUid || customerUid === "-") return;
      const customerSegmentId = clean(data.segmentId || "manual");
      if (segmentId && segmentId !== "all" && customerSegmentId !== segmentId) return;
      if (!consentAllowed(data, consentOnly)) return;
      if (byUid.has(customerUid)) return;

      byUid.set(customerUid, {
        customerUid,
        customerName: clean(data.customerName || data.name || data.displayName),
        customerPhone: clean(data.customerPhone || data.phone),
        segmentId: customerSegmentId,
        sourceDocId: doc.id,
      });
    });

    return Array.from(byUid.values());
  }

  exportsTarget.sendBulkMessageDraft = onCall(
    {
      region: "europe-west1",
    },
    async (request) => {
      const uid = request.auth && request.auth.uid;
      if (!uid) {
        throw new HttpsError("unauthenticated", "Oturum bulunamadı.");
      }

      const draftId = clean(request.data && request.data.draftId);
      if (!draftId) {
        throw new HttpsError("invalid-argument", "draftId zorunludur.");
      }

      const draftRef = db.collection("bulkMessageDrafts").doc(draftId);
      const draftSnap = await draftRef.get();

      if (!draftSnap.exists) {
        throw new HttpsError("not-found", "Toplu mesaj taslağı bulunamadı.");
      }

      const draft = draftSnap.data() || {};
      await assertDraftOwner(uid, draft);

      const attemptId =
        safeDocId(request.data && request.data.clientRequestId) ||
        db.collection("_bulkAttemptIds").doc().id;

      const claim = await db.runTransaction(async (transaction) => {
        const freshSnap = await transaction.get(draftRef);
        if (!freshSnap.exists) {
          throw new HttpsError("not-found", "Toplu mesaj taslağı bulunamadı.");
        }

        const freshDraft = freshSnap.data() || {};
        const status = clean(freshDraft.status, "draft").toLowerCase();
        const sendStatus = clean(freshDraft.sendStatus, "draft_ready").toLowerCase();

        if (status === "sent" || sendStatus === "sent") {
          return {
            state: "sent",
            draft: freshDraft,
            targetCount: Number(freshDraft.targetCount || 0),
            deliveredNotificationCount: Number(freshDraft.deliveredNotificationCount || 0),
          };
        }

        if (sendStatus === "sending" && !sendingIsStale(freshDraft)) {
          return {
            state: "sending",
            draft: freshDraft,
            targetCount: Number(freshDraft.targetCount || 0),
            deliveredNotificationCount: Number(freshDraft.deliveredNotificationCount || 0),
          };
        }

        if (!canSendDraft(freshDraft) && sendStatus !== "sending") {
          throw new HttpsError("failed-precondition", "Bu taslak gönderime hazır değil.");
        }

        if (freshDraft.consentOnly !== true) {
          throw new HttpsError("failed-precondition", "Toplu mesaj için izin kuralı zorunludur.");
        }

        const title = clean(freshDraft.title);
        const body = clean(freshDraft.message || freshDraft.body);
        if (!title || !body) {
          throw new HttpsError("failed-precondition", "Başlık ve mesaj içeriği zorunludur.");
        }

        transaction.set(draftRef, {
          sendStatus: "sending",
          sendAttemptId: attemptId,
          lastSendAttemptId: attemptId,
          sendStartedAt: admin.firestore.FieldValue.serverTimestamp(),
          sendStartedAtLocalIso: new Date().toISOString(),
          sendStartedBy: uid,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        return {
          state: "claimed",
          draft: freshDraft,
          targetCount: 0,
          deliveredNotificationCount: 0,
        };
      });

      if (claim.state === "sent") {
        const sentDraft = claim.draft || {};
        return {
          ok: true,
          draftId,
          attemptId: clean(sentDraft.sendAttemptId || sentDraft.lastSendAttemptId),
          sendStatus: "sent",
          alreadySent: true,
          targetCount: claim.targetCount,
          deliveredNotificationCount: claim.deliveredNotificationCount,
        };
      }

      if (claim.state === "sending") {
        const sendingDraft = claim.draft || {};
        return {
          ok: true,
          draftId,
          attemptId: clean(sendingDraft.sendAttemptId || sendingDraft.lastSendAttemptId),
          sendStatus: "sending",
          alreadySending: true,
          targetCount: claim.targetCount,
          deliveredNotificationCount: claim.deliveredNotificationCount,
        };
      }

      const claimedDraft = claim.draft || {};
      if (claimedDraft.consentOnly !== true) {
        throw new HttpsError("failed-precondition", "Toplu mesaj için izin kuralı zorunludur.");
      }

      const title = clean(claimedDraft.title);
      const body = clean(claimedDraft.message || claimedDraft.body);
      if (!title || !body) {
        throw new HttpsError("failed-precondition", "Başlık ve mesaj içeriği zorunludur.");
      }

      const businessId = clean(claimedDraft.businessId);
      const businessName = clean(claimedDraft.businessName, "İşletme");
      const nowIso = new Date().toISOString();
      const sendLogRef = db.collection("bulkMessageSendLogs").doc(attemptId);

      await sendLogRef.set({
        attemptId,
        draftId,
        businessId,
        businessName,
        status: "sending",
        senderUid: uid,
        title,
        targetCount: 0,
        deliveredNotificationCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAtLocalIso: nowIso,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        source: "send_bulk_message_draft",
      }, { merge: true });

      try {
        const targets = await collectTargetCustomers(claimedDraft);
        if (targets.length === 0) {
          await draftRef.set({
            sendStatus: "no_eligible_recipients",
            sendAttemptId: attemptId,
            lastSendAttemptId: attemptId,
            targetCount: 0,
            deliveredNotificationCount: 0,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            sentAtLocalIso: nowIso,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          await sendLogRef.set({
            status: "no_eligible_recipients",
            targetCount: 0,
            deliveredNotificationCount: 0,
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            completedAtLocalIso: nowIso,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          return {
            ok: true,
            draftId,
            attemptId,
            sendStatus: "no_eligible_recipients",
            alreadySent: false,
            alreadySending: false,
            targetCount: 0,
            deliveredNotificationCount: 0,
          };
        }

        let written = 0;
        let batch = db.batch();
        let opCount = 0;

        async function flush() {
          if (opCount === 0) return;
          await batch.commit();
          batch = db.batch();
          opCount = 0;
        }

        for (const target of targets) {
          const notificationId = `bulk_${safeDocId(draftId)}_${safeDocId(target.customerUid)}`;
          const notificationRef = db.collection("notifications").doc(notificationId);
          batch.set(notificationRef, {
            recipientUid: target.customerUid,
            targetUid: target.customerUid,
            customerUid: target.customerUid,
            userId: target.customerUid,
            targetScope: "user",
            businessId,
            businessName,
            type: "bulkMessage",
            notificationType: "bulkMessage",
            title,
            body,
            route: "customerNotifications",
            data: {
              bulkMessageDraftId: draftId,
              attemptId,
              audience: clean(claimedDraft.audience || claimedDraft.target),
              channel: clean(claimedDraft.channel),
              customerSegmentId: target.segmentId,
              sourceCustomerDocId: target.sourceDocId,
            },
            isRead: false,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            createdAtLocalIso: nowIso,
            source: "send_bulk_message_draft",
          });

          written++;
          opCount++;
          if (opCount >= 450) {
            await flush();
          }
        }

        await flush();

        await draftRef.set({
          sendStatus: "sent",
          status: "sent",
          sendAttemptId: attemptId,
          lastSendAttemptId: attemptId,
          targetCount: targets.length,
          deliveredNotificationCount: written,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          sentAtLocalIso: nowIso,
          sentBy: uid,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        await sendLogRef.set({
          status: "sent",
          targetCount: targets.length,
          deliveredNotificationCount: written,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          completedAtLocalIso: nowIso,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        return {
          ok: true,
          draftId,
          attemptId,
          sendStatus: "sent",
          alreadySent: false,
          alreadySending: false,
          targetCount: targets.length,
          deliveredNotificationCount: written,
        };
      } catch (error) {
        const message = error && error.message ? error.message : String(error);
        await draftRef.set({
          sendStatus: "send_failed",
          sendAttemptId: attemptId,
          lastSendAttemptId: attemptId,
          lastSendError: message.slice(0, 500),
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
          failedAtLocalIso: new Date().toISOString(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        await sendLogRef.set({
          status: "failed",
          errorMessage: message.slice(0, 500),
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
          failedAtLocalIso: new Date().toISOString(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        console.error("sendBulkMessageDraft failed:", {
          draftId,
          attemptId,
          message,
        });

        throw new HttpsError(
          "unavailable",
          "Toplu mesaj gönderimi tamamlanamadı. Daha sonra tekrar deneyin.",
        );
      }
    },
  );
}

module.exports = {
  registerBulkMessagingFunctions,
};
