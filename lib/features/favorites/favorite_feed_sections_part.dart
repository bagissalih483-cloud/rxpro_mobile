part of 'favorite_feed_page.dart';

class _FavoritePostsSection extends StatelessWidget {
  const _FavoritePostsSection({
    required this.future,
    required this.onOpenBusiness,
  });

  final Future<_FavoriteFeedData>? future;
  final ValueChanged<_FavoritePostItem> onOpenBusiness;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FavoriteFeedData>(
      future: future,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            const _FavoriteFeedData(
              followedBusinessIds: {},
              followedBusinesses: [],
              posts: [],
            );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _FavoriteInfoCard(
            icon: Icons.hourglass_empty_rounded,
            title: 'Favori akış hazırlanıyor',
            text:
                'Takip ettiğiniz kurumsal kullanıcıların eski paylaşımları yükleniyor.',
          );
        }

        if (data.followedBusinessIds.isEmpty) {
          return _FavoriteInfoCard(
            icon: Icons.favorite_border_rounded,
            title: 'Henüz takip ettiğiniz kurumsal kullanıcı yok',
            text:
                'Henüz favori işletmen yok. Keşfetmeye başla, sevdiğin işletmeleri burada sakla.',
            actionText: 'Keşfetmeye Başla',
            onAction: () => FixShellNavState.setIndividualIndex(0),
          );
        }

        if (data.posts.isEmpty) {
          return _FavoriteInfoCard(
            icon: Icons.dynamic_feed_outlined,
            title: 'Henüz paylaşım yok',
            text:
                'Takip ettiğiniz kurumsal kullanıcılar paylaşım yaptığında içerikler burada otomatik görünür.',
          );
        }

        return Column(
          children: data.posts.map((post) {
            return _FavoritePostCard(
              post: post,
              onOpenBusiness: () => onOpenBusiness(post),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FollowedDirectSection extends StatelessWidget {
  const _FollowedDirectSection({
    required this.future,
    required this.onOpenBusiness,
  });

  final Future<_FavoriteFeedData>? future;
  final ValueChanged<_FavoriteFollowItem> onOpenBusiness;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FavoriteFeedData>(
      future: future,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            const _FavoriteFeedData(
              followedBusinessIds: {},
              followedBusinesses: [],
              posts: [],
            );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _FavoriteInfoCard(
            icon: Icons.storefront_outlined,
            title: 'Takip edilen işletmeler hazırlanıyor',
            text: 'Takip ettiğiniz kurumsal kullanıcılar yükleniyor.',
          );
        }

        if (data.followedBusinesses.isEmpty) {
          return _FavoriteInfoCard(
            icon: Icons.favorite_border_rounded,
            title: 'Henüz takip ettiğiniz kurumsal kullanıcı yok',
            text:
                'Keşfet ekranındaki işletme profillerinden Takip Et butonuna basınca burada görünür.',
            actionText: 'Keşfetmeye Başla',
            onAction: () => FixShellNavState.setIndividualIndex(0),
          );
        }

        return Column(
          children: data.followedBusinesses.map((item) {
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE9FE),
                  child: Icon(
                    Icons.storefront_outlined,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                title: Text(
                  item.businessName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  item.address.isEmpty
                      ? '${item.category} • Güncel profil'
                      : '${item.category} • ${item.address}',
                ),
                trailing: IconButton.filledTonal(
                  tooltip: 'Randevu Al',
                  onPressed: () => onOpenBusiness(item),
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
                onTap: () => onOpenBusiness(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SavedPostsSection extends StatelessWidget {
  const _SavedPostsSection({
    required this.future,
    required this.onOpenBusiness,
  });

  final Future<List<_FavoritePostItem>>? future;
  final ValueChanged<_FavoritePostItem> onOpenBusiness;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_FavoritePostItem>>(
      future: future,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? const <_FavoritePostItem>[];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _FavoriteInfoCard(
            icon: Icons.bookmark_border_rounded,
            title: 'Kaydettiklerim hazırlanıyor',
            text: 'Kaydettiğiniz paylaşımlar yükleniyor.',
          );
        }

        if (posts.isEmpty) {
          return _FavoriteInfoCard(
            icon: Icons.bookmark_border_rounded,
            title: 'Henüz kaydettiğiniz paylaşım yok',
            text:
                'Kurumsal kullanıcı paylaşımlarındaki kaydet ikonuna basınca burada görünür.',
            actionText: 'Keşfetmeye Başla',
            onAction: () => FixShellNavState.setIndividualIndex(0),
          );
        }

        return Column(
          children: posts.map((post) {
            return _FavoritePostCard(
              post: post,
              onOpenBusiness: () => onOpenBusiness(post),
            );
          }).toList(),
        );
      },
    );
  }
}
