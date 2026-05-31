part of '../../business_profile_page.dart';

class _BusinessHeroMetrics extends StatelessWidget {
  const _BusinessHeroMetrics({
    required this.ratingCount,
    required this.ratingAvg,
    required this.followerCount,
  });

  final int ratingCount;
  final double ratingAvg;
  final int followerCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniInfo(
          icon: Icons.star_rounded,
          text: ratingCount == 0 ? 'Puan yok' : '${ratingAvg.toStringAsFixed(1)} puan',
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFFFFBEB),
        ),
        _MiniInfo(
          icon: Icons.reviews_outlined,
          text: '$ratingCount yorum',
          color: const Color(0xFF2563EB),
          bg: const Color(0xFFEFF6FF),
        ),
        _MiniInfo(
          icon: Icons.favorite_rounded,
          text: '${followerCount} takipçi',
          color: const Color(0xFFDC2626),
          bg: const Color(0xFFFFE4E6),
        ),
      ],
    );
  }
}

class _BusinessHeroActions extends StatelessWidget {
  const _BusinessHeroActions({
    required this.businessId,
    required this.businessName,
    required this.category,
    required this.canEdit,
  });

  final String businessId;
  final String businessName;
  final String category;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    if (!canEdit) {
      return Row(
        children: [
          Expanded(
            child: _ProfileFollowButton(
              businessId: businessId,
              businessName: businessName,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.messagesNewCustomer,
                  arguments: NewCustomerMessageRouteArgs(
                    initialBusinessId: businessId,
                    initialBusinessName: businessName,
                    initialBusinessCategory: category,
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Mesaj'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Sahip gÖrÜnÜmÜ: Bu kurumsal profili yÖnetme yetkiniz var.',
                  style: TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: BusinessProfileEditButton(businessId: businessId),
        ),
      ],
    );
  }
}
