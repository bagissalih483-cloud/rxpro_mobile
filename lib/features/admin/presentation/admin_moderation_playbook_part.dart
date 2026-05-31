part of 'admin_moderation_page.dart';

class _ModerationPlaybookCard extends StatelessWidget {
  const _ModerationPlaybookCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.fact_check_outlined, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Moderasyon playbook',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            _PlaybookLine(
              icon: Icons.search_rounded,
              text:
                  'Kaydi ara, durum filtresini sec ve SLA rengini kontrol et.',
            ),
            _PlaybookLine(
              icon: Icons.notes_rounded,
              text: 'Karar gerekcesini destek notu olarak audit loga ekle.',
            ),
            _PlaybookLine(
              icon: Icons.visibility_off_outlined,
              text: 'İçerik ihlalinde gizle/geri al aksiyonunu kullan.',
            ),
            _PlaybookLine(
              icon: Icons.block_outlined,
              text: 'Tekrarlayan kötü kullanımda kullanıcı engelleme kaydı aç.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaybookLine extends StatelessWidget {
  const _PlaybookLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
