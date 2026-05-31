part of 'business_finance_widgets.dart';

class FinanceInfoCard extends StatelessWidget {
  const FinanceInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2563EB)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(text),
      ),
    );
  }
}

class FinanceWarningCard extends StatelessWidget {
  const FinanceWarningCard({
    super.key,
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF7ED),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFB45309),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(text),
      ),
    );
  }
}

class FinanceEmptyText extends StatelessWidget {
  const FinanceEmptyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
