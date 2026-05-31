part of 'accounting_overview_panel.dart';

class _AccountingOverviewPanelState extends State<AccountingOverviewPanel> {
  final AccountingOverviewPanelController _controller =
      AccountingOverviewPanelController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final summaryExpanded = _controller.summaryExpanded;

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryToggleBar(
                expanded: summaryExpanded,
                businessName: widget.businessName,
                netLabel: AccountingOverviewPanel.money(summary.netKurus),
                statusIcon: statusIcon,
                statusLabel: statusLabel,
                statusColor: statusColor,
                onTap: _controller.toggleSummary,
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
                        const SizedBox(height: 10),
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
                crossFadeState: summaryExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
              const SizedBox(height: 8),
              _ActionGrid(onQuickAction: widget.onQuickAction),
            ],
          ),
        );
      },
    );
  }
}
