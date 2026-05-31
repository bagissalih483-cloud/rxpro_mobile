part of '../business_accounting_shell.dart';

extension _BusinessAccountingShellLayout on _BusinessAccountingShellState {
  Widget _buildAccountingBody({
    required int index,
    required List<Widget> pages,
    required String businessId,
    required String businessName,
    required _AccountingPeriodRange period,
    required AccountingPeriodMode periodMode,
    required String periodLabel,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceClass = RxBreakpoints.fromWidth(constraints.maxWidth);
        final content = Column(
          children: [
            _buildOverview(
              businessId: businessId,
              businessName: businessName,
              period: period,
              periodMode: periodMode,
              periodLabel: periodLabel,
            ),
            Expanded(child: _AccountingLazyStack(index: index, pages: pages)),
          ],
        );

        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              _AccountingMobileTabStrip(
                tabs: _BusinessAccountingShellState._tabs,
                selectedIndex: index,
                onSelected: _selectTab,
              ),
              Expanded(child: content),
            ],
          );
        }

        return Row(
          children: [
            _AccountingSideMenu(
              tabs: _BusinessAccountingShellState._tabs,
              selectedIndex: index,
              extended: deviceClass.isDesktopWide,
              onSelected: _selectTab,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, bodyConstraints) {
                  final bodyWidth = bodyConstraints.maxWidth > 1360
                      ? 1360.0
                      : bodyConstraints.maxWidth;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: bodyWidth,
                      height: bodyConstraints.maxHeight,
                      child: content,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverview({
    required String businessId,
    required String businessName,
    required _AccountingPeriodRange period,
    required AccountingPeriodMode periodMode,
    required String periodLabel,
  }) {
    return StreamBuilder<AccountingSummary>(
      stream: _watchSummaryFor(
        businessId: businessId,
        periodKey: periodLabel,
        period: period,
      ),
      builder: (context, snapshot) {
        final summary =
            snapshot.data ??
            AccountingSummary(businessId: businessId, periodLabel: periodLabel);

        return AccountingOverviewPanel(
          businessName: businessName,
          summary: summary,
          periodMode: periodMode,
          periodLabel: periodLabel,
          onPeriodModeChanged: _controller.setPeriodMode,
          onPreviousPeriod: () => _controller.shiftPeriod(-1),
          onNextPeriod: () => _controller.shiftPeriod(1),
          onCurrentPeriod: _controller.goToCurrentPeriod,
          onQuickAction: _handleQuickAction,
        );
      },
    );
  }
}

class _AccountingMobileTabStrip extends StatelessWidget {
  const _AccountingMobileTabStrip({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_AccountingTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = selectedIndex == index;

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
            onSelected: (_) => onSelected(index),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: tabs.length,
      ),
    );
  }
}

class _AccountingSideMenu extends StatelessWidget {
  const _AccountingSideMenu({
    required this.tabs,
    required this.selectedIndex,
    required this.extended,
    required this.onSelected,
  });

  final List<_AccountingTab> tabs;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: extended ? 220 : 84,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return _AccountingSideMenuItem(
            tab: tab,
            selected: selectedIndex == index,
            extended: extended,
            onTap: () => onSelected(index),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemCount: tabs.length,
      ),
    );
  }
}

class _AccountingSideMenuItem extends StatelessWidget {
  const _AccountingSideMenuItem({
    required this.tab,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final _AccountingTab tab;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF10B981) : const Color(0xFF475569);

    return Material(
      color: selected ? const Color(0xFFEFFBF4) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: extended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(tab.icon, color: color, size: 22),
              if (extended) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tab.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
