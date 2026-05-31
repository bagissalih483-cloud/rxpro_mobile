part of '../../business_profile_page.dart';

class _IntroTab extends StatelessWidget {
  const _IntroTab({
    required this.businessId,
    required this.businessName,
    required this.category,
  });

  final String businessId;
  final String businessName;
  final String category;
  static final AuthService _authService = AuthService();

  Future<void> _openCreatePost(BuildContext context) async {
    final updated = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.businessProfilePostCreate,
      arguments: BusinessProfilePostCreateRouteArgs(
        businessId: businessId,
        businessName: businessName,
      ),
    );

    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanıtım akışı güncellendi.')),
      );
    }
  }

  Stream<List<_BusinessProfilePostItem>> _postsStream() {
    return BusinessProfileRepository()
        .watchBusinessPosts(businessId: businessId)
        .map((rows) {
          final list = rows.map((data) {
            return _BusinessProfilePostItem(
              id: data[FirestoreFields.id]?.toString() ?? '',
              text: data[FirestoreFields.text]?.toString() ?? '',
              imageUrl:
                  data[FirestoreFields.thumbnailUrl]?.toString() ??
                  data[FirestoreFields.imageUrl]?.toString() ??
                  data[FirestoreFields.mediaUrl]?.toString() ??
                  '',
              mediaType:
                  data[FirestoreFields.mediaType]?.toString() ??
                  data[FirestoreFields.type]?.toString() ??
                  'text',
              createdAt: data[FirestoreFields.createdAt]?.toString() ?? '',
              likeCount: _postInt(data[FirestoreFields.likeCount]),
              saveCount: _postInt(data[FirestoreFields.saveCount]),
              reportCount: _postInt(data[FirestoreFields.reportCount]),
            );
          }).toList();

          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  bool _canManageBusiness(Map<String, dynamic> data) {
    final user = _authService.currentUser;
    if (user == null) return false;

    final uid = user.uid;
    final email = user.email?.trim().toLowerCase() ?? '';

    String clean(dynamic value) => value?.toString().trim() ?? '';

    bool listContainsUid(dynamic value) {
      if (value is Iterable) {
        return value.map((e) => e.toString()).contains(uid);
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

    if (uidFields.contains(uid)) return true;

    if (listContainsUid(data[FirestoreFields.ownerUids]) ||
        listContainsUid(data[FirestoreFields.owners]) ||
        listContainsUid(data[FirestoreFields.adminUids]) ||
        listContainsUid(data[FirestoreFields.admins]) ||
        listContainsUid(data[FirestoreFields.managerUids]) ||
        listContainsUid(data[FirestoreFields.authorizedUids])) {
      return true;
    }

    if (email.isNotEmpty) {
      final emailFields = [
        clean(data[FirestoreFields.ownerEmail]).toLowerCase(),
        clean(data[FirestoreFields.businessEmail]).toLowerCase(),
        clean(data[FirestoreFields.createdByEmail]).toLowerCase(),
        clean(data[FirestoreFields.email]).toLowerCase(),
      ];

      if (emailFields.contains(email)) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: BusinessProfileRepository().watchBusinessProfile(
        businessId: businessId,
        includeMetadataChanges: false,
      ),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final description = data[FirestoreFields.description]?.toString() ?? '';
        final address = data[FirestoreFields.address]?.toString() ?? '';
        final workingHours =
            data[FirestoreFields.workingHours]?.toString() ?? '';
        final canManage = _canManageBusiness(data);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canManage) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openCreatePost(context),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Tanıtım İçeriği Paylaş'),
                ),
              ),
              const SizedBox(height: 10),
            ],
            _InfoCard(
              icon: Icons.info_outline,
              title: 'Tanıtım',
              text: description.trim().isEmpty
                  ? 'Bu kurumsal profil için tanıtım yazısı henüz eklenmedi. Kurumsal kullanıcı fotoğraf ve açıklama ekleyebilir.'
                  : description,
            ),
            _InfoCard(
              icon: Icons.schedule,
              title: 'Çalışma Saatleri',
              text: workingHours.trim().isEmpty
                  ? 'Çalışma saatleri henüz eklenmedi.'
                  : workingHours,
            ),
            _InfoCard(
              icon: Icons.location_on_outlined,
              title: 'Adres',
              text: address.trim().isEmpty
                  ? 'Adres bilgisi henüz eklenmedi.'
                  : address,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text('Kurumsal Paylaşımlar', style: RxText.sectionTitle),
            ),
            StreamBuilder<List<_BusinessProfilePostItem>>(
              stream: _postsStream(),
              builder: (context, postSnapshot) {
                final posts = postSnapshot.data ?? [];

                if (postSnapshot.connectionState == ConnectionState.waiting) {
                  return const _MiniLoadingCard(
                    text: 'Tanıtım içerikleri hazırlanıyor...',
                  );
                }

                if (posts.isEmpty) {
                  return const _InfoCard(
                    icon: Icons.photo_library_outlined,
                    title: 'Henüz paylaşım yok',
                    text:
                        'Kurumsal kullanıcı tanıtım fotoğrafı veya yazı paylaştığında burada görünür.',
                  );
                }

                return Column(
                  children: posts.map((post) {
                    return BusinessProfilePostInteractiveCard(
                      postId: post.id,
                      text: post.text,
                      imageUrl: post.imageUrl,
                      createdAt: post.createdAt,
                      likeCount: post.likeCount,
                      saveCount: post.saveCount,
                      reportCount: post.reportCount,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
