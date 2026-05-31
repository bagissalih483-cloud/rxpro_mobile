part of 'appointment_dashboard_views.dart';

class AppointmentHeatLegend extends StatelessWidget {
  const AppointmentHeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      AppointmentLegendItem('Boş', Color(0xFFFFFFFF)),
      AppointmentLegendItem('Az', Color(0xFFFFE4E6)),
      AppointmentLegendItem('Orta', Color(0xFFFCA5A5)),
      AppointmentLegendItem('Yoğun', Color(0xFFEF4444)),
      AppointmentLegendItem('Çok yoğun', Color(0xFF991B1B)),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class AppointmentErrorCard extends StatelessWidget {
  const AppointmentErrorCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Text(
          'Randevu verisi okunamadı:\n$message',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
