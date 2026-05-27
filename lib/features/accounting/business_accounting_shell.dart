import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/session/app_session_scope.dart';

import 'data/accounting_repository.dart';
import 'data/callable_accounting_repository.dart';
import 'models/accounting_models.dart';
import 'pages/accounting_expenses_page.dart';
import 'pages/accounting_receivables_page.dart';
import 'pages/accounting_reports_page.dart';
import 'pages/accounting_permissions_page.dart';
import 'presentation/pages/accounting_sales_page.dart';
import 'presentation/widgets/accounting_overview_panel.dart';

class BusinessAccountingShell extends StatefulWidget {
  const BusinessAccountingShell({super.key});

  @override
  State<BusinessAccountingShell> createState() =>
      _BusinessAccountingShellState();
}

class _BusinessAccountingShellState extends State<BusinessAccountingShell> {
  final AccountingRepository _repository = CallableAccountingRepository();
  int _index = 0;
  AccountingPeriodMode _periodMode = AccountingPeriodMode.month;
  DateTime _periodAnchor = DateTime.now();
  String? _summaryStreamKey;
  Stream<AccountingSummary>? _summaryStream;

  static const _tabs = <_AccountingTab>[
    _AccountingTab('Sat\u0131\u015flar', Icons.point_of_sale_rounded),
    _AccountingTab('Alacaklar', Icons.schedule_rounded),
    _AccountingTab('Giderler', Icons.receipt_long_rounded),
    _AccountingTab('Raporlar', Icons.picture_as_pdf_rounded),
    _AccountingTab('Yetkiler', Icons.admin_panel_settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.maybeOf(context);
    final businessId = session?.businessId ?? '';
    final businessName = session?.businessName ?? 'İşletme';
    final period = _periodRange(_periodAnchor, _periodMode);
    final periodLabel = _periodLabel(period.start, _periodMode);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          StreamBuilder<AccountingSummary>(
            stream: _watchSummaryFor(
              businessId: businessId,
              periodKey: periodLabel,
              period: period,
            ),
            builder: (context, snapshot) {
              final summary =
                  snapshot.data ??
                  AccountingSummary(
                    businessId: businessId,
                    periodLabel: periodLabel,
                  );

              return AccountingOverviewPanel(
                businessName: businessName,
                summary: summary,
                periodMode: _periodMode,
                periodLabel: periodLabel,
                onPeriodModeChanged: (value) {
                  setState(() {
                    _periodMode = value;
                    _periodAnchor = _normalizeAnchor(_periodAnchor, value);
                  });
                },
                onPreviousPeriod: () => _shiftPeriod(-1),
                onNextPeriod: () => _shiftPeriod(1),
                onCurrentPeriod: _goToCurrentPeriod,
                onQuickAction: _handleQuickAction,
              );
            },
          ),
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final selected = _index == index;

                return ChoiceChip(
                  selected: selected,
                  avatar: Icon(
                    tab.icon,
                    size: 18,
                    color: selected ? Colors.white : const Color(0xFF334155),
                  ),
                  label: Text(tab.title),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : const Color(0xFF334155),
                  ),
                  selectedColor: const Color(0xFF10B981),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE2E8F0),
                  ),
                  onSelected: (_) {
                    _selectTab(index);
                  },
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: _tabs.length,
            ),
          ),
          Expanded(
            child: _AccountingLazyStack(
              index: _index,
              pages: pages,
            ),
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    if (index == _index) return;
    setState(() {
      _index = index.clamp(0, _tabs.length - 1).toInt();
    });
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

  void _shiftPeriod(int direction) {
    setState(() {
      switch (_periodMode) {
        case AccountingPeriodMode.day:
          _periodAnchor = _periodAnchor.add(Duration(days: direction));
          return;
        case AccountingPeriodMode.year:
          _periodAnchor = DateTime(_periodAnchor.year + direction);
          return;
        case AccountingPeriodMode.month:
          _periodAnchor = DateTime(
            _periodAnchor.year,
            _periodAnchor.month + direction,
          );
          return;
      }
    });
  }

  void _goToCurrentPeriod() {
    setState(() {
      _periodAnchor = _normalizeAnchor(DateTime.now(), _periodMode);
    });
  }

  DateTime _normalizeAnchor(DateTime date, AccountingPeriodMode mode) {
    switch (mode) {
      case AccountingPeriodMode.day:
        return DateTime(date.year, date.month, date.day);
      case AccountingPeriodMode.year:
        return DateTime(date.year);
      case AccountingPeriodMode.month:
        return DateTime(date.year, date.month);
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return const FractionallySizedBox(
          heightFactor: 0.92,
          child: AccountingSalesEntryForm(),
        );
      },
    );
  }

  Future<void> _showExpenseEntrySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return const FractionallySizedBox(
          heightFactor: 0.92,
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
        return _AccountingPeriodRange(start, start.add(const Duration(days: 1)));
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
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    switch (mode) {
      case AccountingPeriodMode.day:
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        return '$day.$month.${date.year}';
      case AccountingPeriodMode.year:
        return '${date.year} yılı';
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
  const _AccountingLazyStack({
    required this.index,
    required this.pages,
  });

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
