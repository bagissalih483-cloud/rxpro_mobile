part of 'favorite_feed_page.dart';

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
  late final FavoriteFeedController<_FavoriteFeedData, List<_FavoritePostItem>>
  _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller =
        FavoriteFeedController<_FavoriteFeedData, List<_FavoritePostItem>>(
          loadFeed: _loadFeed,
          loadSaved: _loadSavedPosts,
          emptyFeed: () async => const _FavoriteFeedData(
            followedBusinessIds: {},
            followedBusinesses: [],
            posts: [],
          ),
          emptySaved: () async => const <_FavoritePostItem>[],
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _clean(dynamic value) => value?.toString().trim() ?? '';

  static String _firstNonEmpty(List<dynamic> values, [String fallback = '']) {
    for (final value in values) {
      final text = _clean(value);
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  void _ensureLoaded(String? uid) {
    _controller.ensureLoaded(uid);
  }

  Future<void> _refresh() async {
    final uid = _authService.currentUser?.uid;
    await _controller.refresh(uid);
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
        data[FirestoreFields.thumbnailUrl],
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
    Navigator.of(context).pushNamed(
      AppRoutes.businessProfile,
      arguments: BusinessProfileRouteArgs(
        businessId: post.businessId,
        businessName: post.businessName,
        category: post.businessCategory,
      ),
    );
  }

  void _openBusinessFollow(_FavoriteFollowItem item) {
    Navigator.of(context).pushNamed(
      AppRoutes.businessProfile,
      arguments: BusinessProfileRouteArgs(
        businessId: item.businessId,
        businessName: item.businessName,
        category: item.category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return StreamBuilder(
            stream: _authService.authStateChanges(),
            initialData: _authService.currentUser,
            builder: (context, snapshot) {
              final user = snapshot.data;
              _ensureLoaded(user?.uid);
              final selectedTab = _controller.selectedTab;

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
                    _controller.selectTab(index);
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
                    future: _controller.feedFuture,
                    onOpenBusiness: _openBusinessPost,
                  )
                else if (selectedTab == 1)
                  _FollowedDirectSection(
                    future: _controller.feedFuture,
                    onOpenBusiness: _openBusinessFollow,
                  )
                else
                  _SavedPostsSection(
                    future: _controller.savedFuture,
                    onOpenBusiness: _openBusinessPost,
                  ),
              ],
            ),
          );
            },
          );
        },
      ),
    );
  }
}
