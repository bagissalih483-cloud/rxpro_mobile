import 'package:flutter/material.dart';

class AccountingSummaryPage extends StatelessWidget {
  const AccountingSummaryPage({super.key, required this.periodLabel});

  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
      children: [
        _DailyFlowPanel(periodLabel: periodLabel),
        const SizedBox(height: 10),
        const _ControlPanel(),
        const SizedBox(height: 10),
        const _RecentTransactionsPanel(),
      ],
    );
  }
}

class _DailyFlowPanel extends StatelessWidget {
  const _DailyFlowPanel({required this.periodLabel});

  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    const items = [
      _FlowItem(
        icon: Icons.point_of_sale_rounded,
        title: 'Satış kaydı',
        text: 'Hizmet, ürün veya karma işlem',
        color: Color(0xFF10B981),
      ),
      _FlowItem(
        icon: Icons.payments_rounded,
        title: 'Tahsilat',
        text: 'Ödenen ve bekleyen tutarlar',
        color: Color(0xFF2563EB),
      ),
      _FlowItem(
        icon: Icons.receipt_long_rounded,
        title: 'Gider',
        text: 'Kira, sarf, personel ve diğer',
        color: Color(0xFFF97316),
      ),
      _FlowItem(
        icon: Icons.picture_as_pdf_rounded,
        title: 'Rapor',
        text: 'Dönem özeti ve dışa aktarım',
        color: Color(0xFF7C3AED),
      ),
    ];

    return _SectionSurface(
      title: 'Muhasebe akışı',
      trailing: _TinyBadge(label: periodLabel, color: Color(0xFF0F766E)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 560 ? 4 : 2;
          final spacing = 8.0;
          final width =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final item in items)
                SizedBox(width: width, child: _FlowTile(item: item)),
            ],
          );
        },
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel();

  @override
  Widget build(BuildContext context) {
    const items = [
      _ControlItem('Bugünkü satışlar işlendi', Icons.done_all_rounded),
      _ControlItem('Bekleyen tahsilatlar kontrol edildi', Icons.schedule_rounded),
      _ControlItem('Gider fişleri kayda hazır', Icons.receipt_rounded),
      _ControlItem('Gün sonu raporu alınabilir', Icons.assessment_rounded),
    ];

    return _SectionSurface(
      title: 'Gün sonu kontrolü',
      trailing: _TinyBadge(label: 'Operasyon', color: Color(0xFF2563EB)),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _ControlRow(item: items[i]),
            if (i != items.length - 1) const Divider(height: 14),
          ],
        ],
      ),
    );
  }
}

class _RecentTransactionsPanel extends StatelessWidget {
  const _RecentTransactionsPanel();

  @override
  Widget build(BuildContext context) {
    return _SectionSurface(
      title: 'Son hareketler',
      trailing: _TinyBadge(label: 'Canlı akış', color: Color(0xFF64748B)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.history_rounded, color: Color(0xFF64748B), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Satış, tahsilat ve gider hareketleri oluştuğunda burada sıralanır.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionSurface extends StatelessWidget {
  const _SectionSurface({
    required this.title,
    required this.trailing,
    required this.child,
  });

  final String title;
  final Widget trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FlowTile extends StatelessWidget {
  const _FlowTile({required this.item});

  final _FlowItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 23),
          const Spacer(),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.item});

  final _ControlItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: const Color(0xFF2563EB), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FlowItem {
  const _FlowItem({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;
}

class _ControlItem {
  const _ControlItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
