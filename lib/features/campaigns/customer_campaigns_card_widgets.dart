part of 'customer_campaigns_page.dart';

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.item,
    required this.onTap,
    required this.onOpenBusiness,
    required this.onReport,
  });

  final _CampaignItem item;
  final VoidCallback onTap;
  final VoidCallback? onOpenBusiness;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Poster(item: item),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 17),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.businessName.isEmpty
                              ? 'İşletme'
                              : item.businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        item.dateRange,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (onOpenBusiness != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RxPrimaryActionButton(
                            onPressed: onOpenBusiness,
                            icon: Icons.calendar_month_outlined,
                            label: 'Fırsattan Randevu Al',
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          tooltip: 'Şikayet et',
                          onPressed: onReport,
                          icon: const Icon(Icons.flag_outlined),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton.outlined(
                        tooltip: 'Şikayet et',
                        onPressed: onReport,
                        icon: const Icon(Icons.flag_outlined),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
