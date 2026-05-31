part of '../../business_profile_page.dart';

class _BusinessHeroCover extends StatelessWidget {
  const _BusinessHeroCover({
    required this.coverUrl,
    required this.logoUrl,
    required this.businessName,
    required this.category,
  });

  final String coverUrl;
  final String logoUrl;
  final String businessName;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: coverUrl.isEmpty
                ? const LinearGradient(
                    colors: [RxColors.navy, RxColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            image: coverUrl.isEmpty
                ? null
                : DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover),
          ),
          child: coverUrl.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.storefront_rounded,
                    color: Colors.white70,
                    size: 46,
                  ),
                )
              : null,
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.30),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 12,
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 2),
                  image: logoUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(logoUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                child: logoUrl.isEmpty
                    ? const Icon(
                        Icons.business_rounded,
                        color: RxColors.primary,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
