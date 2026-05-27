class AccountingFirestorePaths {
  const AccountingFirestorePaths._();

  static String businessRoot(String businessId) {
    return 'businesses/$businessId';
  }

  static String sales(String businessId) {
    return '${businessRoot(businessId)}/accountingSales';
  }

  static String sale(String businessId, String saleId) {
    return '${sales(businessId)}/$saleId';
  }

  static String payments(String businessId) {
    return '${businessRoot(businessId)}/accountingPayments';
  }

  static String payment(String businessId, String paymentId) {
    return '${payments(businessId)}/$paymentId';
  }

  static String receivables(String businessId) {
    return '${businessRoot(businessId)}/accountingReceivables';
  }

  static String receivable(String businessId, String receivableId) {
    return '${receivables(businessId)}/$receivableId';
  }

  static String expenses(String businessId) {
    return '${businessRoot(businessId)}/accountingExpenses';
  }

  static String expense(String businessId, String expenseId) {
    return '${expenses(businessId)}/$expenseId';
  }

  static String recurringExpenses(String businessId) {
    return '${businessRoot(businessId)}/accountingRecurringExpenses';
  }

  static String recurringExpense(String businessId, String recurringExpenseId) {
    return '${recurringExpenses(businessId)}/$recurringExpenseId';
  }

  static String reports(String businessId) {
    return '${businessRoot(businessId)}/accountingReports';
  }

  static String report(String businessId, String reportId) {
    return '${reports(businessId)}/$reportId';
  }
}
