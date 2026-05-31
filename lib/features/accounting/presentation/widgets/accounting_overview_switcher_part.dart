part of 'accounting_overview_panel.dart';

class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({required this.selected, required this.onChanged});

  final AccountingPeriodMode selected;
  final ValueChanged<AccountingPeriodMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<AccountingPeriodMode>(
        segments: const [
          ButtonSegment(
            value: AccountingPeriodMode.day,
            icon: Icon(Icons.today_rounded),
            label: Text('Günlük'),
          ),
          ButtonSegment(
            value: AccountingPeriodMode.month,
            icon: Icon(Icons.calendar_month_rounded),
            label: Text('Aylık'),
          ),
          ButtonSegment(
            value: AccountingPeriodMode.year,
            icon: Icon(Icons.event_available_rounded),
            label: Text('Yıllık'),
          ),
        ],
        selected: {selected},
        showSelectedIcon: false,
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(86, 40)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          ),
          visualDensity: VisualDensity.standard,
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
          ),
        ),
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

enum AccountingQuickAction {
  addSale,
  collectPayment,
  addExpense,
  openReports,
  openPermissions,
}

class _ActionData {
  const _ActionData({
    required this.title,
    required this.text,
    required this.icon,
    required this.color,
    required this.action,
  });

  final String title;
  final String text;
  final IconData icon;
  final Color color;
  final AccountingQuickAction action;
}
