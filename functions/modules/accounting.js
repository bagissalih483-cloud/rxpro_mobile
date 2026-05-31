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

  function firstNonEmpty(values) {
    for (const value of values) {
      const clean = text(value);
      if (clean) return clean;
    }
    return "";
  }

  function amountKurusOfAppointment(data) {
    const raw =
      data.servicePrice ??
      data.price ??
      data.amount ??
      data.totalPrice ??
      data.finalPrice;
    if (typeof raw === "number" && Number.isFinite(raw)) {
      return Math.max(0, Math.round(raw * 100));
    }

    const normalized = text(raw).replace(/\./g, "").replace(",", ".");
    const value = Number(normalized);
    if (!Number.isFinite(value)) return 0;
    return Math.max(0, Math.round(value * 100));
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

    if (paidAmountKurus > totalAmountKurus) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Tahsil edilen tutar satis tutarindan buyuk olamaz.",
      );
    }

    const remainingAmountKurus = Math.max(totalAmountKurus - paidAmountKurus, 0);
    const paymentStatus =
      remainingAmountKurus === 0
        ? "paid"
        : paidAmountKurus > 0
          ? "partial"
          : text(payload.paymentStatus, "unpaid");

    return {
      ...payload,
      businessId,
      source,
      saleType,
      totalAmountKurus,
      paidAmountKurus,
      remainingAmountKurus,
      processStatus: text(payload.processStatus, "processed"),
      paymentStatus,
      customerPhone: normalizePhone(payload.customerPhone),
      items: normalizeSaleItems(payload.items),
      schemaVersion: 1,
    };
  }

  function validateEnsureAppointmentAdisyon(data) {
    const payload = data || {};
    const appointmentData =
      payload.appointmentData && typeof payload.appointmentData === "object"
        ? payload.appointmentData
        : {};

    return {
      businessId: requiredString(payload.businessId, "businessId"),
      appointmentId: requiredString(payload.appointmentId, "appointmentId"),
      appointmentData,
      staffId: text(payload.staffId),
      staffName: text(payload.staffName),
      actorName: text(payload.actorName),
      schemaVersion: 2,
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

  function validateCollectInstallmentPayment(data) {
    const payload = data || {};
    return {
      ...payload,
      businessId: requiredString(payload.businessId, "businessId"),
      saleId: requiredString(payload.saleId, "saleId"),
      installmentId: requiredString(payload.installmentId, "installmentId"),
      amountKurus: positiveKurus(payload.amountKurus, "amountKurus"),
      method: requiredString(payload.method, "method"),
      note: text(payload.note),
      schemaVersion: 2,
    };
  }

  function validateCancelSale(data) {
    const payload = data || {};
    return {
      businessId: requiredString(payload.businessId, "businessId"),
      saleId: requiredString(payload.saleId, "saleId"),
      cancelReason: requiredString(payload.cancelReason, "cancelReason"),
      schemaVersion: 2,
    };
  }

  function validateRefundSale(data) {
    const payload = data || {};
    return {
      businessId: requiredString(payload.businessId, "businessId"),
      saleId: requiredString(payload.saleId, "saleId"),
      amountKurus: positiveKurus(payload.amountKurus, "amountKurus"),
      refundReason: requiredString(payload.refundReason, "refundReason"),
      method: text(payload.method, "unknown"),
      schemaVersion: 2,
    };
  }

  function validateProcessSale(data) {
    const payload = data || {};
    const paymentStatus = requiredString(payload.paymentStatus, "paymentStatus");
    const allowedStatuses = [
      "paid",
      "partial",
      "openAccount",
      "installment",
      "free",
    ];
    if (!allowedStatuses.includes(paymentStatus)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Gecersiz adisyon odeme sonucu.",
      );
    }

    const installmentCount = Math.round(Number(payload.installmentCount || 0));
    if (
      paymentStatus === "installment" &&
      (!Number.isFinite(installmentCount) ||
        installmentCount < 2 ||
        installmentCount > 24)
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Taksit sayisi 2 ile 24 arasinda olmalidir.",
      );
    }

    return {
      ...payload,
      businessId: requiredString(payload.businessId, "businessId"),
      saleId: requiredString(payload.saleId, "saleId"),
      paymentStatus,
      paymentMethod: text(payload.paymentMethod, "unknown"),
      paidAmountKurus: nonNegativeKurus(payload.paidAmountKurus),
      installmentCount,
      installmentPeriod: text(payload.installmentPeriod, "monthly"),
      dueDate: payload.dueDate || null,
      note: text(payload.note),
      schemaVersion: 2,
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
    const aliases = {
      saleProcess: [
        "saleProcess",
        "financeWrite",
        "adisyon.manage",
        "adisyon.edit",
      ],
      paymentCollect: [
        "paymentCollect",
        "financeWrite",
        "receivableManage",
        "adisyon.collectPayment",
      ],
      saleCancel: [
        "saleCancel",
        "financeWrite",
        "canManageFinance",
        "canCancelSales",
        "adisyon.cancel",
      ],
      paymentRefund: [
        "paymentRefund",
        "financeWrite",
        "canRefundPayments",
        "refundPayments",
        "adisyon.refund",
      ],
      reportsRead: [
        "reportsRead",
        "financeRead",
        "reportExport",
        "adisyon.report",
      ],
      appointmentsWrite: [
        "appointmentsWrite",
        "appointmentManage",
        "canManageAppointments",
        "completeAssignedAppointments",
        "appointmentStartFinish",
      ],
      expenseWrite: ["expenseWrite", "financeWrite"],
      financeWrite: ["financeWrite", "canManageFinance"],
    };
    const acceptedKeys = aliases[permissionKey] || [permissionKey];

    if (
      permissions.financeAdmin === true ||
      acceptedKeys.some((key) => permissions[key] === true || staff[key] === true)
    ) {
      return;
    }

    throw new functions.https.HttpsError(
      "permission-denied",
      "Bu muhasebe islemi icin yetkiniz yok.",
    );
  }

  function paymentPermissionFor(status) {
    if (status === "paid" || status === "partial") return "paymentCollect";
    return "saleProcess";
  }

  function processedAmounts(input, sale) {
    const total = nonNegativeKurus(sale.totalAmountKurus);
    let paid = Math.min(input.paidAmountKurus, total);

    if (input.paymentStatus === "paid") {
      paid = total;
    } else if (
      input.paymentStatus === "free" ||
      input.paymentStatus === "openAccount" ||
      input.paymentStatus === "installment"
    ) {
      paid = Math.min(paid, total);
    }

    if (input.paymentStatus === "partial" && (paid <= 0 || paid >= total)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Kismi odemede tahsil edilen tutar toplamdan kucuk ve sifirdan buyuk olmalidir.",
      );
    }

    if (input.paymentStatus === "free") {
      return { paid: 0, remaining: 0 };
    }

    const remaining = Math.max(total - paid, 0);
    if (input.paymentStatus === "openAccount" && remaining <= 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Acik hesap icin kalan tutar olmalidir.",
      );
    }
    if (input.paymentStatus === "installment" && remaining <= 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Taksitli satis icin kalan tutar olmalidir.",
      );
    }

    return { paid, remaining };
  }

  function dueDateFromInput(value) {
    if (!value) return null;
    if (typeof value === "string") {
      const date = new Date(value);
      if (!Number.isNaN(date.getTime())) {
        return admin.firestore.Timestamp.fromDate(date);
      }
    }
    if (
      typeof value === "object" &&
      value !== null &&
      value.toDate &&
      typeof value.toDate === "function"
    ) {
      return value;
    }
    if (typeof value === "object" && value !== null && value._seconds !== undefined) {
      return new admin.firestore.Timestamp(value._seconds, value._nanoseconds || 0);
    }
    return null;
  }

  function installmentDueDate(firstDueDate, index, period) {
    const base = firstDueDate.toDate();
    const date = new Date(base.getTime());
    if (period === "weekly") {
      date.setDate(date.getDate() + 7 * (index - 1));
    } else {
      date.setMonth(date.getMonth() + (index - 1));
    }
    return admin.firestore.Timestamp.fromDate(date);
  }

  function installmentAmount(total, count, index) {
    const base = Math.floor(total / count);
    const remainder = total - base * count;
    return base + (index <= remainder ? 1 : 0);
  }

  exportsTarget.accountingCreateManualSale = functions.https.onCall(
    async (data, context) => {
      const uid = signedInUid(context);
      const input = validateCreateManualSale(data);
      await assertBusinessPermission(uid, input.businessId, "saleProcess");

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

  exportsTarget.accountingEnsureAppointmentAdisyon = functions.https.onCall(
    async (data, context) => {
      const uid = signedInUid(context);
      const input = validateEnsureAppointmentAdisyon(data);
      await assertBusinessPermission(uid, input.businessId, "appointmentsWrite");

      const saleId = `appointment_${input.appointmentId}`;
      const saleRef = db.doc(
        `businesses/${input.businessId}/accountingSales/${saleId}`,
      );
      const now = admin.firestore.FieldValue.serverTimestamp();

      let created = false;
      await db.runTransaction(async (transaction) => {
        const existing = await transaction.get(saleRef);
        if (existing.exists) return;

        const appointment = input.appointmentData || {};
        const totalAmountKurus = amountKurusOfAppointment(appointment);
        const serviceName = firstNonEmpty([
          appointment.serviceName,
          appointment.title,
          "Hizmet",
        ]);
        const customerId = firstNonEmpty([
          appointment.customerId,
          appointment.userId,
          appointment.clientId,
        ]);
        const customerName = firstNonEmpty([
          appointment.customerName,
          appointment.clientName,
        ]);
        const customerPhone = normalizePhone(
          firstNonEmpty([
            appointment.customerPhone,
            appointment.phone,
            appointment.clientPhone,
          ]),
        );
        const staffId = firstNonEmpty([
          input.staffId,
          appointment.businessStaffId,
          appointment.staffId,
          appointment.linkedStaffId,
        ]);
        const staffName = firstNonEmpty([
          input.staffName,
          appointment.staffName,
          input.actorName,
        ]);
        const serviceId = firstNonEmpty([appointment.serviceId]);

        transaction.set(
          saleRef,
          {
            saleId,
            businessId: input.businessId,
            appointmentId: input.appointmentId,
            sourceAppointmentId: input.appointmentId,
            source: "appointment",
            sourceType: "appointment",
            saleType: "service",
            customerId,
            customerName,
            customerPhone,
            staffId,
            staffName,
            serviceId,
            serviceName,
            items: [
              {
                itemType: "service",
                type: "service",
                refId: serviceId,
                name: serviceName,
                quantity: 1,
                unitPriceKurus: totalAmountKurus,
                lineTotalKurus: totalAmountKurus,
                totalAmountKurus,
              },
            ],
            totalAmountKurus,
            paidAmountKurus: 0,
            remainingAmountKurus: totalAmountKurus,
            discountAmountKurus: 0,
            depositAmountKurus: 0,
            processStatus: "pending",
            paymentStatus: "unpaid",
            paymentMethod: "unknown",
            appointmentDate: appointment.appointmentDate || null,
            appointmentTime: appointment.appointmentTime || null,
            createdAt: now,
            updatedAt: now,
            createdByUid: uid,
            createdByName: input.actorName,
            schemaVersion: 2,
          },
          { merge: true },
        );
        created = true;
      });

      return {
        ok: true,
        saleId,
        created,
      };
    },
  );

  exportsTarget.accountingProcessSale = functions.https.onCall(
    async (data, context) => {
      const uid = signedInUid(context);
      const input = validateProcessSale(data);
      await assertBusinessPermission(
        uid,
        input.businessId,
        paymentPermissionFor(input.paymentStatus),
      );

      const saleRef = db.doc(
        `businesses/${input.businessId}/accountingSales/${input.saleId}`,
      );
      const paymentRef = db.doc(
        `businesses/${input.businessId}/accountingPayments/${input.saleId}_initial`,
      );
      const receivableRef = db.doc(
        `businesses/${input.businessId}/accountingReceivables/${input.saleId}`,
      );
      const activityRef = db
        .collection(`businesses/${input.businessId}/businessActivityLogs`)
        .doc();
      const now = admin.firestore.FieldValue.serverTimestamp();

      await db.runTransaction(async (transaction) => {
        const saleSnap = await transaction.get(saleRef);
        if (!saleSnap.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "Adisyon bulunamadi.",
          );
        }

        const sale = saleSnap.data() || {};
        if (sale.processStatus === "processed") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Bu adisyon daha once islenmis.",
          );
        }
        if (sale.processStatus === "cancelled" || sale.processStatus === "voided") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Iptal veya gecersiz adisyon islenemez.",
          );
        }

        const total = nonNegativeKurus(sale.totalAmountKurus);
        if (total <= 0 && input.paymentStatus !== "free") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Adisyon tutari gecersiz.",
          );
        }

        const { paid, remaining } = processedAmounts(input, sale);
        const dueDate = dueDateFromInput(input.dueDate);
        if (
          (input.paymentStatus === "openAccount" ||
            input.paymentStatus === "installment") &&
          !dueDate
        ) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            "Vadeli veya taksitli islem icin vade tarihi gerekir.",
          );
        }

        transaction.set(
          saleRef,
          {
            processStatus: "processed",
            paymentStatus: input.paymentStatus,
            paymentMethod: input.paymentMethod,
            paidAmountKurus: paid,
            remainingAmountKurus: remaining,
            dueDate,
            processedAt: now,
            processedByUid: uid,
            note: input.note || sale.note || null,
            updatedAt: now,
            schemaVersion: 2,
          },
          { merge: true },
        );

        if (paid > 0 && input.paymentStatus !== "free") {
          transaction.set(
            paymentRef,
            {
              paymentId: paymentRef.id,
              saleId: input.saleId,
              businessId: input.businessId,
              customerId: sale.customerId || null,
              amountKurus: paid,
              method: input.paymentMethod,
              collectedAt: now,
              collectedByUid: uid,
              note: input.note || null,
              source: "sale_processing",
              createdAt: now,
              updatedAt: now,
              schemaVersion: 2,
            },
            { merge: true },
          );
        } else {
          transaction.delete(paymentRef);
        }

        if (
          ["partial", "openAccount", "installment"].includes(
            input.paymentStatus,
          ) &&
          remaining > 0
        ) {
          transaction.set(
            receivableRef,
            {
              receivableId: receivableRef.id,
              businessId: input.businessId,
              saleId: input.saleId,
              customerId: sale.customerId || null,
              customerName: sale.customerName || null,
              customerPhone: sale.customerPhone || null,
              totalAmountKurus: total,
              paidAmountKurus: paid,
              remainingAmountKurus: remaining,
              dueDate,
              status: input.paymentStatus === "partial" ? "partial" : "open",
              source: input.paymentStatus,
              createdAt: now,
              updatedAt: now,
              schemaVersion: 2,
            },
            { merge: true },
          );
        } else {
          transaction.delete(receivableRef);
        }

        for (let i = 1; i <= 24; i += 1) {
          const installmentRef = db.doc(
            `businesses/${input.businessId}/accountingInstallments/${input.saleId}_${i}`,
          );
          if (
            input.paymentStatus !== "installment" ||
            i > input.installmentCount ||
            remaining <= 0 ||
            !dueDate
          ) {
            transaction.delete(installmentRef);
          } else {
            transaction.set(
              installmentRef,
              {
                installmentId: installmentRef.id,
                businessId: input.businessId,
                saleId: input.saleId,
                customerId: sale.customerId || null,
                customerName: sale.customerName || null,
                installmentNo: i,
                amountKurus: installmentAmount(
                  remaining,
                  input.installmentCount,
                  i,
                ),
                paidAmountKurus: 0,
                dueDate: installmentDueDate(dueDate, i, input.installmentPeriod),
                status: "pending",
                createdByUid: uid,
                createdAt: now,
                updatedAt: now,
                schemaVersion: 2,
              },
              { merge: true },
            );
          }
        }

        transaction.set(activityRef, {
          businessId: input.businessId,
          actorUid: uid,
          action: "accounting.sale_processed",
          targetType: "accountingSale",
          targetId: input.saleId,
          before: {
            processStatus: sale.processStatus || null,
            paymentStatus: sale.paymentStatus || null,
            paidAmountKurus: nonNegativeKurus(sale.paidAmountKurus),
            remainingAmountKurus: nonNegativeKurus(sale.remainingAmountKurus),
          },
          after: {
            processStatus: "processed",
            paymentStatus: input.paymentStatus,
            paidAmountKurus: paid,
            remainingAmountKurus: remaining,
          },
          source: "cloudFunction",
          createdAt: now,
          schemaVersion: 2,
        });
      });

      return {
        ok: true,
        saleId: input.saleId,
        paymentStatus: input.paymentStatus,
      };
    },
  );

  exportsTarget.accountingCollectPayment = functions.https.onCall(
    async (data, context) => {
      const uid = signedInUid(context);
      const input = validateCollectPayment(data);
      await assertBusinessPermission(uid, input.businessId, "paymentCollect");

      const now = admin.firestore.FieldValue.serverTimestamp();
      const paymentRef = db
        .collection(`businesses/${input.businessId}/accountingPayments`)
        .doc();
      const saleRef = db.doc(
        `businesses/${input.businessId}/accountingSales/${input.saleId}`,
      );
      const receivableRef = db.doc(
        `businesses/${input.businessId}/accountingReceivables/${input.saleId}`,
      );
      const activityRef = db
        .collection(`businesses/${input.businessId}/businessActivityLogs`)
        .doc();

      await db.runTransaction(async (transaction) => {
        const saleSnap = await transaction.get(saleRef);
        if (!saleSnap.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "Tahsilat icin adisyon bulunamadi.",
          );
        }

        const sale = saleSnap.data() || {};
        if (sale.processStatus === "cancelled" || sale.processStatus === "voided") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Iptal veya gecersiz adisyona tahsilat girilemez.",
          );
        }

        const total = nonNegativeKurus(sale.totalAmountKurus);
        const paidBefore = nonNegativeKurus(sale.paidAmountKurus);
        const remainingBefore =
          nonNegativeKurus(sale.remainingAmountKurus) ||
          Math.max(total - paidBefore, 0);

        if (remainingBefore <= 0) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Bu adisyonun kalan tahsilati yok.",
          );
        }
        if (input.amountKurus > remainingBefore) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            "Tahsilat tutari kalan bakiyeden buyuk olamaz.",
          );
        }

        const paidAfter = Math.min(paidBefore + input.amountKurus, total);
        const remainingAfter = Math.max(total - paidAfter, 0);
        const paymentStatus = remainingAfter === 0 ? "paid" : "partial";

        transaction.set(
          paymentRef,
          {
            ...input,
            paymentId: paymentRef.id,
            amountKurus: input.amountKurus,
            collectedByUid: uid,
            collectedAt: now,
            createdAt: now,
            updatedAt: now,
            source: "receivable_collection",
            schemaVersion: 2,
          },
          { merge: true },
        );

        transaction.set(
          saleRef,
          {
            processStatus: "processed",
            paymentStatus,
            paidAmountKurus: paidAfter,
            remainingAmountKurus: remainingAfter,
            updatedAt: now,
            schemaVersion: 2,
          },
          { merge: true },
        );

        transaction.set(
          receivableRef,
          {
            receivableId: receivableRef.id,
            businessId: input.businessId,
            saleId: input.saleId,
            customerId: sale.customerId || null,
            customerName: sale.customerName || null,
            customerPhone: sale.customerPhone || null,
            totalAmountKurus: total,
            paidAmountKurus: paidAfter,
            remainingAmountKurus: remainingAfter,
            status: remainingAfter === 0 ? "paid" : "partial",
            updatedAt: now,
            schemaVersion: 2,
          },
          { merge: true },
        );

        transaction.set(activityRef, {
          businessId: input.businessId,
          actorUid: uid,
          action: "accounting.payment_collected",
          targetType: "accountingSale",
          targetId: input.saleId,
          before: {
            paidAmountKurus: paidBefore,
            remainingAmountKurus: remainingBefore,
          },
          after: {
            paidAmountKurus: paidAfter,
            remainingAmountKurus: remainingAfter,
          },
          source: "cloudFunction",
          createdAt: now,
          schemaVersion: 2,
        });
      });

      return {
        ok: true,
        paymentId: paymentRef.id,
      };
    },
  );

  exportsTarget.accountingCollectInstallmentPayment = functions.https.onCall(
    async (data, context) => {
      const uid = signedInUid(context);
      const input = validateCollectInstallmentPayment(data);
      await assertBusinessPermission(uid, input.businessId, "paymentCollect");

      const now = admin.firestore.FieldValue.serverTimestamp();
      const saleRef = db.doc(
        `businesses/${input.businessId}/accountingSales/${input.saleId}`,
      );
      const installmentRef = db.doc(
        `businesses/${input.businessId}/accountingInstallments/${input.installmentId}`,
      );
      const receivableRef = db.doc(
        `businesses/${input.businessId}/accountingReceivables/${input.saleId}`,
      );
      const paymentRef = db
        .collection(`businesses/${input.businessId}/accountingPayments`)
        .doc();
      const activityRef = db
        .collection(`businesses/${input.businessId}/businessActivityLogs`)
        .doc();

      await db.runTransaction(async (transaction) => {
        const [saleSnap, installmentSnap] = await Promise.all([
          transaction.get(saleRef),
          transaction.get(installmentRef),
        ]);

        if (!saleSnap.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "Taksit tahsilati icin adisyon bulunamadi.",
          );
        }
        if (!installmentSnap.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "Taksit kaydi bulunamadi.",
          );
        }

        const sale = saleSnap.data() || {};
        const installment = installmentSnap.data() || {};
        if (installment.saleId !== input.saleId) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Taksit kaydi bu adisyona bagli degil.",
          );
        }
        if (sale.processStatus === "cancelled" || sale.processStatus === "voided") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Iptal veya gecersiz adisyona taksit tahsilati girilemez.",
          );
        }
        if (installment.status === "cancelled") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Iptal taksite tahsilat girilemez.",
          );
        }

        const installmentAmountTotal = nonNegativeKurus(installment.amountKurus);
        const installmentPaidBefore = nonNegativeKurus(
          installment.paidAmountKurus,
        );
        const installmentRemaining =
          installmentAmountTotal - installmentPaidBefore;
        if (installmentRemaining <= 0 || installment.status === "paid") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Bu taksit zaten kapanmis.",
          );
        }
        if (input.amountKurus > installmentRemaining) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            "Tahsilat tutari taksit bakiyesinden buyuk olamaz.",
          );
        }

        const total = nonNegativeKurus(sale.totalAmountKurus);
        const paidBefore = nonNegativeKurus(sale.paidAmountKurus);
        const remainingBefore =
          nonNegativeKurus(sale.remainingAmountKurus) ||
          Math.max(total - paidBefore, 0);
        if (input.amountKurus > remainingBefore) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            "Tahsilat tutari kalan adisyon bakiyesinden buyuk olamaz.",
          );
        }

        const installmentPaidAfter = installmentPaidBefore + input.amountKurus;
        const installmentStatus =
          installmentPaidAfter >= installmentAmountTotal ? "paid" : "partial";
        const paidAfter = Math.min(paidBefore + input.amountKurus, total);
        const remainingAfter = Math.max(total - paidAfter, 0);
        const paymentStatus = remainingAfter === 0 ? "paid" : "installment";

        transaction.set(
          paymentRef,
          {
            paymentId: paymentRef.id,
            saleId: input.saleId,
            businessId: input.businessId,
            installmentId: input.installmentId,
            customerId: sale.customerId || null,
            amountKurus: input.amountKurus,
            method: input.method,
            collectedAt: now,
            collectedByUid: uid,
            note: input.note || null,
            source: "installment_collection",
            createdAt: now,
            updatedAt: now,
            schemaVersion: 2,
          },
          { merge: true },
        );

        transaction.set(
          installmentRef,
          {
            paidAmountKurus: installmentPaidAfter,
            status: installmentStatus,
            paidAt: installmentStatus === "paid" ? now : null,
            updatedAt: now,
            schemaVersion: 2,
          },
          { merge: true },
        );

        transaction.set(
          saleRef,
          {
            processStatus: "processed",
            paymentStatus,
            paidAmountKurus: paidAfter,
            remainingAmountKurus: remainingAfter,
            updatedAt: now,
            schemaVersion: 2,
          },
          { merge: true },
        );

        transaction.set(
          receivableRef,
          {
            receivableId: receivableRef.id,
            businessId: input.businessId,
            saleId: input.saleId,
            customerId: sale.customerId || null,
            customerName: sale.customerName || null,
            customerPhone: sale.customerPhone || null,
            totalAmountKurus: total,
            paidAmountKurus: paidAfter,
            remainingAmountKurus: remainingAfter,
            status: remainingAfter === 0 ? "paid" : "partial",
            updatedAt: now,
            schemaVersion: 2,
          },
          { merge: true },
        );

        transaction.set(activityRef, {
          businessId: input.businessId,
          actorUid: uid,
          action: "accounting.installment_payment_collected",
          targetType: "accountingInstallment",
          targetId: input.installmentId,
          before: {
            salePaidAmountKurus: paidBefore,
            saleRemainingAmountKurus: remainingBefore,
            installmentPaidAmountKurus: installmentPaidBefore,
          },
          after: {
            salePaidAmountKurus: paidAfter,
            saleRemainingAmountKurus: remainingAfter,
            installmentPaidAmountKurus: installmentPaidAfter,
          },
          source: "cloudFunction",
          createdAt: now,
          schemaVersion: 2,
        });
      });

      return {
        ok: true,
        paymentId: paymentRef.id,
        installmentId: input.installmentId,
      };
    },
  );

  exportsTarget.accountingCancelSale = functions.https.onCall(
    async (data, context) => {
      const uid = signedInUid(context);
      const input = validateCancelSale(data);
      await assertBusinessPermission(uid, input.businessId, "saleCancel");

      const now = admin.firestore.FieldValue.serverTimestamp();
      const saleRef = db.doc(
        `businesses/${input.businessId}/accountingSales/${input.saleId}`,
      );
      const receivableRef = db.doc(
        `businesses/${input.businessId}/accountingReceivables/${input.saleId}`,
      );
      const activityRef = db
        .collection(`businesses/${input.businessId}/businessActivityLogs`)
        .doc();
      const installmentRefs = Array.from({ length: 24 }, (_, index) =>
        db.doc(
          `businesses/${input.businessId}/accountingInstallments/${input.saleId}_${index + 1}`,
        ),
      );

      await db.runTransaction(async (transaction) => {
        const saleSnap = await transaction.get(saleRef);
        const receivableSnap = await transaction.get(receivableRef);
        const installmentSnaps = [];
        for (const ref of installmentRefs) {
          installmentSnaps.push(await transaction.get(ref));
        }

        if (!saleSnap.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "Iptal edilecek adisyon bulunamadi.",
          );
        }

        const sale = saleSnap.data() || {};
        if (sale.processStatus === "cancelled") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Bu adisyon zaten iptal edilmis.",
          );
        }

        const paidBefore = nonNegativeKurus(sale.paidAmountKurus);
        if (paidBefore > 0) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Tahsilat alinmis adisyon iptali icin iade/duzeltme akisi gerekir.",
          );
        }

        transaction.set(
          saleRef,
          {
            processStatus: "cancelled",
            paymentStatus: "cancelled",
            remainingAmountKurus: 0,
            cancelReason: input.cancelReason,
            cancelledAt: now,
            cancelledByUid: uid,
            updatedAt: now,
            schemaVersion: 2,
          },
          { merge: true },
        );

        if (receivableSnap.exists) {
          transaction.set(
            receivableRef,
            {
              receivableId: receivableRef.id,
              businessId: input.businessId,
              saleId: input.saleId,
              status: "cancelled",
              remainingAmountKurus: 0,
              cancelReason: input.cancelReason,
              cancelledAt: now,
              cancelledByUid: uid,
              updatedAt: now,
              schemaVersion: 2,
            },
            { merge: true },
          );
        }

        installmentSnaps.forEach((snap, index) => {
          if (!snap.exists) return;
          transaction.set(
            installmentRefs[index],
            {
              status: "cancelled",
              cancelReason: input.cancelReason,
              cancelledAt: now,
              cancelledByUid: uid,
              updatedAt: now,
              schemaVersion: 2,
            },
            { merge: true },
          );
        });

        transaction.set(activityRef, {
          businessId: input.businessId,
          actorUid: uid,
          action: "accounting.sale_cancelled",
          targetType: "accountingSale",
          targetId: input.saleId,
          before: {
            processStatus: sale.processStatus || null,
            paymentStatus: sale.paymentStatus || null,
            paidAmountKurus: paidBefore,
            remainingAmountKurus: nonNegativeKurus(sale.remainingAmountKurus),
          },
          after: {
            processStatus: "cancelled",
            paymentStatus: "cancelled",
            paidAmountKurus: paidBefore,
            remainingAmountKurus: 0,
          },
          reason: input.cancelReason,
          source: "cloudFunction",
          createdAt: now,
          schemaVersion: 2,
        });
      });

      return {
        ok: true,
        saleId: input.saleId,
      };
    },
  );

  exportsTarget.accountingRefundSale = functions.https.onCall(
    async (data, context) => {
      const uid = signedInUid(context);
      const input = validateRefundSale(data);
      await assertBusinessPermission(uid, input.businessId, "paymentRefund");

      const now = admin.firestore.FieldValue.serverTimestamp();
      const saleRef = db.doc(
        `businesses/${input.businessId}/accountingSales/${input.saleId}`,
      );
      const receivableRef = db.doc(
        `businesses/${input.businessId}/accountingReceivables/${input.saleId}`,
      );
      const refundRef = db
        .collection(`businesses/${input.businessId}/accountingRefunds`)
        .doc();
      const paymentRef = db
        .collection(`businesses/${input.businessId}/accountingPayments`)
        .doc();
      const activityRef = db
        .collection(`businesses/${input.businessId}/businessActivityLogs`)
        .doc();

      await db.runTransaction(async (transaction) => {
        const saleSnap = await transaction.get(saleRef);
        const receivableSnap = await transaction.get(receivableRef);

        if (!saleSnap.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "Iade edilecek adisyon bulunamadi.",
          );
        }

        const sale = saleSnap.data() || {};
        if (sale.processStatus === "cancelled" || sale.processStatus === "voided") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Iptal veya gecersiz adisyona iade girilemez.",
          );
        }
        if (sale.paymentStatus === "refunded") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Bu adisyon zaten iade edilmis.",
          );
        }

        const paidBefore = nonNegativeKurus(sale.paidAmountKurus);
        if (paidBefore <= 0) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Iade icin tahsil edilmis tutar bulunmuyor.",
          );
        }
        if (input.amountKurus !== paidBefore) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            "Ilk guvenli fazda sadece tam iade desteklenir.",
          );
        }

        transaction.set(
          refundRef,
          {
            refundId: refundRef.id,
            businessId: input.businessId,
            saleId: input.saleId,
            customerId: sale.customerId || null,
            amountKurus: input.amountKurus,
            method: input.method,
            reason: input.refundReason,
            refundedByUid: uid,
            refundedAt: now,
            createdAt: now,
            updatedAt: now,
            schemaVersion: 2,
          },
          { merge: true },
        );

        transaction.set(
          paymentRef,
          {
            paymentId: paymentRef.id,
            saleId: input.saleId,
            businessId: input.businessId,
            customerId: sale.customerId || null,
            amountKurus: -input.amountKurus,
            method: input.method,
            collectedAt: now,
            collectedByUid: uid,
            note: input.refundReason,
            source: "refund",
            refundId: refundRef.id,
            createdAt: now,
            updatedAt: now,
            schemaVersion: 2,
          },
          { merge: true },
        );

        transaction.set(
          saleRef,
          {
            processStatus: "processed",
            paymentStatus: "refunded",
            paidAmountKurus: 0,
            remainingAmountKurus: 0,
            refundedAmountKurus: input.amountKurus,
            refundReason: input.refundReason,
            refundedAt: now,
            refundedByUid: uid,
            updatedAt: now,
            schemaVersion: 2,
          },
          { merge: true },
        );

        if (receivableSnap.exists) {
          transaction.set(
            receivableRef,
            {
              status: "cancelled",
              remainingAmountKurus: 0,
              cancelReason: "refund",
              updatedAt: now,
              schemaVersion: 2,
            },
            { merge: true },
          );
        }

        transaction.set(activityRef, {
          businessId: input.businessId,
          actorUid: uid,
          action: "accounting.sale_refunded",
          targetType: "accountingSale",
          targetId: input.saleId,
          before: {
            paymentStatus: sale.paymentStatus || null,
            paidAmountKurus: paidBefore,
            remainingAmountKurus: nonNegativeKurus(sale.remainingAmountKurus),
          },
          after: {
            paymentStatus: "refunded",
            paidAmountKurus: 0,
            remainingAmountKurus: 0,
            refundedAmountKurus: input.amountKurus,
          },
          reason: input.refundReason,
          source: "cloudFunction",
          createdAt: now,
          schemaVersion: 2,
        });
      });

      return {
        ok: true,
        saleId: input.saleId,
        refundAmountKurus: input.amountKurus,
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
