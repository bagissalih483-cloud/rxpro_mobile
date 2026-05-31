class AccountingPermissionKeys {
  const AccountingPermissionKeys._();

  static const financeRead = 'financeRead';
  static const financeWrite = 'financeWrite';
  static const adisyonView = 'adisyon.view';
  static const adisyonManage = 'adisyon.edit';
  static const adisyonCollectPayment = 'adisyon.collectPayment';
  static const adisyonCancel = 'adisyon.cancel';
  static const saleProcess = 'saleProcess';
  static const saleCancel = 'saleCancel';
  static const paymentCollect = 'paymentCollect';
  static const paymentRefund = 'paymentRefund';
  static const reportsRead = 'reportsRead';
  static const expenseWrite = 'expenseWrite';
  static const receivableManage = 'receivableManage';
  static const reportExport = 'reportExport';

  static const all = <String>[
    financeRead,
    financeWrite,
    adisyonView,
    adisyonManage,
    adisyonCollectPayment,
    adisyonCancel,
    saleProcess,
    saleCancel,
    paymentCollect,
    paymentRefund,
    reportsRead,
    expenseWrite,
    receivableManage,
    reportExport,
  ];
}

class AccountingPermissionLabels {
  const AccountingPermissionLabels._();

  static const labels = <String, String>{
    AccountingPermissionKeys.financeRead: 'Muhasebe görüntüleme',
    AccountingPermissionKeys.financeWrite: 'Satış ve tahsilat işlemleri',
    AccountingPermissionKeys.adisyonView: 'Adisyonları görür',
    AccountingPermissionKeys.adisyonManage: 'Adisyon yönetir',
    AccountingPermissionKeys.adisyonCollectPayment: 'Ödeme alır',
    AccountingPermissionKeys.adisyonCancel: 'Adisyon iptal eder',
    AccountingPermissionKeys.saleProcess: 'Adisyon işler',
    AccountingPermissionKeys.saleCancel: 'Satış/adisyon iptal eder',
    AccountingPermissionKeys.paymentCollect: 'Tahsilat alır',
    AccountingPermissionKeys.paymentRefund: 'İade/düzeltme yapar',
    AccountingPermissionKeys.reportsRead: 'Finans raporlarını görür',
    AccountingPermissionKeys.expenseWrite: 'Gider işlemleri',
    AccountingPermissionKeys.receivableManage: 'Alacak ve vade yönetimi',
    AccountingPermissionKeys.reportExport: 'Rapor/PDF dışa aktarma',
  };
}
