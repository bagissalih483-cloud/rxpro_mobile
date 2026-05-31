part of 'favorite_feed_page.dart';

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
