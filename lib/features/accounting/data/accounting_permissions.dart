class AccountingPermissionKeys {
  const AccountingPermissionKeys._();

  static const financeRead = 'financeRead';
  static const financeWrite = 'financeWrite';
  static const expenseWrite = 'expenseWrite';
  static const receivableManage = 'receivableManage';
  static const reportExport = 'reportExport';

  static const all = <String>[
    financeRead,
    financeWrite,
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
    AccountingPermissionKeys.expenseWrite: 'Gider işlemleri',
    AccountingPermissionKeys.receivableManage: 'Alacak ve vade yönetimi',
    AccountingPermissionKeys.reportExport: 'Rapor/PDF dışa aktarma',
  };
}
