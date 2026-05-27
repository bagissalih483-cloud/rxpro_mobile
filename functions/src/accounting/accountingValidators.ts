import * as functions from "firebase-functions";
import {
  CollectPaymentInput,
  CreateExpenseInput,
  CreateManualSaleInput,
} from "./accountingTypes";

export function assertSignedIn(context: functions.https.CallableContext): string {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Oturum bulunamadı."
    );
  }
  return uid;
}

export function assertString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} zorunludur.`
    );
  }
  return value.trim();
}

export function assertPositiveNumber(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} sıfırdan büyük olmalıdır.`
    );
  }
  return Math.round(value);
}

export function normalizePhone(input?: string | null): string | null {
  if (!input) return null;

  let digits = input.replace(/[^0-9]/g, "");
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

  return input.trim();
}

export function validateCreateManualSale(data: any): CreateManualSaleInput {
  const businessId = assertString(data.businessId, "businessId");
  const saleType = assertString(
    data.saleType,
    "saleType"
  ) as CreateManualSaleInput["saleType"];
  const source = assertString(data.source ?? "manual", "source");
  const totalAmountKurus = assertPositiveNumber(
    data.totalAmountKurus,
    "totalAmountKurus"
  );
  const paidAmountKurus = Math.max(
    0,
    Math.round(Number(data.paidAmountKurus ?? 0))
  );
  const remainingAmountKurus = Math.max(
    0,
    Math.round(Number(data.remainingAmountKurus ?? 0))
  );

  if (!Array.isArray(data.items) || data.items.length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "En az bir satış kalemi gerekir."
    );
  }

  if (paidAmountKurus > totalAmountKurus && remainingAmountKurus > 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Tahsil edilen tutar satış tutarından büyük olamaz."
    );
  }

  return {
    ...data,
    businessId,
    source,
    saleType,
    totalAmountKurus,
    paidAmountKurus,
    remainingAmountKurus,
    customerPhone: normalizePhone(data.customerPhone),
    schemaVersion: 1,
  };
}

export function validateCollectPayment(data: any): CollectPaymentInput {
  return {
    ...data,
    businessId: assertString(data.businessId, "businessId"),
    saleId: assertString(data.saleId, "saleId"),
    amountKurus: assertPositiveNumber(data.amountKurus, "amountKurus"),
    method: assertString(
      data.method,
      "method"
    ) as CollectPaymentInput["method"],
  };
}

export function validateCreateExpense(data: any): CreateExpenseInput {
  return {
    ...data,
    businessId: assertString(data.businessId, "businessId"),
    category: assertString(data.category, "category"),
    title: assertString(data.title, "title"),
    amountKurus: assertPositiveNumber(data.amountKurus, "amountKurus"),
    paymentMethod: assertString(
      data.paymentMethod,
      "paymentMethod"
    ) as CreateExpenseInput["paymentMethod"],
    status: (data.status ?? "pending") as CreateExpenseInput["status"],
  };
}
