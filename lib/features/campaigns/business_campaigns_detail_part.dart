part of 'business_campaigns_page.dart';

class _BusinessCampaignDetailSheet extends StatelessWidget {
  const _BusinessCampaignDetailSheet({
    required this.item,
    required this.businessName,
    required this.sendingBulkDraft,
    required this.onSendBulkDraft,
  });

  final BusinessCampaignItemViewModel item;
  final String businessName;
  final bool sendingBulkDraft;
  final VoidCallback? onSendBulkDraft;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Icon(
                  item.statusLabel == 'Yayında'
                      ? Icons.local_offer_rounded
                      : Icons.edit_note_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName.trim().isEmpty ? 'İşletme' : businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(text: item.statusLabel),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.description,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _DetailTile(
            icon: Icons.category_outlined,
            label: 'Kategori',
            value: item.category.trim().isEmpty ? 'Genel' : item.category,
          ),
          _DetailTile(
            icon: Icons.sell_outlined,
            label: 'Fırsat',
            value: item.discountText.trim().isEmpty
                ? 'Özel fırsat'
                : item.discountText,
          ),
          _DetailTile(
            icon: Icons.calendar_today_outlined,
            label: 'Geçerlilik',
            value: item.dateRange,
          ),
          if (item.isBulkDraft)
            _DetailTile(
              icon: Icons.notifications_active_outlined,
              label: 'Gönderim',
              value: item.deliverySummary,
            ),
          if (onSendBulkDraft != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: sendingBulkDraft
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        onSendBulkDraft?.call();
                      },
                icon: sendingBulkDraft
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  sendingBulkDraft ? 'Gönderiliyor...' : 'Toplu Mesajı Gönder',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sadece uygulama bildirimi izni olan bağlı müşterilere gönderilir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
