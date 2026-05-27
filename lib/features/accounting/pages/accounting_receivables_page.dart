import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/session/app_session_scope.dart';

import '../data/accounting_repository.dart';
import '../data/callable_accounting_repository.dart';
import '../models/accounting_models.dart';

class AccountingReceivablesPage extends StatefulWidget {
  AccountingReceivablesPage({
    super.key,
    required this.from,
    required this.to,
    AccountingRepository? repository,
  }) : _repository = repository ?? CallableAccountingRepository();

  final DateTime from;
  final DateTime to;
  final AccountingRepository _repository;

  @override
  State<AccountingReceivablesPage> createState() =>
      _AccountingReceivablesPageState();
}

class _AccountingReceivablesPageState extends State<AccountingReceivablesPage>
    with AutomaticKeepAliveClientMixin {
  String _filter = 'all';
  String? _salesStreamKey;
  Stream<List<AccountingSale>>? _salesStream;

  @override
  bool get wantKeepAlive => true;

  List<_ReceivableItem> _visibleItems(List<_ReceivableItem> items) {
    if (_filter == 'all') return items;
    return items.where((item) => item.status == _filter).toList();
  }

  void _showCollectionPreview(_ReceivableItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Tahsilat \u00f6n izlemesi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _InfoRow(label: 'M\u00fc\u015fteri', value: item.customerName),
              _InfoRow(label: 'Kalem', value: item.itemName),
              _InfoRow(label: 'Toplam', value: item.totalLabel),
              _InfoRow(label: '\u00d6denen', value: item.paidLabel),
              _InfoRow(label: 'Kalan', value: item.remainingLabel),
              _InfoRow(label: 'Durum', value: item.statusLabel),
              const SizedBox(height: 12),
              const Text(
                'Tahsilat kaydı canlı servis açıldığında bu satışın kalan bakiyesinden düşülecek.',
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

  void _showReminderPreview(_ReceivableItem item) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hat\u0131rlatma tasla\u011f\u0131'),
          content: Text(
            '${item.customerName} i\u00e7in ${item.remainingLabel} kalan alacak hat\u0131rlatmas\u0131 olu\u015fturulacak. Bildirim altyap\u0131s\u0131 46H a\u015famas\u0131nda ba\u011flanacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final session = AppSessionScope.maybeOf(context);
    final businessId = session?.businessId ?? '';

    return StreamBuilder<List<AccountingSale>>(
      stream: _watchSalesFor(businessId),
      builder: (context, snapshot) {
        final allItems = (snapshot.data ?? const <AccountingSale>[])
            .where((sale) => sale.remainingAmountKurus > 0)
            .map(_ReceivableItem.fromSale)
            .toList();
        final items = _visibleItems(allItems);

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _FilterChips(
              filter: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 10),
            if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(minHeight: 3),
            if (items.isEmpty)
              const _EmptyReceivables()
            else
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReceivableCard(
                    item: item,
                    onCollect: () => _showCollectionPreview(item),
                    onReminder: () => _showReminderPreview(item),
                  ),
                ),
          ],
        );
      },
    );
  }

  Stream<List<AccountingSale>> _watchSalesFor(String businessId) {
    final key = [
      businessId,
      widget.from.millisecondsSinceEpoch,
      widget.to.millisecondsSinceEpoch,
    ].join('|');

    if (_salesStreamKey != key || _salesStream == null) {
      _salesStreamKey = key;
      _salesStream = widget._repository.watchSales(
        businessId: businessId,
        from: widget.from,
        to: widget.to,
      );
    }

    return _salesStream!;
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.filter, required this.onChanged});

  final String filter;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipButton(
          selected: filter == 'all',
          label: 'T\u00fcm\u00fc',
          onTap: () => onChanged('all'),
        ),
        _FilterChipButton(
          selected: filter == 'unpaid',
          label: 'Bekleyen',
          onTap: () => onChanged('unpaid'),
        ),
        _FilterChipButton(
          selected: filter == 'partial',
          label: 'K\u0131smi',
          onTap: () => onChanged('partial'),
        ),
        _FilterChipButton(
          selected: filter == 'overdue',
          label: 'Geciken',
          onTap: () => onChanged('overdue'),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected ? Colors.white : const Color(0xFF334155),
      ),
      selectedColor: const Color(0xFF10B981),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _ReceivableCard extends StatelessWidget {
  const _ReceivableCard({
    required this.item,
    required this.onCollect,
    required this.onReminder,
  });

  final _ReceivableItem item;
  final VoidCallback onCollect;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    final color = item.status == 'overdue'
        ? const Color(0xFFEF4444)
        : item.status == 'partial'
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B981);

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(Icons.person_rounded, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                Chip(
                  label: Text(item.statusLabel),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                  backgroundColor: color.withValues(alpha: 0.10),
                  side: BorderSide(color: color.withValues(alpha: 0.25)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.itemName,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.source} • ${item.dueLabel}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: _AmountColumn(title: 'Toplam', value: item.totalLabel),
                ),
                Expanded(
                  child: _AmountColumn(
                    title: '\u00d6denen',
                    value: item.paidLabel,
                  ),
                ),
                Expanded(
                  child: _AmountColumn(
                    title: 'Kalan',
                    value: item.remainingLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCollect,
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: const Text('Tahsilat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReminder,
                    icon: const Icon(
                      Icons.notifications_active_rounded,
                      size: 18,
                    ),
                    label: const Text('Hat\u0131rlat'),
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

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ],
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
            width: 96,
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

class _EmptyReceivables extends StatelessWidget {
  const _EmptyReceivables();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 38),
            SizedBox(height: 10),
            Text(
              'Bu filtrede alacak yok',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivableItem {
  const _ReceivableItem({
    required this.customerName,
    required this.itemName,
    required this.totalLabel,
    required this.paidLabel,
    required this.remainingLabel,
    required this.dueLabel,
    required this.status,
    required this.source,
  });

  final String customerName;
  final String itemName;
  final String totalLabel;
  final String paidLabel;
  final String remainingLabel;
  final String dueLabel;
  final String status;
  final String source;

  factory _ReceivableItem.fromSale(AccountingSale sale) {
    final now = DateTime.now();
    final due = sale.dueDate;
    final itemName = sale.items.map((item) => item.name).take(2).join(' + ');
    final overdue =
        due != null && sale.remainingAmountKurus > 0 && due.isBefore(now);

    return _ReceivableItem(
      customerName: sale.customerName?.trim().isNotEmpty == true
          ? sale.customerName!.trim()
          : 'Misafir müşteri',
      itemName: itemName.isEmpty ? _saleTypeLabel(sale.saleType) : itemName,
      totalLabel: _money(sale.totalAmountKurus),
      paidLabel: _money(sale.paidAmountKurus),
      remainingLabel: _money(sale.remainingAmountKurus),
      dueLabel: due == null ? 'Vade yok' : 'Vade: ${_dateLabel(due)}',
      status: overdue
          ? 'overdue'
          : sale.paidAmountKurus > 0
          ? 'partial'
          : 'unpaid',
      source: _saleTypeLabel(sale.saleType),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'partial':
        return 'K\u0131smi';
      case 'overdue':
        return 'Geciken';
      default:
        return 'Bekleyen';
    }
  }
}

String _money(int kurus) {
  final sign = kurus < 0 ? '-' : '';
  final value = (kurus.abs() / 100).toStringAsFixed(2).replaceAll('.', ',');
  return '$sign$value TL';
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _saleTypeLabel(AccountingSaleType type) {
  switch (type) {
    case AccountingSaleType.product:
      return 'Ürün satışı';
    case AccountingSaleType.mixed:
      return 'Karma satış';
    case AccountingSaleType.service:
      return 'Hizmet satışı';
  }
}
