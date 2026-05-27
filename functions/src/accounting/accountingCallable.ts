import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  assertSignedIn,
  validateCollectPayment,
  validateCreateExpense,
  validateCreateManualSale,
} from "./accountingValidators";

const db = admin.firestore();

async function assertBusinessPermission(
  uid: string,
  businessId: string,
  permissionKey: string
): Promise<void> {
  const businessRef = db.doc(`businesses/${businessId}`);
  const businessSnap = await businessRef.get();

  if (!businessSnap.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "Kurumsal hesap bulunamadı."
    );
  }

  const business = businessSnap.data() ?? {};
  const ownerUid = business.ownerUid ?? business.uid ?? business.createdByUid;

  if (ownerUid === uid) return;

  const staffQuery = await db
    .collection("businessStaff")
    .where("businessId", "==", businessId)
    .where("isActive", "!=", false)
    .limit(50)
    .get();

  const staffDoc = staffQuery.docs.find((doc) => {
    const data = doc.data() ?? {};
    return data.linkedUid === uid || data.staffUid === uid || data.userId === uid;
  });

  if (!staffDoc) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Bu kurumsal hesap için yetkiniz yok."
    );
  }

  const staff = staffDoc.data() ?? {};
  const permissions = staff.permissions ?? {};

  if (
    permissions[permissionKey] === true ||
    permissions.financeAdmin === true ||
    staff[permissionKey] === true
  ) {
    return;
  }

  throw new functions.https.HttpsError(
    "permission-denied",
    "Bu muhasebe işlemi için yetkiniz yok."
  );
}

export const accountingCreateManualSale = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    const uid = assertSignedIn(context);
    const input = validateCreateManualSale(data);
    await assertBusinessPermission(uid, input.businessId, "financeWrite");

    const now = admin.firestore.FieldValue.serverTimestamp();
    const saleRef = db
      .collection(`businesses/${input.businessId}/accountingSales`)
      .doc();

    const batch = db.batch();

    batch.set(saleRef, {
      ...input,
      saleId: saleRef.id,
      createdByUid: uid,
      createdAt: now,
      updatedAt: now,
    });

    if (input.paidAmountKurus > 0) {
      const paymentRef = db
        .collection(`businesses/${input.businessId}/accountingPayments`)
        .doc();

      batch.set(paymentRef, {
        paymentId: paymentRef.id,
        saleId: saleRef.id,
        businessId: input.businessId,
        customerId: input.customerId ?? null,
        amountKurus: input.paidAmountKurus,
        method: input.paymentMethod,
        collectedAt: now,
        collectedByUid: uid,
        source: "manualSale",
        createdAt: now,
      });
    }

    if (input.remainingAmountKurus > 0) {
      const receivableRef = db
        .collection(`businesses/${input.businessId}/accountingReceivables`)
        .doc();

      batch.set(receivableRef, {
        receivableId: receivableRef.id,
        saleId: saleRef.id,
        businessId: input.businessId,
        customerId: input.customerId ?? null,
        customerName: input.customerName ?? null,
        customerPhone: input.customerPhone ?? null,
        amountKurus: input.remainingAmountKurus,
        dueDate: input.dueDate ?? null,
        status: "open",
        createdAt: now,
        updatedAt: now,
      });
    }

    await batch.commit();

    return {
      ok: true,
      saleId: saleRef.id,
    };
  });

export const accountingCollectPayment = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    const uid = assertSignedIn(context);
    const input = validateCollectPayment(data);
    await assertBusinessPermission(uid, input.businessId, "financeWrite");

    const now = admin.firestore.FieldValue.serverTimestamp();
    const paymentRef = db
      .collection(`businesses/${input.businessId}/accountingPayments`)
      .doc();

    await paymentRef.set({
      ...input,
      paymentId: paymentRef.id,
      collectedByUid: uid,
      collectedAt: now,
      createdAt: now,
    });

    return {
      ok: true,
      paymentId: paymentRef.id,
    };
  });

export const accountingCreateExpense = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    const uid = assertSignedIn(context);
    const input = validateCreateExpense(data);
    await assertBusinessPermission(uid, input.businessId, "expenseWrite");

    const now = admin.firestore.FieldValue.serverTimestamp();
    const expenseRef = db
      .collection(`businesses/${input.businessId}/accountingExpenses`)
      .doc();

    const batch = db.batch();

    batch.set(expenseRef, {
      ...input,
      expenseId: expenseRef.id,
      createdByUid: uid,
      createdAt: now,
      updatedAt: now,
    });

    if (input.recurring === true) {
      const recurringRef = db
        .collection(`businesses/${input.businessId}/accountingRecurringExpenses`)
        .doc();

      batch.set(recurringRef, {
        recurringExpenseId: recurringRef.id,
        sourceExpenseId: expenseRef.id,
        businessId: input.businessId,
        category: input.category,
        title: input.title,
        amountKurus: input.amountKurus,
        paymentMethod: input.paymentMethod,
        recurrencePeriod: input.recurrencePeriod ?? "monthly",
        nextDate: input.nextDate ?? null,
        active: true,
        createdByUid: uid,
        createdAt: now,
        updatedAt: now,
      });
    }

    await batch.commit();

    return {
      ok: true,
      expenseId: expenseRef.id,
    };
  });
