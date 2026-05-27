part of '../../business_profile_page.dart';

class _MiniLoadingCard extends StatelessWidget {
  const _MiniLoadingCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: RxText.body),
      ),
    );
  }
}

class _ReviewsTab extends StatefulWidget {
  const _ReviewsTab({required this.businessId, required this.businessName});

  final String businessId;
  final String businessName;

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  final commentController = TextEditingController();
  final BusinessProfileRepository _reviewsRepository =
      BusinessProfileRepository();
  final AuthService _authService = AuthService();
  int selectedRating = 5;
  bool sending = false;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Stream<List<_ReviewItem>> _reviewsStream() {
    return _reviewsRepository
        .watchBusinessReviews(businessId: widget.businessId)
        .map((rows) {
          final list = rows.map((data) {
            return _ReviewItem(
              id: data[FirestoreFields.id]?.toString() ?? '',
              customerName:
                  data[FirestoreFields.customerName]?.toString() ??
                  'Bireysel Kullanıcı',
              comment: data[FirestoreFields.comment]?.toString() ?? '',
              rating: _toInt(data[FirestoreFields.rating]),
              createdAt: data[FirestoreFields.createdAt]?.toString() ?? '',
            );
          }).toList();

          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> _refreshRatingSummary() async {
    await _reviewsRepository.refreshRatingSummary(
      businessId: widget.businessId,
    );
  }

  Future<void> _sendReview() async {
    final user = _authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum yapmak için giriş yapın.')),
      );
      return;
    }

    final comment = commentController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Yorum boş olamaz.')));
      return;
    }

    setState(() => sending = true);

    try {
      final userData = await _reviewsRepository.fetchUserData(uid: user.uid);
      final customerName =
          userData[FirestoreFields.displayName]?.toString() ??
          user.email ??
          'Bireysel Kullanıcı';

      await _reviewsRepository.createReview(
        businessId: widget.businessId,
        businessName: widget.businessName,
        customerUid: user.uid,
        customerName: customerName,
        rating: selectedRating,
        comment: comment,
      );

      await _refreshRatingSummary();

      commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Yorumunuz kaydedildi.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Yorum kaydedilemedi: ')));
      }
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yorum Yaz', style: RxText.sectionTitle),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    final selected = star <= selectedRating;

                    return IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() => selectedRating = star);
                      },
                      icon: Icon(selected ? Icons.star : Icons.star_border),
                      color: RxColors.orange,
                    );
                  }),
                ),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Deneyiminizi yazın...',
                    filled: true,
                    fillColor: RxColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: sending ? null : _sendReview,
                    child: Text(sending ? 'Gönderiliyor...' : 'Yorumu Gönder'),
                  ),
                ),
              ],
            ),
          ),
        ),
        StreamBuilder<List<_ReviewItem>>(
          stream: _reviewsStream(),
          builder: (context, snapshot) {
            final reviews = snapshot.data ?? [];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              );
            }

            if (reviews.isEmpty) {
              return const _InfoCard(
                icon: Icons.chat_outlined,
                title: 'Henüz yorum yok',
                text:
                    'Bu kurumsal kullanıcı için ilk yorumu siz yapabilirsiniz.',
              );
            }

            return Column(
              children: reviews.map((review) {
                return Card(
                  child: ListTile(
                    dense: true,
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(
                      review.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text('${'★' * review.rating}  ${review.comment}'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

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

class _ProfileFollowButton extends StatefulWidget {
  const _ProfileFollowButton({
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<_ProfileFollowButton> createState() => _ProfileFollowButtonState();
}

class _ProfileFollowButtonState extends State<_ProfileFollowButton> {
  final AppCacheService cache = AppCacheService();
  final BusinessProfileRepository _followRepository =
      BusinessProfileRepository();
  final AuthService _authService = AuthService();

  bool following = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final cached = await cache.isBusinessFollowed(widget.businessId);
    if (mounted) {
      setState(() => following = cached);
    }

    final isFollowing = await _followRepository.isFollowingBusiness(
      businessId: widget.businessId,
      uid: user.uid,
    );
    await cache.setBusinessFollowed(
      businessId: widget.businessId,
      followed: isFollowing,
    );

    if (mounted) {
      setState(() => following = isFollowing);
    }
  }

  Future<void> _toggle() async {
    final user = _authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Takip için giriş yapın.')));
      return;
    }

    if (busy) return;

    final oldValue = following;
    final newValue = !oldValue;

    setState(() {
      following = newValue;
      busy = true;
    });

    await cache.setBusinessFollowed(
      businessId: widget.businessId,
      followed: newValue,
    );

    try {
      await _followRepository.setBusinessFollowing(
        businessId: widget.businessId,
        businessName: widget.businessName,
        uid: user.uid,
        followed: newValue,
      );
    } catch (_) {
      await cache.setBusinessFollowed(
        businessId: widget.businessId,
        followed: oldValue,
      );
      if (mounted) {
        setState(() => following = oldValue);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: busy ? null : _toggle,
      icon: Icon(
        following ? Icons.favorite : Icons.favorite_border,
        color: following ? RxColors.red : null,
        size: 18,
      ),
      label: Text(following ? 'Takipte' : 'Takip'),
    );
  }
}

int _postInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

// ignore: unused_element
class _StableBookingTile extends StatelessWidget {
  const _StableBookingTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEDE9FE) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFFE5E7EB),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? const Color(0xFF5B21B6)
                            : const Color(0xFF111827),
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StableTimeChip extends StatelessWidget {
  const _StableTimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(64, 38),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: selected ? const Color(0xFFEDE9FE) : Colors.white,
          foregroundColor: selected
              ? const Color(0xFF6D28D9)
              : const Color(0xFF111827),
          side: BorderSide(
            color: selected ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB),
            width: selected ? 1.4 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ),
    );
  }
}
