import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';
import 'package:rxpro_mobile/features/favorites/data/favorite_feed_repository.dart';

import '../business/widgets/business_profile_post_interactive_card.dart';
import '../businesses/business_profile_page.dart';

/// 50C-J2: Favorite feed behavior is unchanged.
class FavoriteFeedPage extends StatefulWidget {
  const FavoriteFeedPage({super.key});

  @override
  State<FavoriteFeedPage> createState() => _FavoriteFeedPageState();
}

class _FavoriteFeedPageState extends State<FavoriteFeedPage>
    with AutomaticKeepAliveClientMixin<FavoriteFeedPage> {
  final FavoriteFeedRepository _favoriteFeedRepository =
      FavoriteFeedRepository();
  final AuthService _authService = AuthService();
  int selectedTab = 0;
  String? loadedUid;

  Future<_FavoriteFeedData>? feedFuture;
  Future<List<_FavoritePostItem>>? savedFuture;

  @override
  bool get wantKeepAlive => true;

  static String _clean(dynamic value) => value?.toString().trim() ?? '';

  static String _firstNonEmpty(List<dynamic> values, [String fallback = '']) {
    for (final value in values) {
      final text = _clean(value);
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  void _ensureLoaded(String? uid) {
    if (uid == null || uid.isEmpty) {
      loadedUid = null;
      feedFuture = Future.value(
        const _FavoriteFeedData(
          followedBusinessIds: {},
          followedBusinesses: [],
          posts: [],
        ),
      );
      savedFuture = Future.value(const []);
      return;
    }

    if (loadedUid != uid || feedFuture == null || savedFuture == null) {
      loadedUid = uid;
      feedFuture = _loadFeed(uid);
      savedFuture = _loadSavedPosts(uid);
    }
  }

  Future<void> _refresh() async {
    final uid = _authService.currentUser?.uid;

    setState(() {
      loadedUid = null;
      _ensureLoaded(uid);
    });

    await Future.wait([
      feedFuture ?? Future.value(),
      savedFuture ?? Future.value(),
    ]);
  }

  _FavoritePostItem _favoritePostFromRepositoryDocument(
    FavoritePostDocument doc,
  ) {
    final data = doc.data;

    return _FavoritePostItem(
      id: doc.id,
      businessId: _firstNonEmpty([
        data[FirestoreFields.businessId],
        data[FirestoreFields.businessDocId],
      ]),
      businessName: _firstNonEmpty([
        data[FirestoreFields.businessName],
        data[FirestoreFields.name],
      ], 'Kurumsal Kullanıcı'),
      businessCategory: _firstNonEmpty([
        data[FirestoreFields.businessCategory],
        data[FirestoreFields.category],
      ], 'Genel'),
      text: _clean(data[FirestoreFields.text]),
      imageUrl: _firstNonEmpty([
        data[FirestoreFields.imageUrl],
        data[FirestoreFields.mediaUrl],
      ]),
      createdAt: _clean(data[FirestoreFields.createdAt]),
      likeCount: _toIntFavoriteFeedValue(data[FirestoreFields.likeCount]),
      saveCount: _toIntFavoriteFeedValue(data[FirestoreFields.saveCount]),
      reportCount: _toIntFavoriteFeedValue(data[FirestoreFields.reportCount]),
      isActive: data[FirestoreFields.isActive] != false,
    );
  }

  int _toIntFavoriteFeedValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<_FavoriteFeedData> _loadFeed(String uid) async {
    final bundle = await _favoriteFeedRepository.fetchFavoriteFeedBundle(
      uid: uid,
    );

    final followedBusinesses = bundle.followedBusinesses.map((doc) {
      final data = doc.data;

      return _FavoriteFollowItem(
        businessId: doc.id,
        businessName: _firstNonEmpty([
          data[FirestoreFields.businessName],
          data[FirestoreFields.name],
          data[FirestoreFields.title],
        ], 'Kurumsal Kullanıcı'),
        category: _firstNonEmpty([
          data[FirestoreFields.category],
          data[FirestoreFields.businessCategory],
          data[FirestoreFields.sector],
        ], 'Genel'),
        address: _firstNonEmpty([
          data[FirestoreFields.address],
          data[FirestoreFields.fullAddress],
          data[FirestoreFields.district],
          data[FirestoreFields.city],
        ]),
      );
    }).toList();

    followedBusinesses.sort((a, b) => a.businessName.compareTo(b.businessName));

    final posts = bundle.posts
        .map((doc) => _favoritePostFromRepositoryDocument(doc))
        .where((post) => post.isActive)
        .toList();

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _FavoriteFeedData(
      followedBusinessIds: bundle.followedBusinessIds,
      followedBusinesses: followedBusinesses,
      posts: posts,
    );
  }

  Future<List<_FavoritePostItem>> _loadSavedPosts(String uid) async {
    final docs = await _favoriteFeedRepository.fetchSavedPosts(uid: uid);

    final posts = docs
        .map((doc) => _favoritePostFromRepositoryDocument(doc))
        .where((post) => post.isActive)
        .toList();

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  void _openBusinessPost(_FavoritePostItem post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessProfilePage(
          businessId: post.businessId,
          businessName: post.businessName,
          category: post.businessCategory,
        ),
      ),
    );
  }

  void _openBusinessFollow(_FavoriteFollowItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessProfilePage(
          businessId: item.businessId,
          businessName: item.businessName,
          category: item.category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder(
      stream: _authService.authStateChanges(),
      initialData: _authService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        _ensureLoaded(user?.uid);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const _FavoriteHeader(),
              const SizedBox(height: 12),
              _FavoriteTabs(
                selectedIndex: selectedTab,
                onChanged: (index) {
                  setState(() => selectedTab = index);
                },
              ),
              const SizedBox(height: 14),
              if (user == null)
                const _FavoriteInfoCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Giriş yapmanız gerekiyor',
                  text:
                      'Takip ettiğiniz kurumsal kullanıcıları ve kaydettiğiniz paylaşımları görmek için giriş yapın.',
                )
              else if (selectedTab == 0)
                _FavoritePostsSection(
                  future: feedFuture,
                  onOpenBusiness: _openBusinessPost,
                )
              else if (selectedTab == 1)
                _FollowedDirectSection(
                  future: feedFuture,
                  onOpenBusiness: _openBusinessFollow,
                )
              else
                _SavedPostsSection(
                  future: savedFuture,
                  onOpenBusiness: _openBusinessPost,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FavoriteHeader extends StatelessWidget {
  const _FavoriteHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favori',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 4),
        Text(
          'Takip ettiğiniz kurumsal kullanıcılar, paylaşımlar ve kaydedilen içerikler.',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FavoriteTabs extends StatelessWidget {
  const _FavoriteTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      _FavoriteTabData(Icons.dynamic_feed_outlined, 'Paylaşımlar'),
      _FavoriteTabData(Icons.storefront_outlined, 'Takip'),
      _FavoriteTabData(Icons.bookmark_border_rounded, 'Kaydettiklerim'),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = selectedIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 19,
                      color: selected
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF6B7280),
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

class _FavoriteTabData {
  const _FavoriteTabData(this.icon, this.label);

  final IconData icon;
  final String label;
}

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
          return const _FavoriteInfoCard(
            icon: Icons.hourglass_empty_rounded,
            title: 'Favori akış hazırlanıyor',
            text:
                'Takip ettiğiniz kurumsal kullanıcıların eski paylaşımları yükleniyor.',
          );
        }

        if (data.followedBusinessIds.isEmpty) {
          return const _FavoriteInfoCard(
            icon: Icons.favorite_border_rounded,
            title: 'Henüz takip ettiğiniz kurumsal kullanıcı yok',
            text:
                'Kurumsal kullanıcıları takip edince eski ve yeni paylaşımları burada görünür.',
          );
        }

        if (data.posts.isEmpty) {
          return const _FavoriteInfoCard(
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
          return const _FavoriteInfoCard(
            icon: Icons.storefront_outlined,
            title: 'Takip edilen işletmeler hazırlanıyor',
            text: 'Takip ettiğiniz kurumsal kullanıcılar yükleniyor.',
          );
        }

        if (data.followedBusinesses.isEmpty) {
          return const _FavoriteInfoCard(
            icon: Icons.favorite_border_rounded,
            title: 'Henüz takip ettiğiniz kurumsal kullanıcı yok',
            text:
                'Kurumsal Kullanıcı profiline girip Takip Et butonuna basınca burada doğrudan görünür.',
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
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
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
          return const _FavoriteInfoCard(
            icon: Icons.bookmark_border_rounded,
            title: 'Kaydettiklerim hazırlanıyor',
            text: 'Kaydettiğiniz paylaşımlar yükleniyor.',
          );
        }

        if (posts.isEmpty) {
          return const _FavoriteInfoCard(
            icon: Icons.bookmark_border_rounded,
            title: 'Henüz kaydettiğiniz paylaşım yok',
            text:
                'Kurumsal kullanıcı paylaşımlarındaki kaydet ikonuna basınca burada görünür.',
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

class _FavoriteInfoCard extends StatelessWidget {
  const _FavoriteInfoCard({
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF7C3AED), size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritePostCard extends StatelessWidget {
  const _FavoritePostCard({required this.post, required this.onOpenBusiness});

  final _FavoritePostItem post;
  final VoidCallback onOpenBusiness;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F7FA),
              child: Icon(Icons.storefront_outlined, color: Color(0xFF18B7C9)),
            ),
            title: Text(
              post.businessName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(post.businessCategory),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: onOpenBusiness,
          ),
        ),
        BusinessProfilePostInteractiveCard(
          postId: post.id,
          text: post.text,
          imageUrl: post.imageUrl,
          createdAt: post.createdAt,
          likeCount: post.likeCount,
          saveCount: post.saveCount,
          reportCount: post.reportCount,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _FavoriteFeedData {
  const _FavoriteFeedData({
    required this.followedBusinessIds,
    required this.followedBusinesses,
    required this.posts,
  });

  final Set<String> followedBusinessIds;
  final List<_FavoriteFollowItem> followedBusinesses;
  final List<_FavoritePostItem> posts;
}

class _FavoriteFollowItem {
  const _FavoriteFollowItem({
    required this.businessId,
    required this.businessName,
    required this.category,
    required this.address,
  });

  final String businessId;
  final String businessName;
  final String category;
  final String address;
}

class _FavoritePostItem {
  const _FavoritePostItem({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessCategory,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
    required this.likeCount,
    required this.saveCount,
    required this.reportCount,
    required this.isActive,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String businessCategory;
  final String text;
  final String imageUrl;
  final String createdAt;
  final int likeCount;
  final int saveCount;
  final int reportCount;
  final bool isActive;
}
