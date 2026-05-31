import 'accounting_permissions.dart';

class AccountingPermissionBridge {
  const AccountingPermissionBridge._();

  static Map<String, bool> normalize(Map<String, dynamic>? raw) {
    final input = raw ?? const <String, dynamic>{};

    bool has(String key) => input[key] == true;

    final financeRead =
        has(AccountingPermissionKeys.financeRead) ||
        has('viewFinance') ||
        has('canViewFinance') ||
        has('analysisRead') ||
        has('canViewAnalysis');

    final financeWrite =
        has(AccountingPermissionKeys.financeWrite) ||
        has('enterFinance') ||
        has('canManageFinance') ||
        has('canManageSales') ||
        has(AccountingPermissionKeys.saleProcess) ||
        has('paymentCollect');

    final saleProcess =
        financeWrite ||
        has(AccountingPermissionKeys.saleProcess) ||
        has(AccountingPermissionKeys.adisyonManage);

    final saleCancel =
        financeWrite ||
        has(AccountingPermissionKeys.saleCancel) ||
        has(AccountingPermissionKeys.adisyonCancel) ||
        has('canCancelSales');

    final paymentCollect =
        financeWrite ||
        has(AccountingPermissionKeys.paymentCollect) ||
        has(AccountingPermissionKeys.adisyonCollectPayment);

    final paymentRefund =
        financeWrite ||
        has(AccountingPermissionKeys.paymentRefund) ||
        has('canRefundPayments') ||
        has('refundPayments');

    final expenseWrite =
        has(AccountingPermissionKeys.expenseWrite) ||
        has('enterExpenses') ||
        has('canManageExpenses') ||
        has('expenseManage');

    final receivableManage =
        has(AccountingPermissionKeys.receivableManage) ||
        has('canManageReceivables') ||
        has('receivableWrite') ||
        has('paymentCollect');

    final reportExport =
        has(AccountingPermissionKeys.reportExport) ||
        has('canExportReports') ||
        has('reportWrite') ||
        has('financeExport');
    final reportsRead =
        financeRead || has(AccountingPermissionKeys.reportsRead) || reportExport;

    return <String, bool>{
      AccountingPermissionKeys.financeRead: financeRead,
      AccountingPermissionKeys.financeWrite: financeWrite,
      AccountingPermissionKeys.saleProcess: saleProcess,
      AccountingPermissionKeys.saleCancel: saleCancel,
      AccountingPermissionKeys.paymentCollect: paymentCollect,
      AccountingPermissionKeys.paymentRefund: paymentRefund,
      AccountingPermissionKeys.reportsRead: reportsRead,
      AccountingPermissionKeys.expenseWrite: expenseWrite,
      AccountingPermissionKeys.receivableManage: receivableManage,
      AccountingPermissionKeys.reportExport: reportExport,
    };
  }

  static bool hasPermission(
    Map<String, dynamic>? raw,
    String permissionKey, {
    bool owner = false,
  }) {
    if (owner) return true;
    return normalize(raw)[permissionKey] == true;
  }

  static List<String> enabledLabels(
    Map<String, dynamic>? raw, {
    bool owner = false,
  }) {
    if (owner) {
      return AccountingPermissionKeys.all
          .map((key) => AccountingPermissionLabels.labels[key] ?? key)
          .toList();
    }

    final normalized = normalize(raw);
    return AccountingPermissionKeys.all
        .where((key) => normalized[key] == true)
        .map((key) => AccountingPermissionLabels.labels[key] ?? key)
        .toList();
  }

  static Map<String, bool> ownerDefaults() {
    return <String, bool>{
      for (final key in AccountingPermissionKeys.all) key: true,
    };
  }

  static Map<String, bool> cashierDefaults() {
    return <String, bool>{
      AccountingPermissionKeys.financeRead: true,
      AccountingPermissionKeys.financeWrite: true,
      AccountingPermissionKeys.saleProcess: true,
      AccountingPermissionKeys.saleCancel: false,
      AccountingPermissionKeys.paymentCollect: true,
      AccountingPermissionKeys.paymentRefund: false,
      AccountingPermissionKeys.reportsRead: false,
      AccountingPermissionKeys.expenseWrite: false,
      AccountingPermissionKeys.receivableManage: true,
      AccountingPermissionKeys.reportExport: false,
    };
  }

  static Map<String, bool> accountingDefaults() {
    return <String, bool>{
      AccountingPermissionKeys.financeRead: true,
      AccountingPermissionKeys.financeWrite: true,
      AccountingPermissionKeys.saleProcess: true,
      AccountingPermissionKeys.saleCancel: true,
      AccountingPermissionKeys.paymentCollect: true,
      AccountingPermissionKeys.paymentRefund: true,
      AccountingPermissionKeys.reportsRead: true,
      AccountingPermissionKeys.expenseWrite: true,
      AccountingPermissionKeys.receivableManage: true,
      AccountingPermissionKeys.reportExport: true,
    };
  }

  static Map<String, bool> viewOnlyDefaults() {
    return <String, bool>{
      AccountingPermissionKeys.financeRead: true,
      AccountingPermissionKeys.financeWrite: false,
      AccountingPermissionKeys.saleProcess: false,
      AccountingPermissionKeys.saleCancel: false,
      AccountingPermissionKeys.paymentCollect: false,
      AccountingPermissionKeys.paymentRefund: false,
      AccountingPermissionKeys.reportsRead: true,
      AccountingPermissionKeys.expenseWrite: false,
      AccountingPermissionKeys.receivableManage: false,
      AccountingPermissionKeys.reportExport: false,
    };
  }
}
