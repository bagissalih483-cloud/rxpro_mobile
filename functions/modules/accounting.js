"use strict";

function registerAccountingFunctions({ exportsTarget, functions, admin, db }) {
  function signedInUid(context) {
    const uid = context && context.auth && context.auth.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Oturum bulunamadi.",
      );
    }
    return uid;
  }

  function text(value, fallback = "") {
    if (value === undefined || value === null) return fallback;
    const clean = String(value).trim();
    return clean || fallback;
  }

  function requiredString(value, field) {
    const clean = text(value);
    if (!clean) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `${field} zorunludur.`,
      );
    }
    return clean;
  }

  function positiveKurus(value, field) {
    const amount = Number(value);
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `${field} sifirdan buyuk olmalidir.`,
      );
    }
    return Math.round(amount);
  }

  function nonNegativeKurus(value) {
    const amount = Number(value || 0);
    if (!Number.isFinite(amount) || amount < 0) return 0;
    return Math.round(amount);
  }

  function normalizePhone(input) {
    const raw = text(input);
    if (!raw) return null;

    let digits = raw.replace(/[^0-9]/g, "");
    if (digits.startsWith("0090")) {
      digits = digits.substring(4);
    } else if (digits.startsWith("90") && digits.length === 12) {
      digits = digits.substring(2);
    } else if (digits.startsWith("0") && digits.length === 11) {
      digits = digits.substring(1);
    }

    if (digits.length === 10 && digits.startsWith("5")) {
      return `+90${digits}`;
    }

    return raw;
  }

  function normalizeSaleItems(items) {
    if (!Array.isArray(items) || items.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "En az bir satis kalemi gerekir.",
      );
    }

    return items.map((item, index) => {
      const source = item || {};
      return {
        ...source,
        itemType: requiredString(
          source.itemType || "manual",
          `items[${index}].itemType`,
        ),
        name: requiredString(source.name, `items[${index}].name`),
        quantity: positiveKurus(source.quantity, `items[${index}].quantity`),
        unitPriceKurus: nonNegativeKurus(source.unitPriceKurus),
        lineTotalKurus: positiveKurus(
          source.lineTotalKurus,
          `items[${index}].lineTotalKurus`,
        ),
      };
    });
  }

  function validateCreateManualSale(data) {
    const payload = data || {};
    const businessId = requiredString(payload.businessId, "businessId");
    const saleType = requiredString(payload.saleType, "saleType");
    const source = requiredString(payload.source || "manual", "source");
    const totalAmountKurus = positiveKurus(
      payload.totalAmountKurus,
      "totalAmountKurus",
    );
    const paidAmountKurus = nonNegativeKurus(payload.paidAmountKurus);
    const remainingAmountKurus = nonNegativeKurus(
      payload.remainingAmountKurus,
    );

    if (paidAmountKurus > totalAmountKurus && remainingAmountKurus > 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Tahsil edilen tutar satis tutarindan buyuk olamaz.",
      );
    }

    return {
      ...payload,
      businessId,
      source,
      saleType,
      totalAmountKurus,
      paidAmountKurus,
      remainingAmountKurus,
      customerPhone: normalizePhone(payload.customerPhone),
      items: normalizeSaleItems(payload.items),
      schemaVersion: 1,
    };
  }

  function validateCollectPayment(data) {
    const payload = data || {};
    return {
      ...payload,
      businessId: requiredString(payload.businessId, "businessId"),
      saleId: requiredString(payload.saleId, "saleId"),
      amountKurus: positiveKurus(payload.amountKurus, "amountKurus"),
      method: requiredString(payload.method, "method"),
      schemaVersion: 1,
    };
  }

  function validateCreateExpense(data) {
    const payload = data || {};
    return {
      ...payload,
      businessId: requiredString(payload.businessId, "businessId"),
      category: requiredString(payload.category, "category"),
      title: requiredString(payload.title, "title"),
      amountKurus: positiveKurus(payload.amountKurus, "amountKurus"),
      paymentMethod: requiredString(payload.paymentMethod, "paymentMethod"),
      status: text(payload.status, "pending"),
      schemaVersion: 1,
    };
  }

  function valueMatchesUid(value, uid) {
    if (Array.isArray(value)) {
      return value.some((item) => valueMatchesUid(item, uid));
    }

    return text(value).toLowerCase() === text(uid).toLowerCase();
  }

  async function assertBusinessPermission(uid, businessId, permissionKey) {
    const businessRef = db.doc(`businesses/${businessId}`);
    const businessSnap = await businessRef.get();

    if (!businessSnap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Kurumsal hesap bulunamadi.",
      );
    }

    const business = businessSnap.data() || {};
    const ownerFields = [
      business.ownerUid,
      business.ownerId,
      business.businessOwnerUid,
      business.userId,
      business.uid,
      business.createdBy,
      business.createdByUid,
      business.adminUid,
      business.managerUid,
      business.ownerUids,
      business.adminUids,
      business.managerUids,
      business.authorizedUids,
    ];

    if (ownerFields.some((value) => valueMatchesUid(value, uid))) {
      return;
    }

    const staffQuery = await db
      .collection("businessStaff")
      .where("businessId", "==", businessId)
      .limit(100)
      .get();

    const staffDoc = staffQuery.docs.find((doc) => {
      const staff = doc.data() || {};
      if (staff.isActive === false) return false;

      return [
        staff.linkedUid,
        staff.staffUid,
        staff.userId,
        staff.uid,
        staff.userUid,
      ].some((value) => valueMatchesUid(value, uid));
    });

    if (!staffDoc) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Bu kurumsal hesap icin yetkiniz yok.",
      );
    }

    const staff = staffDoc.data() || {};
    const permissions = staff.permissions || {};

    if (
      permissions[permissionKey] === true ||
      permissions.financeAdmin === true ||
      staff[permissionKey] === true
    ) {
      return;
    }

    throw new functions.https.HttpsError(
      "permission-denied",
      "Bu muhasebe islemi icin yetkiniz yok.",
    );
  }

  exportsTarget.accountingCreateManualSale = functions.https.onCall(
    async (data, context) => {
      const uid = signedInUid(context);
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
          customerId: input.customerId || null,
          amountKurus: input.paidAmountKurus,
          method: input.paymentMethod,
          collectedAt: now,
          collectedByUid: uid,
          source: "manualSale",
          createdAt: now,
          schemaVersion: 1,
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
          customerId: input.customerId || null,
          customerName: input.customerName || null,
          customerPhone: input.customerPhone || null,
          amountKurus: input.remainingAmountKurus,
          dueDate: input.dueDate || null,
          status: "open",
          createdAt: now,
          updatedAt: now,
          schemaVersion: 1,
        });
      }

      await batch.commit();

      return {
        ok: true,
        saleId: saleRef.id,
      };
    },
  );

  exportsTarget.accountingCollectPayment = functions.https.onCall(
    async (data, context) => {
      const uid = signedInUid(context);
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
    },
  );

  exportsTarget.accountingCreateExpense = functions.https.onCall(
    async (data, context) => {
      const uid = signedInUid(context);
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
          .collection(
            `businesses/${input.businessId}/accountingRecurringExpenses`,
          )
          .doc();

        batch.set(recurringRef, {
          recurringExpenseId: recurringRef.id,
          sourceExpenseId: expenseRef.id,
          businessId: input.businessId,
          category: input.category,
          title: input.title,
          amountKurus: input.amountKurus,
          paymentMethod: input.paymentMethod,
          recurrencePeriod: input.recurrencePeriod || "monthly",
          nextDate: input.nextDate || null,
          active: true,
          createdByUid: uid,
          createdAt: now,
          updatedAt: now,
          schemaVersion: 1,
        });
      }

      await batch.commit();

      return {
        ok: true,
        expenseId: expenseRef.id,
      };
    },
  );
}

module.exports = {
  registerAccountingFunctions,
};
