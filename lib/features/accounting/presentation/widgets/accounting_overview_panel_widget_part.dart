part of 'accounting_overview_panel.dart';

class AccountingOverviewPanel extends StatefulWidget {
  const AccountingOverviewPanel({
    super.key,
    required this.businessName,
    required this.summary,
    required this.periodMode,
    required this.periodLabel,
    required this.onPeriodModeChanged,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.onCurrentPeriod,
    required this.onQuickAction,
  });

  final String businessName;
  final AccountingSummary summary;
  final AccountingPeriodMode periodMode;
  final String periodLabel;
  final ValueChanged<AccountingPeriodMode> onPeriodModeChanged;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;
  final VoidCallback onCurrentPeriod;
  final ValueChanged<AccountingQuickAction> onQuickAction;

  @override
  State<AccountingOverviewPanel> createState() =>
      _AccountingOverviewPanelState();

  static String money(int kurus) {
    final sign = kurus < 0 ? '-' : '';
    final value = (kurus.abs() / 100).toStringAsFixed(2).replaceAll('.', ',');
    return '$sign$value TL';
  }
}
