part of '../../business_profile_page.dart';

class _ReviewItem {
  final String id;
  final String customerName;
  final String comment;
  final int rating;
  final String createdAt;

  const _ReviewItem({
    required this.id,
    required this.customerName,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: RxColors.primary.withValues(alpha: 0.10),
          child: Icon(icon, color: RxColors.primary),
        ),
        title: Text(title, style: RxText.cardTitle),
        subtitle: Text(text, style: RxText.body),
      ),
    );
  }
}
