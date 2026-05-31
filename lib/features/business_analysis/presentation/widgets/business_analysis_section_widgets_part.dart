part of 'business_analysis_widgets.dart';

class BusinessAnalysisSection extends StatelessWidget {
  const BusinessAnalysisSection({
    super.key,
    required this.title,
    required this.emptyText,
    required this.entries,
    required this.icon,
  });

  final String title;
  final String emptyText;
  final List<MapEntry<String, int>> entries;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final maxValue = entries.isEmpty ? 1 : entries.first.value;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(emptyText, style: const TextStyle(color: Color(0xFF64748B)))
          else
            for (final item in entries) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${item.value}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: item.value / math.max(1, maxValue),
                  backgroundColor: const Color(0xFFE2E8F0),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class BusinessAnalysisSuggestionCard extends StatelessWidget {
  const BusinessAnalysisSuggestionCard({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(color: Color(0xFF78350F), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
