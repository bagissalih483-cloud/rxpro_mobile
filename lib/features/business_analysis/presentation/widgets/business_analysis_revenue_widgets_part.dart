part of 'business_analysis_widgets.dart';

class BusinessAnalysisRevenueSplitCard extends StatelessWidget {
  const BusinessAnalysisRevenueSplitCard({
    super.key,
    required this.serviceRevenue,
    required this.productRevenue,
    required this.totalRevenue,
    required this.money,
  });

  final double serviceRevenue;
  final double productRevenue;
  final double totalRevenue;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final double serviceRatio = totalRevenue <= 0
        ? 0.0
        : (serviceRevenue / totalRevenue).clamp(0.0, 1.0).toDouble();
    final double productRatio = totalRevenue <= 0
        ? 0.0
        : (productRevenue / totalRevenue).clamp(0.0, 1.0).toDouble();

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
          const Text(
            'Hasılat Dağılımı',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          BusinessAnalysisSplitLine(
            label: 'Hizmet',
            value: money(serviceRevenue),
            ratio: serviceRatio,
          ),
          const SizedBox(height: 10),
          BusinessAnalysisSplitLine(
            label: 'Ürün',
            value: money(productRevenue),
            ratio: productRatio,
          ),
        ],
      ),
    );
  }
}

class BusinessAnalysisSplitLine extends StatelessWidget {
  const BusinessAnalysisSplitLine({
    super.key,
    required this.label,
    required this.value,
    required this.ratio,
  });

  final String label;
  final String value;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: ratio,
            backgroundColor: const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }
}
