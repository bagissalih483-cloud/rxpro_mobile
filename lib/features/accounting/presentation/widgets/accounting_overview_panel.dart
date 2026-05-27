import 'package:flutter/material.dart';

import '../../models/accounting_models.dart';

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
  State<AccountingOverviewPanel> createState() => _AccountingOverviewPanelState();

  static String money(int kurus) {
    final sign = kurus < 0 ? '-' : '';
    final value = (kurus.abs() / 100).toStringAsFixed(2).replaceAll('.', ',');
    return '$sign$value TL';
  }
}

class _AccountingOverviewPanelState extends State<AccountingOverviewPanel> {
  var _summaryExpanded = false;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final netPositive = summary.netKurus >= 0;
    final hasOverdue = summary.overdueKurus > 0;
    final statusIcon = hasOverdue
        ? Icons.warning_amber_rounded
        : netPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final statusLabel = hasOverdue
        ? 'Geciken var'
        : netPositive
        ? 'Dengede'
        : 'Açık var';
    final statusColor = hasOverdue
        ? const Color(0xFFEF4444)
        : netPositive
        ? const Color(0xFF22C55E)
        : const Color(0xFFF97316);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeriodSwitcher(
            selected: widget.periodMode,
            onChanged: widget.onPeriodModeChanged,
          ),
          const SizedBox(height: 6),
          _PeriodNavigator(
            label: widget.periodLabel,
            onPrevious: widget.onPreviousPeriod,
            onNext: widget.onNextPeriod,
            onCurrent: widget.onCurrentPeriod,
          ),
          const SizedBox(height: 8),
          _SummaryToggleBar(
            expanded: _summaryExpanded,
            businessName: widget.businessName,
            netLabel: AccountingOverviewPanel.money(summary.netKurus),
            statusIcon: statusIcon,
            statusLabel: statusLabel,
            statusColor: statusColor,
            onTap: () {
              setState(() => _summaryExpanded = !_summaryExpanded);
            },
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.businessName.trim().isEmpty
                                ? 'Muhasebe paneli'
                                : widget.businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.periodLabel} dönemi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      icon: statusIcon,
                      label: statusLabel,
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AccountingOverviewPanel.money(summary.netKurus),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Net nakit görünümü: tahsilat - gider',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth < 520;
                    final itemWidth = twoColumns
                        ? (constraints.maxWidth - 6) / 2
                        : (constraints.maxWidth - 18) / 4;

                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: _MetricTile(
                            label: 'Ciro',
                            value: AccountingOverviewPanel.money(
                              summary.totalSalesKurus,
                            ),
                            color: const Color(0xFF38BDF8),
                            icon: Icons.show_chart_rounded,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _MetricTile(
                            label: 'Tahsilat',
                            value: AccountingOverviewPanel.money(
                              summary.collectedKurus,
                            ),
                            color: const Color(0xFF22C55E),
                            icon: Icons.verified_rounded,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _MetricTile(
                            label: 'Alacak',
                            value: AccountingOverviewPanel.money(
                              summary.pendingKurus,
                            ),
                            color: const Color(0xFFF59E0B),
                            icon: Icons.schedule_rounded,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _MetricTile(
                            label: 'Gider',
                            value: AccountingOverviewPanel.money(
                              summary.expenseKurus,
                            ),
                            color: const Color(0xFFFB7185),
                            icon: Icons.receipt_long_rounded,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                  ],
                ),
              ),
            ),
            crossFadeState: _summaryExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
          const SizedBox(height: 8),
          _ActionGrid(onQuickAction: widget.onQuickAction),
        ],
      ),
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _RoundIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Önceki dönem',
                onTap: onPrevious,
              ),
              Expanded(
                child: InkWell(
                  onTap: onCurrent,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              _RoundIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Sonraki dönem',
                onTap: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFF0F172A), size: 22),
        ),
      ),
    );
  }
}

class _SummaryToggleBar extends StatelessWidget {
  const _SummaryToggleBar({
    required this.expanded,
    required this.businessName,
    required this.netLabel,
    required this.statusIcon,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  final bool expanded;
  final String businessName;
  final String netLabel;
  final IconData statusIcon;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName.trim().isEmpty ? 'Mali özet' : businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Net: $netLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                icon: statusIcon,
                label: statusLabel,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF475569),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.onQuickAction});

  final ValueChanged<AccountingQuickAction> onQuickAction;

  @override
  Widget build(BuildContext context) {
    const actions = [
      _ActionData(
        title: 'Satış gir',
        text: 'Hizmet veya ürün',
        icon: Icons.add_shopping_cart_rounded,
        color: Color(0xFF10B981),
        action: AccountingQuickAction.addSale,
      ),
      _ActionData(
        title: 'Tahsilat',
        text: 'Bekleyen alacak',
        icon: Icons.payments_rounded,
        color: Color(0xFF2563EB),
        action: AccountingQuickAction.collectPayment,
      ),
      _ActionData(
        title: 'Gider ekle',
        text: 'Masraf takibi',
        icon: Icons.receipt_long_rounded,
        color: Color(0xFFF97316),
        action: AccountingQuickAction.addExpense,
      ),
      _ActionData(
        title: 'Rapor',
        text: 'PDF ve dönem',
        icon: Icons.picture_as_pdf_rounded,
        color: Color(0xFF7C3AED),
        action: AccountingQuickAction.openReports,
      ),
      _ActionData(
        title: 'Yetki',
        text: 'Personel erişimi',
        icon: Icons.admin_panel_settings_rounded,
        color: Color(0xFF0F766E),
        action: AccountingQuickAction.openPermissions,
      ),
    ];

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];

          return SizedBox(
            width: 88,
            child: _ActionTile(
              data: action,
              onTap: () => onQuickAction(action.action),
            ),
          );
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.data, required this.onTap});

  final _ActionData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 74,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(data.icon, color: data.color, size: 19),
              const Spacer(),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                data.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({
    required this.selected,
    required this.onChanged,
  });

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
