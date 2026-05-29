part of '../../business_profile_page.dart';

class _BusinessHeroCard extends StatelessWidget {
  const _BusinessHeroCard({
    required this.businessId,
    required this.businessName,
    required this.category,
  });

  final String businessId;
  final String businessName;
  final String category;
  static final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: BusinessProfileRepository().watchBusinessProfile(
        businessId: businessId,
        includeMetadataChanges: true,
      ),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final coverUrl = data[FirestoreFields.coverUrl]?.toString() ?? '';
        final logoUrl = _firstNonEmpty([
          data[FirestoreFields.logoUrl],
          data[FirestoreFields.photoUrl],
          data[FirestoreFields.imageUrl],
        ]);
        final resolvedBusinessName = _firstNonEmpty([
          data[FirestoreFields.businessName],
          data[FirestoreFields.name],
          data[FirestoreFields.companyName],
          data[FirestoreFields.displayName],
          businessName,
        ]);
        final resolvedCategory = _firstNonEmpty([
          data[FirestoreFields.categoryLabel],
          data[FirestoreFields.category],
          data[FirestoreFields.businessCategory],
          category,
        ]);
        final description = data[FirestoreFields.description]?.toString() ?? '';
        final followerCount = _toInt(data[FirestoreFields.followerCount]);
        final ratingAvg = _toDouble(data[FirestoreFields.ratingAvg]);
        final ratingCount = _toInt(data[FirestoreFields.ratingCount]);
        final currentUser = _authService.currentUser;
        final currentUid = currentUser?.uid;
        final currentEmail = currentUser?.email?.trim().toLowerCase() ?? '';

        String clean(dynamic value) => value?.toString().trim() ?? '';

        bool listContainsUid(dynamic value) {
          if (currentUid == null) return false;
          if (value is Iterable) {
            return value.map((e) => e.toString()).contains(currentUid);
          }
          return false;
        }

        final uidFields = [
          clean(data[FirestoreFields.ownerUid]),
          clean(data[FirestoreFields.ownerId]),
          clean(data[FirestoreFields.userId]),
          clean(data[FirestoreFields.uid]),
          clean(data[FirestoreFields.createdBy]),
          clean(data[FirestoreFields.creatorUid]),
          clean(data[FirestoreFields.businessOwnerUid]),
          clean(data[FirestoreFields.adminUid]),
          clean(data[FirestoreFields.managerUid]),
        ];

        final emailFields = [
          clean(data[FirestoreFields.ownerEmail]).toLowerCase(),
          clean(data[FirestoreFields.businessEmail]).toLowerCase(),
          clean(data[FirestoreFields.createdByEmail]).toLowerCase(),
          clean(data[FirestoreFields.email]).toLowerCase(),
        ];

        final canEdit =
            currentUid != null &&
            (uidFields.contains(currentUid) ||
                listContainsUid(data[FirestoreFields.ownerUids]) ||
                listContainsUid(data[FirestoreFields.owners]) ||
                listContainsUid(data[FirestoreFields.adminUids]) ||
                listContainsUid(data[FirestoreFields.admins]) ||
                listContainsUid(data[FirestoreFields.managerUids]) ||
                listContainsUid(data[FirestoreFields.authorizedUids]) ||
                (currentEmail.isNotEmpty &&
                    emailFields.contains(currentEmail)));

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
              Stack(
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
                          : DecorationImage(
                              image: NetworkImage(coverUrl),
                              fit: BoxFit.cover,
                            ),
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
                                resolvedBusinessName,
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
                                resolvedCategory,
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniInfo(
                          icon: Icons.star_rounded,
                          text: ratingCount == 0
                              ? 'Puan yok'
                              : '${ratingAvg.toStringAsFixed(1)} puan',
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
                          text: '$followerCount takipçi',
                          color: const Color(0xFFDC2626),
                          bg: const Color(0xFFFFE4E6),
                        ),
                      ],
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
                    if (!canEdit) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileFollowButton(
                              businessId: businessId,
                              businessName: resolvedBusinessName,
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
                                    initialBusinessName: resolvedBusinessName,
                                    initialBusinessCategory: resolvedCategory,
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                              ),
                              label: const Text('Mesaj'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
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
                            Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Sahip görünümü: Bu kurumsal profili yönetme yetkiniz var.',
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
                        child: BusinessProfileEditButton(
                          businessId: businessId,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return '';
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.icon,
    required this.text,
    this.color = RxColors.primary,
    this.bg = const Color(0xFFEFF6FF),
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessBookingDisabledCard extends StatelessWidget {
  const _BusinessBookingDisabledCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF7ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFFED7AA)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Color(0xFFC2410C)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kurumsal hesap a\u00e7\u0131kken randevu alma kapat\u0131ld\u0131. Bu ekran sadece bireysel kullan\u0131c\u0131lar\u0131n randevu talebi olu\u015fturmas\u0131 i\u00e7indir.',
                style: TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({
    required this.selectedIndex,
    required this.onChanged,
    this.hideAppointment = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool hideAppointment;

  @override
  Widget build(BuildContext context) {
    final tabs = <_TabData>[
      const _TabData(icon: Icons.home_outlined, label: 'Tan\u0131t\u0131m'),
      if (!hideAppointment)
        const _TabData(icon: Icons.calendar_month_outlined, label: 'Randevu'),
      const _TabData(icon: Icons.chat_outlined, label: 'Yorumlar'),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.028),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = selectedIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? RxColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 20,
                      color: selected ? RxColors.primary : RxColors.muted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: selected ? RxColors.primary : RxColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TabData {
  final IconData icon;
  final String label;

  const _TabData({required this.icon, required this.label});
}
