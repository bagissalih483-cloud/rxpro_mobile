import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/responsive/rx_adaptive_modal.dart';
import 'package:rxpro_mobile/core/responsive/rx_breakpoints.dart';
import 'package:rxpro_mobile/core/responsive/rx_keyboard_shortcuts.dart';
import 'package:rxpro_mobile/core/session/app_session_scope.dart';

import 'data/accounting_repository.dart';
import 'data/callable_accounting_repository.dart';
import 'models/accounting_models.dart';
import 'pages/accounting_expenses_page.dart';
import 'pages/accounting_permissions_page.dart';
import 'pages/accounting_receivables_page.dart';
import 'pages/accounting_reports_page.dart';
import 'presentation/business_accounting_shell_controller.dart';
import 'presentation/pages/accounting_sales_page.dart';
import 'presentation/widgets/accounting_overview_panel.dart';
import 'presentation/widgets/accounting_sales_entry_form.dart';

part 'presentation/business_accounting_shell_layout_part.dart';

class BusinessAccountingShell extends StatefulWidget {
  const BusinessAccountingShell({super.key});

  @override
  State<BusinessAccountingShell> createState() =>
      _BusinessAccountingShellState();
}

class _BusinessAccountingShellState extends State<BusinessAccountingShell> {
  final AccountingRepository _repository = CallableAccountingRepository();
  final BusinessAccountingShellController _controller =
      BusinessAccountingShellController();
  String? _summaryStreamKey;
  Stream<AccountingSummary>? _summaryStream;

  static const _tabs = <_AccountingTab>[
    _AccountingTab('Adisyon Yönet', Icons.receipt_long_rounded),
    _AccountingTab('Tahsilatlar', Icons.schedule_rounded),
    _AccountingTab('Giderler', Icons.receipt_long_rounded),
    _AccountingTab('Raporlar', Icons.picture_as_pdf_rounded),
    _AccountingTab('Yetkiler', Icons.admin_panel_settings_rounded),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.maybeOf(context);
    final businessId = session?.businessId ?? '';
    final businessName = session?.businessName ?? '\u0130\u015fletme';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final index = _controller.index;
        final periodMode = _controller.periodMode;
        final period = _periodRange(_controller.periodAnchor, periodMode);
        final periodLabel = _periodLabel(period.start, periodMode);
        final pages = <Widget>[
          AccountingSalesPage(
            key: const PageStorageKey<String>('accounting_sales_tab'),
            from: period.start,
            to: period.end,
          ),
          AccountingReceivablesPage(
            key: const PageStorageKey<String>('accounting_operations_tab'),
            from: period.start,
            to: period.end,
          ),
          AccountingExpensesPage(
            key: const PageStorageKey<String>('accounting_expenses_tab'),
            from: period.start,
            to: period.end,
          ),
          AccountingReportsPage(
            key: const PageStorageKey<String>('accounting_reports_tab'),
            periodLabel: periodLabel,
            from: period.start,
            to: period.end,
          ),
          const AccountingPermissionsPage(
            key: PageStorageKey<String>('accounting_permissions_tab'),
          ),
        ];

        return RxKeyboardShortcutScope(
          onCreate: () => _showSaleEntrySheet(),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: _buildAccountingBody(
              index: index,
              pages: pages,
              businessId: businessId,
              businessName: businessName,
              period: period,
              periodMode: periodMode,
              periodLabel: periodLabel,
            ),
          ),
        );
      },
    );
  }

  void _selectTab(int index) {
    _controller.selectTab(index, _tabs.length);
  }

  void _handleQuickAction(AccountingQuickAction action) {
    switch (action) {
      case AccountingQuickAction.addSale:
        _showSaleEntrySheet();
        return;
      case AccountingQuickAction.collectPayment:
        _selectTab(1);
        return;
      case AccountingQuickAction.addExpense:
        _showExpenseEntrySheet();
        return;
      case AccountingQuickAction.openReports:
        _selectTab(3);
        return;
      case AccountingQuickAction.openPermissions:
        _selectTab(4);
        return;
    }
  }

  Stream<AccountingSummary> _watchSummaryFor({
    required String businessId,
    required String periodKey,
    required _AccountingPeriodRange period,
  }) {
    final key = [
      businessId,
      periodKey,
      period.start.millisecondsSinceEpoch,
      period.end.millisecondsSinceEpoch,
    ].join('|');

    if (_summaryStreamKey != key || _summaryStream == null) {
      _summaryStreamKey = key;
      _summaryStream = _repository.watchSummary(
        businessId: businessId,
        periodKey: periodKey,
        from: period.start,
        to: period.end,
      );
    }

    return _summaryStream!;
  }

  Future<void> _showSaleEntrySheet() async {
    await showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 720,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.86,
          child: AccountingSalesEntryForm(),
        );
      },
    );
  }

  Future<void> _showExpenseEntrySheet() async {
    await showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 640,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: AccountingExpenseEntryForm(),
        );
      },
    );
  }

  _AccountingPeriodRange _periodRange(
    DateTime date,
    AccountingPeriodMode mode,
  ) {
    switch (mode) {
      case AccountingPeriodMode.day:
        final start = DateTime(date.year, date.month, date.day);
        return _AccountingPeriodRange(
          start,
          start.add(const Duration(days: 1)),
        );
      case AccountingPeriodMode.year:
        return _AccountingPeriodRange(
          DateTime(date.year),
          DateTime(date.year + 1),
        );
      case AccountingPeriodMode.month:
        return _AccountingPeriodRange(
          DateTime(date.year, date.month),
          DateTime(date.year, date.month + 1),
        );
    }
  }

  String _periodLabel(DateTime date, AccountingPeriodMode mode) {
    const months = [
      'Ocak',
      '\u015eubat',
      'Mart',
      'Nisan',
      'May\u0131s',
      'Haziran',
      'Temmuz',
      'A\u011fustos',
      'Eyl\u00fcl',
      'Ekim',
      'Kas\u0131m',
      'Aral\u0131k',
    ];

    switch (mode) {
      case AccountingPeriodMode.day:
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        return '$day.$month.${date.year}';
      case AccountingPeriodMode.year:
        return '${date.year} y\u0131l\u0131';
      case AccountingPeriodMode.month:
        return '${months[date.month - 1]} ${date.year}';
    }
  }
}

class _AccountingPeriodRange {
  const _AccountingPeriodRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class _AccountingTab {
  const _AccountingTab(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _AccountingLazyStack extends StatefulWidget {
  const _AccountingLazyStack({required this.index, required this.pages});

  final int index;
  final List<Widget> pages;

  @override
  State<_AccountingLazyStack> createState() => _AccountingLazyStackState();
}

class _AccountingLazyStackState extends State<_AccountingLazyStack> {
  final Set<int> _visited = <int>{};

  @override
  void initState() {
    super.initState();
    _visited.add(widget.index);
  }

  @override
  void didUpdateWidget(covariant _AccountingLazyStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited
      ..removeWhere((index) => index >= widget.pages.length)
      ..add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final index in _visited)
          Offstage(
            offstage: index != widget.index,
            child: TickerMode(
              enabled: index == widget.index,
              child: SizedBox.expand(
                child: KeyedSubtree(
                  key: PageStorageKey<String>('accounting_tab_page_$index'),
                  child: widget.pages[index],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
