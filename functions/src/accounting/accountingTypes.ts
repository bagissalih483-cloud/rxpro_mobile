export type AccountingSaleType = "service" | "product" | "mixed";
export type AccountingPaymentStatus = "unpaid" | "partial" | "collected";
export type AccountingPaymentMethod = "cash" | "bank" | "card" | "nfc";

export interface AccountingSaleItemInput {
  itemType: "service" | "product" | "manual";
  refId?: string | null;
  name: string;
  quantity: number;
  unitPriceKurus: number;
  lineTotalKurus: number;
}

export interface CreateManualSaleInput {
  businessId: string;
  customerId?: string | null;
  customerName?: string | null;
  customerPhone?: string | null;
  appointmentId?: string | null;
  source: string;
  saleType: AccountingSaleType;
  totalAmountKurus: number;
  paidAmountKurus: number;
  remainingAmountKurus: number;
  discountAmountKurus?: number;
  depositAmountKurus?: number;
  paymentStatus: AccountingPaymentStatus;
  paymentMethod: AccountingPaymentMethod;
  dueDate?: string | null;
  note?: string | null;
  items: AccountingSaleItemInput[];
  schemaVersion?: number;
}

export interface CollectPaymentInput {
  businessId: string;
  saleId: string;
  customerId?: string | null;
  amountKurus: number;
  method: AccountingPaymentMethod;
  collectedAt?: string | null;
  note?: string | null;
  source?: string | null;
}

export interface CreateExpenseInput {
  businessId: string;
  category: string;
  title: string;
  amountKurus: number;
  paymentMethod: AccountingPaymentMethod;
  status: "paid" | "pending";
  expenseDate?: string | null;
  vendorName?: string | null;
  note?: string | null;
  recurring?: boolean;
  recurrencePeriod?: "weekly" | "monthly" | "quarterly" | "yearly" | null;
  nextDate?: string | null;
}