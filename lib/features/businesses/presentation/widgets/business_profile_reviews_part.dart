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
  final BusinessProfileReviewsController _controller =
      BusinessProfileReviewsController();
  final BusinessProfileRepository _reviewsRepository =
      BusinessProfileRepository();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _controller.dispose();
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

    _controller.setSending(true);

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
        rating: _controller.selectedRating,
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
        _controller.setSending(false);
      }
    }
  }

  Future<void> _reportReview(_ReviewItem review) async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorumu raporlamak için giriş yapın.')),
      );
      return;
    }

    final created = await _reviewsRepository.reportReview(
      reviewId: review.id,
      businessId: widget.businessId,
      uid: user.uid,
      reason: 'review_report',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? 'Yorum inceleme icin raporlandi.'
              : 'Bu yorum daha once raporlanmis.',
        ),
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Column(
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
                    final selected = star <= _controller.selectedRating;

                    return IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _controller.selectRating(star),
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
                    onPressed: _controller.sending ? null : _sendReview,
                    child: Text(_controller.sending ? 'Gönderiliyor...' : 'Yorumu Gönder'),
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
                    trailing: IconButton(
                      tooltip: 'Yorumu raporla',
                      onPressed: () => _reportReview(review),
                      icon: const Icon(Icons.flag_outlined),
                    ),
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
      ),
    );
  }
}
