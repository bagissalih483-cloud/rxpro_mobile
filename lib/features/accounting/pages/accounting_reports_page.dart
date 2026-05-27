import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/session/app_session_scope.dart';

import '../data/accounting_repository.dart';
import '../data/callable_accounting_repository.dart';
import '../models/accounting_models.dart';

class AccountingReportsPage extends StatefulWidget {
  AccountingReportsPage({
    super.key,
    required this.periodLabel,
    required this.from,
    required this.to,
    AccountingRepository? repository,
  }) : _repository = repository ?? CallableAccountingRepository();

  final String periodLabel;
  final DateTime from;
  final DateTime to;
  final AccountingRepository _repository;

  @override
  State<AccountingReportsPage> createState() => _AccountingReportsPageState();
}

class _AccountingReportsPageState extends State<AccountingReportsPage>
    with AutomaticKeepAliveClientMixin {
  String _reportType = 'summary';
  String? _summaryStreamKey;
  Stream<AccountingSummary>? _summaryStream;

  @override
  bool get wantKeepAlive => true;

  void _showExportPreview(String type, AccountingSummary summary) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final title = type == 'pdf'
            ? 'PDF rapor tasla\u011f\u0131'
            : 'Excel/CSV rapor tasla\u011f\u0131';

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _InfoRow(label: 'D\u00f6nem', value: widget.periodLabel),
              _InfoRow(label: 'Rapor', value: _reportTypeLabel(_reportType)),
              _InfoRow(label: 'Ciro', value: _money(summary.totalSalesKurus)),
              _InfoRow(label: 'Tahsilat', value: _money(summary.collectedKurus)),
              _InfoRow(label: 'Gider', value: _money(summary.expenseKurus)),
              _InfoRow(label: 'Net', value: _money(summary.netKurus)),
              const SizedBox(height: 12),
              const Text(
                'PDF/Excel dışa aktarımı sonraki sunucu adımında dosya olarak üretilecek. Bu ekran şimdiden seçili dönemin canlı özetini kullanır.',
                style: TextStyle(color: Color(0xFF64748B), height: 1.35),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Ön izlemeyi kapat'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _reportTypeLabel(String value) {
    switch (value) {
      case 'receivables':
        return 'Alacak raporu';
      case 'expenses':
        return 'Gider raporu';
      case 'staff':
        return 'Personel i\u015flem raporu';
      case 'items':
        return 'Hizmet / \u00fcr\u00fcn k\u0131r\u0131l\u0131m\u0131';
      default:
        return 'Gelir-gider \u00f6zeti';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final session = AppSessionScope.maybeOf(context);
    final businessId = session?.businessId ?? '';

    return StreamBuilder<AccountingSummary>(
      stream: _watchSummaryFor(
        businessId: businessId,
      ),
      builder: (context, snapshot) {
        final summary =
            snapshot.data ??
            AccountingSummary(
              businessId: businessId,
              periodLabel: widget.periodLabel,
            );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ReportMetricsGrid(summary: summary),
            const SizedBox(height: 12),
            _ReportFilterCard(
              reportType: _reportType,
              onReportTypeChanged: (value) {
                setState(() => _reportType = value);
              },
            ),
            const SizedBox(height: 12),
            _ReportPreviewCard(
              periodLabel: widget.periodLabel,
              reportTypeLabel: _reportTypeLabel(_reportType),
              onPdf: () => _showExportPreview('pdf', summary),
              onExcel: () => _showExportPreview('excel', summary),
            ),
            const SizedBox(height: 12),
            _ReportBreakdownCard(summary: summary),
          ],
        );
      },
    );
  }

  Stream<AccountingSummary> _watchSummaryFor({required String businessId}) {
    final key = [
      businessId,
      widget.periodLabel,
      widget.from.millisecondsSinceEpoch,
      widget.to.millisecondsSinceEpoch,
    ].join('|');

    if (_summaryStreamKey != key || _summaryStream == null) {
      _summaryStreamKey = key;
      _summaryStream = widget._repository.watchSummary(
        businessId: businessId,
        periodKey: widget.periodLabel,
        from: widget.from,
        to: widget.to,
      );
    }

    return _summaryStream!;
  }
}

class _ReportFilterCard extends StatelessWidget {
  const _ReportFilterCard({
    required this.reportType,
    required this.onReportTypeChanged,
  });

  final String reportType;
  final ValueChanged<String> onReportTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Rapor tipi'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: reportType,
              decoration: const InputDecoration(
                labelText: 'Rapor tipi',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'summary',
                  child: Text('Gelir-gider \u00f6zeti'),
                ),
                DropdownMenuItem(
                  value: 'receivables',
                  child: Text('Alacak raporu'),
                ),
                DropdownMenuItem(
                  value: 'expenses',
                  child: Text('Gider raporu'),
                ),
                DropdownMenuItem(
                  value: 'staff',
                  child: Text('Personel i\u015flem raporu'),
                ),
                DropdownMenuItem(
                  value: 'items',
                  child: Text(
                    'Hizmet / \u00fcr\u00fcn k\u0131r\u0131l\u0131m\u0131',
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) onReportTypeChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMetricsGrid extends StatelessWidget {
  const _ReportMetricsGrid({required this.summary});

  final AccountingSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricItem(
        'Ciro',
        _money(summary.totalSalesKurus),
        Icons.trending_up_rounded,
      ),
      _MetricItem(
        'Tahsilat',
        _money(summary.collectedKurus),
        Icons.verified_rounded,
      ),
      _MetricItem(
        'Bekleyen',
        _money(summary.pendingKurus),
        Icons.schedule_rounded,
      ),
      _MetricItem(
        'Geciken',
        _money(summary.overdueKurus),
        Icons.warning_rounded,
      ),
      _MetricItem(
        'Gider',
        _money(summary.expenseKurus),
        Icons.receipt_long_rounded,
      ),
      _MetricItem('Net', _money(summary.netKurus), Icons.ssid_chart_rounded),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 42) / 2,
            child: _MetricCard(item: item),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Icon(item.icon, color: const Color(0xFF475569), size: 25),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportPreviewCard extends StatelessWidget {
  const _ReportPreviewCard({
    required this.periodLabel,
    required this.reportTypeLabel,
    required this.onPdf,
    required this.onExcel,
  });

  final String periodLabel;
  final String reportTypeLabel;
  final VoidCallback onPdf;
  final VoidCallback onExcel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Rapor \u00f6n izlemesi'),
            const SizedBox(height: 10),
            _InfoRow(label: 'D\u00f6nem', value: periodLabel),
            _InfoRow(label: 'Tip', value: reportTypeLabel),
            const _InfoRow(
              label: 'Durum',
              value: 'Seçili dönem verisi hazır',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExcel,
                    icon: const Icon(Icons.table_chart_rounded),
                    label: const Text('Excel/CSV'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportBreakdownCard extends StatelessWidget {
  const _ReportBreakdownCard({required this.summary});

  final AccountingSummary summary;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _BreakdownRow(
        'Hizmet gelirleri',
        _money(summary.serviceRevenueKurus),
        Icons.room_service_rounded,
      ),
      _BreakdownRow(
        '\u00dcr\u00fcn gelirleri',
        _money(summary.productRevenueKurus),
        Icons.shopping_bag_rounded,
      ),
      _BreakdownRow(
        'Bekleyen alacak',
        _money(summary.pendingKurus),
        Icons.payments_rounded,
      ),
      _BreakdownRow(
        'Geciken alacak',
        _money(summary.overdueKurus),
        Icons.warning_rounded,
      ),
      _BreakdownRow(
        'Toplam gider',
        _money(summary.expenseKurus),
        Icons.receipt_long_rounded,
      ),
    ];

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('K\u0131r\u0131l\u0131m'),
            const SizedBox(height: 8),
            for (final row in rows)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(row.icon, color: const Color(0xFF10B981)),
                title: Text(
                  row.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: Text(
                  row.value,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: Color(0xFF0F172A),
        fontSize: 15,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

String _money(int kurus) {
  final sign = kurus < 0 ? '-' : '';
  final value = (kurus.abs() / 100).toStringAsFixed(2).replaceAll('.', ',');
  return '$sign$value TL';
}

class _MetricItem {
  const _MetricItem(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
}

class _BreakdownRow {
  const _BreakdownRow(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
}
