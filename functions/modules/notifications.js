"use strict";

function registerNotificationFunctions({
  exportsTarget,
  onDocumentCreated,
  onSchedule,
  admin,
  db,
}) {
  function rxClean(value, fallback = "") {
    if (value === undefined || value === null) return fallback;
    return String(value).trim() || fallback;
  }
  
  function rxStatusIsCancelled(data) {
    const status = rxClean(
      data.status || data.appointmentStatus || data.state || data.bookingStatus
    ).toLowerCase();
  
    return status.includes("cancel") ||
      status.includes("iptal") ||
      data.isCancelled === true;
  }
  
  function rxShortPushBody(type, body) {
    const t = rxClean(type).toLowerCase();
  
    if (t.includes("postpone") || t.includes("ertele")) {
      return "Randevunuz için yeni saat önerildi.";
    }
  
    if (t.includes("cancel") || t.includes("iptal")) {
      return "Detay için dokunun.";
    }
  
    if (t.includes("reminder")) {
      return "Gelecek misiniz?";
    }
  
    const cleanBody = rxClean(body, "Detay için dokunun.");
    return cleanBody.length > 90 ? cleanBody.slice(0, 87) + "..." : cleanBody;
  }
  
  async function rxResolveBusinessTargetUids(data) {
    const uids = new Set();
  
    const rawBusinessId = rxClean(data.businessId);
    if (!rawBusinessId) return [];
  
    const businessIdCandidates = new Set();
    businessIdCandidates.add(rawBusinessId);
  
    let strippedBusinessUid = "";
    if (rawBusinessId.startsWith("business_")) {
      strippedBusinessUid = rxClean(rawBusinessId.replace(/^business_/, ""));
      if (strippedBusinessUid) {
        businessIdCandidates.add(strippedBusinessUid);
        uids.add(strippedBusinessUid);
      }
    }
  
    // Bazı projelerde businessId doğrudan işletme kullanıcısının UID'si gibi tutuluyor.
    if (!rawBusinessId.startsWith("business_") && rawBusinessId.length >= 12) {
      uids.add(rawBusinessId);
    }
  
    // businesses/{businessId} dokümanlarından owner alanlarını çöz.
    for (const bid of Array.from(businessIdCandidates)) {
      try {
        const businessDoc = await db.collection("businesses").doc(bid).get();
        if (businessDoc.exists) {
          const b = businessDoc.data() || {};
          [
            b.ownerUid,
            b.ownerId,
            b.businessOwnerUid,
            b.userId,
            b.uid,
            b.createdBy,
            b.adminUid,
            b.managerUid
          ].forEach((v) => {
            const uid = rxClean(v);
            if (uid) uids.add(uid);
          });
        }
      } catch (err) {
        console.error("RX_41I_D2_BUSINESS_DOC_LOOKUP_ERROR", {
          businessId: bid,
          error: err && err.message ? err.message : String(err)
        });
      }
    }
  
    // users koleksiyonunda işletme id alanlarına göre ara.
    const fields = [
      "businessId",
      "ownedBusinessId",
      "activeBusinessId",
      "selectedBusinessId"
    ];
  
    for (const bid of Array.from(businessIdCandidates)) {
      for (const field of fields) {
        try {
          const snap = await db.collection("users")
            .where(field, "==", bid)
            .limit(10)
            .get();
  
          snap.forEach((doc) => {
            if (doc.id) uids.add(doc.id);
            const u = doc.data() || {};
            [
              u.uid,
              u.ownerUid,
              u.userId
            ].forEach((v) => {
              const uid = rxClean(v);
              if (uid) uids.add(uid);
            });
          });
        } catch (err) {
          console.error("RX_41I_D2_USER_BUSINESS_LOOKUP_ERROR", {
            field,
            businessId: bid,
            error: err && err.message ? err.message : String(err)
          });
        }
      }
    }
  
    return Array.from(uids).filter(Boolean);
  }
  
  async function rxResolveNotificationTargetUids(data) {
    const uids = new Set();
  
    const directUid = rxClean(
      data.recipientUid ||
      data.targetUid ||
      data.userId ||
      data.customerUid ||
      data.receiverUid ||
      data.clientUid
    );
  
    if (directUid) {
      uids.add(directUid);
      return Array.from(uids).filter(Boolean);
    }
  
    const targetScope = rxClean(data.targetScope).toLowerCase();
    const businessId = rxClean(data.businessId);
  
    if (businessId && (targetScope === "business" || !targetScope)) {
      const businessUids = await rxResolveBusinessTargetUids(data);
      businessUids.forEach((uid) => {
        if (uid) uids.add(uid);
      });
    }
  
    return Array.from(uids).filter(Boolean);
  }
  
  async function rxCollectFcmTokensForUids(uids) {
    const db = admin.firestore();
    const tokens = new Set();
  
    for (const uid of uids) {
      try {
        const userDoc = await db.collection("users").doc(uid).get();
  
        if (userDoc.exists) {
          const userData = userDoc.data() || {};
          const legacyToken = rxClean(userData.fcmToken);
          if (legacyToken && userData.fcmTokenActive !== false && (!userData.fcmTokenOwnerUid || userData.fcmTokenOwnerUid === uid)) {
            tokens.add(legacyToken);
          }
        }
  
        const tokenSnap = await db.collection("users")
          .doc(uid)
          .collection("fcmTokens")
          .where("active", "==", true)
          .get();
  
        tokenSnap.forEach((doc) => {
          const t = doc.data() || {};
          const token = rxClean(t.token || doc.id);
          if (token && t.active === true && (!t.ownerUid || t.ownerUid === uid)) tokens.add(token);
        });
      } catch (error) {
        console.error("token collect failed", uid, error);
      }
    }
  
    return Array.from(tokens);
  }

  function rxPreferenceKeyForNotification(data) {
    const type = rxClean(data.type).toLowerCase();
    const route = rxClean(data.route).toLowerCase();

    if (
      type.includes("appointment") ||
      type.includes("randevu") ||
      route.includes("appointment")
    ) {
      return "appointmentReminders";
    }

    if (
      type.includes("message") ||
      type.includes("mesaj") ||
      route.includes("message")
    ) {
      return "messages";
    }

    if (
      type.includes("campaign") ||
      type.includes("kampanya") ||
      type.includes("bulk") ||
      route.includes("campaign")
    ) {
      return "campaigns";
    }

    return "system";
  }

  async function rxFilterUidsByNotificationPreferences(uids, data) {
    const preferenceKey = rxPreferenceKeyForNotification(data);
    const allowed = [];

    for (const uid of uids || []) {
      const cleanUid = rxClean(uid);
      if (!cleanUid) continue;

      try {
        const prefDoc = await db.collection("notificationPreferences")
          .doc(cleanUid)
          .get();

        if (!prefDoc.exists) {
          allowed.push(cleanUid);
          continue;
        }

        const prefs = prefDoc.data() || {};
        if (prefs.pushEnabled === false || prefs[preferenceKey] === false) {
          console.log("RX_PUSH_SKIPPED_BY_PREFERENCES", {
            uid: cleanUid,
            preferenceKey
          });
          continue;
        }

        allowed.push(cleanUid);
      } catch (error) {
        console.error("RX_PUSH_PREFERENCE_LOOKUP_FAILED", {
          uid: cleanUid,
          preferenceKey,
          error: error && error.message ? error.message : String(error)
        });
        allowed.push(cleanUid);
      }
    }

    return allowed;
  }
  
  function rxPushData(notificationId, data) {
    const innerData = data.data && typeof data.data === "object" ? data.data : {};
  
    return {
      notificationId: String(notificationId),
      title: rxClean(data.title, "RxPro"),
      body: rxShortPushBody(data.type, data.body),
      type: rxClean(data.type, "general"),
      route: rxClean(data.route),
      businessId: rxClean(data.businessId),
      businessName: rxClean(data.businessName),
      targetScope: rxClean(data.targetScope),
      recipientUid: rxClean(data.recipientUid),
      targetUid: rxClean(data.targetUid),
      userId: rxClean(data.userId),
      customerUid: rxClean(data.customerUid),
      receiverUid: rxClean(data.receiverUid),
      appointmentId: rxClean(innerData.appointmentId || data.appointmentId),
      payload: JSON.stringify(innerData).slice(0, 3500)
    };
  }
  
  
  async function rxDisableDeadFcmTokenForUids(uids, badToken, reason) {
    const db = admin.firestore();
    const token = rxClean(badToken);
    if (!token) return;
  
    for (const uid of uids || []) {
      const cleanUid = rxClean(uid);
      if (!cleanUid) continue;
  
      try {
        const userRef = db.collection("users").doc(cleanUid);
        const userDoc = await userRef.get();
  
        if (userDoc.exists) {
          const userData = userDoc.data() || {};
          if (rxClean(userData.fcmToken) === token) {
            await userRef.set({
              fcmTokenActive: false,
              fcmTokenDisabledReason: reason || "invalid",
              fcmTokenDisabledAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
          }
        }
  
        const tokenSnap = await userRef.collection("fcmTokens")
          .where("active", "==", true)
          .get();
        const batch = db.batch();
        let count = 0;
  
        tokenSnap.forEach((doc) => {
          const data = doc.data() || {};
          const storedToken = rxClean(data.token || doc.id);
  
          if (storedToken === token) {
            batch.set(doc.ref, {
              active: false,
              disabledReason: reason || "invalid",
              disabledAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
            count++;
          }
        });
  
        if (count > 0) {
          await batch.commit();
          console.log("FCM_DEAD_TOKEN_DISABLED_41H3", {
            uid: cleanUid,
            count,
            reason: reason || "invalid"
          });
        }
      } catch (error) {
        console.error("FCM_DEAD_TOKEN_DISABLE_FAILED_41H3", cleanUid, error);
      }
    }
  }
  exportsTarget.sendPushOnNotificationCreated = onDocumentCreated(
    {
      document: "notifications/{notificationId}",
      region: "europe-west1"
    },
    async (event) => {
      const snap = event.data;
      if (!snap) return;
  
      const data = snap.data() || {};
      const notificationId = event.params.notificationId;
  
      const title = rxClean(data.title, "RxPro");
      const body = rxShortPushBody(data.type, data.body);
  
      try {
        const targetUids = await rxResolveNotificationTargetUids(data);
        const pushTargetUids = await rxFilterUidsByNotificationPreferences(
          targetUids,
          data,
        );
        const tokens = await rxCollectFcmTokensForUids(pushTargetUids);
      console.log("RX_41I_D2_TOKEN_COLLECT_SUMMARY", {
        targetUids,
        pushTargetUids,
        tokenCount: tokens.length
      });
  
        console.log("sendPushOnNotificationCreated target", {
          notificationId,
          type: data.type,
          recipientUid: data.recipientUid || data.targetUid || data.userId || data.customerUid || data.receiverUid || data.clientUid || "",
          targetScope: data.targetScope || "",
          businessId: data.businessId || "",
          targetUidCount: targetUids.length,
        targetUids: targetUids,
          pushTargetUidCount: pushTargetUids.length,
          tokenCount: tokens.length
        });
  
        if (tokens.length === 0) {
          await snap.ref.set({
            pushStatus: "no-token",
            pushtargetUidCount: targetUids.length,
        targetUids: targetUids,
            pushTargetUidCount: pushTargetUids.length,
            pushSkippedByPreferenceCount: Math.max(
              0,
              targetUids.length - pushTargetUids.length,
            ),
            pushTokenCount: 0,
            pushCheckedAt: admin.firestore.FieldValue.serverTimestamp()
          }, { merge: true });
          return;
        }
  
        let successCount = 0;
        let failureCount = 0;
  
        for (let i = 0; i < tokens.length; i += 500) {
          const chunk = tokens.slice(i, i + 500);
  
          const response = await admin.messaging().sendEachForMulticast({
            tokens: chunk,
            notification: { title, body },
            data: rxPushData(notificationId, data),
            android: {
              priority: "high",
              notification: {
                channelId: "rxpro_high_importance",
                clickAction: "FLUTTER_NOTIFICATION_CLICK"
              }
            },
            apns: {
              payload: {
                aps: { sound: "default" }
              }
            }
          });
  
          successCount += response.successCount;
          failureCount += response.failureCount;
  
          if (response.failureCount > 0 && Array.isArray(response.responses)) {
            for (let j = 0; j < response.responses.length; j++) {
              const r = response.responses[j];
              if (!r.success) {
                const code = r.error && r.error.code ? r.error.code : "";
                const message = r.error && r.error.message ? r.error.message : "";
                const badToken = chunk[j] || "";
  
                console.log("FCM_DELIVERY_ERROR_DETAIL_41H2", {
                  index: j,
                  code,
                  message,
                  tokenTail: badToken ? badToken.slice(-10) : ""
                });
  
                if (
                  code === "messaging/registration-token-not-registered" ||
                  code === "messaging/invalid-registration-token"
                ) {
                  await rxDisableDeadFcmTokenForUids(targetUids, badToken, code);
                }
              }
            }
          }
        }
  
        await snap.ref.set({
          pushStatus: failureCount === 0 ? "sent" : "partial",
          pushtargetUidCount: targetUids.length,
        targetUids: targetUids,
          pushTargetUidCount: pushTargetUids.length,
          pushSkippedByPreferenceCount: Math.max(
            0,
            targetUids.length - pushTargetUids.length,
          ),
          pushTokenCount: tokens.length,
          pushSuccessCount: successCount,
          pushFailureCount: failureCount,
          pushSentAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
  
        console.log("sendPushOnNotificationCreated result", {
          notificationId,
          successCount,
          failureCount
        });
      } catch (error) {
        console.error("sendPushOnNotificationCreated failed", error);
  
        await snap.ref.set({
          pushStatus: "error",
          pushError: error && error.message ? error.message : String(error),
          pushErrorAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      }
    }
  );
  
  exportsTarget.sendAppointmentReminderOneHour = onSchedule(
    {
      schedule: "every 5 minutes",
      region: "europe-west1",
      timeZone: "Europe/Istanbul"
    },
    async () => {
      const db = admin.firestore();
      const now = Date.now();
      const lower = new Date(now + 55 * 60 * 1000);
      const upper = new Date(now + 65 * 60 * 1000);
  
      const snap = await db.collection("appointments")
        .where("startAt", ">=", admin.firestore.Timestamp.fromDate(lower))
        .where("startAt", "<=", admin.firestore.Timestamp.fromDate(upper))
        .limit(100)
        .get();
  
      const batch = db.batch();
      let count = 0;
  
      for (const doc of snap.docs) {
        const data = doc.data() || {};
  
        if (data.reminder1hSent === true) continue;
        if (rxStatusIsCancelled(data)) continue;
  
        const customerUid = rxClean(
          data.customerUid || data.customerId || data.userId || data.uid || data.clientUid
        );
        if (!customerUid) continue;
  
        const businessId = rxClean(data.businessId);
        const businessName = rxClean(data.businessName, "İşletme");
        const serviceName = rxClean(data.serviceName, "Randevu");
        const dateText = rxClean(data.dateText || data.appointmentDate);
        const timeText = rxClean(data.timeText || data.appointmentTime);
  
        const notificationRef = db.collection("notifications").doc();
  
        batch.set(notificationRef, {
          recipientUid: customerUid,
          targetScope: "user",
          targetUid: customerUid,
          customerUid,
          businessId,
          businessName,
          type: "appointment_reminder_1h",
          title: "Randevunuza 1 saat kaldı",
          body: "Gelecek misiniz?",
          route: "customerAppointments",
          data: {
            appointmentId: doc.id,
            requiresArrivalConfirmation: true,
            serviceName,
            dateText,
            timeText
          },
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAtIso: new Date().toISOString(),
          source: "scheduled_appointment_reminder_1h"
        });
  
        batch.set(doc.ref, {
          reminder1hSent: true,
          reminder1hSentAt: admin.firestore.FieldValue.serverTimestamp(),
          arrivalQuestionSent: true,
          customerArrivalStatus: "pending",
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
  
        count++;
      }
  
      if (count > 0) {
        await batch.commit();
      }
  
      console.log("sendAppointmentReminderOneHour completed", { count });
    }
  );
  
}

module.exports = {
  registerNotificationFunctions,
};
