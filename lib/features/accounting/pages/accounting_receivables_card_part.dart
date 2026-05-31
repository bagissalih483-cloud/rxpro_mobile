part of 'accounting_receivables_page.dart';

class _ReceivableCard extends StatelessWidget {
  const _ReceivableCard({
    required this.item,
    required this.onCollect,
    required this.onReminder,
  });

  final _ReceivableItem item;
  final VoidCallback? onCollect;
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
