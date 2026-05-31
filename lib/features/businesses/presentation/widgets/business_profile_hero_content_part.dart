part of '../../business_profile_page.dart';

class _BusinessHeroContent extends StatelessWidget {
  const _BusinessHeroContent({
    required this.businessId,
    required this.businessName,
    required this.category,
    required this.coverUrl,
    required this.logoUrl,
    required this.description,
    required this.followerCount,
    required this.ratingAvg,
    required this.ratingCount,
    required this.canEdit,
  });

  final String businessId;
  final String businessName;
  final String category;
  final String coverUrl;
  final String logoUrl;
  final String description;
  final int followerCount;
  final double ratingAvg;
  final int ratingCount;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BusinessHeroCover(
            coverUrl: coverUrl,
            logoUrl: logoUrl,
            businessName: businessName,
            category: category,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BusinessHeroMetrics(
                  ratingCount: ratingCount,
                  ratingAvg: ratingAvg,
                  followerCount: followerCount,
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RxColors.muted,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 13),
                _BusinessHeroActions(
                  businessId: businessId,
                  businessName: businessName,
                  category: category,
                  canEdit: canEdit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
