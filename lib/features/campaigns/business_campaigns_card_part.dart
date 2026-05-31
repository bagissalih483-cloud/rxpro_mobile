part of 'business_campaigns_page.dart';

class _BusinessCampaignCard extends StatelessWidget {
  const _BusinessCampaignCard({
    required this.item,
    required this.onTap,
    required this.onUnpublish,
  });

  final BusinessCampaignItemViewModel item;
  final VoidCallback onTap;
  final VoidCallback? onUnpublish;

  @override
  Widget build(BuildContext context) {
    final published = onUnpublish != null;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: published
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    child: Icon(
                      published
                          ? Icons.local_offer_rounded
                          : Icons.edit_note_rounded,
                      color: published
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  _StatusChip(text: item.statusLabel),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              _InfoLine(label: 'Kategori', value: item.category),
              _InfoLine(label: 'Fırsat', value: item.discountText),
              if (item.isBulkDraft)
                _InfoLine(label: 'Gönderim', value: item.deliverySummary),
              _InfoLine(label: 'Geçerlilik', value: item.dateRange),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.open_in_full_rounded),
                    label: const Text('Detay'),
                  ),
                  const Spacer(),
                  if (onUnpublish != null)
                    OutlinedButton.icon(
                      onPressed: onUnpublish,
                      icon: const Icon(Icons.visibility_off_outlined),
                      label: const Text('Yayından Kaldır'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
