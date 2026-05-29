import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessStoryModel {
  const BusinessStoryModel({
    required this.id,
    required this.businessId,
    required this.businessOwnerUid,
    required this.businessName,
    required this.businessLogoUrl,
    required this.category,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.mediaType,
    required this.caption,
    required this.storyType,
    required this.campaignId,
    required this.createdAt,
    required this.expiresAt,
    required this.active,
    required this.viewCount,
  });

  final String id;
  final String businessId;
  final String businessOwnerUid;
  final String businessName;
  final String businessLogoUrl;
  final String category;
  final String mediaUrl;
  final String thumbnailUrl;
  final String mediaType;
  final String caption;
  final String storyType;
  final String campaignId;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool active;
  final int viewCount;

  bool get isExpired {
    final expires = expiresAt;
    if (expires == null) return false;
    return expires.isBefore(DateTime.now());
  }

  bool get visibleNow => active && !isExpired && mediaUrl.trim().isNotEmpty;

  factory BusinessStoryModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return BusinessStoryModel(
      id: doc.id,
      businessId: _first([
        data['businessId'],
        data['businessDocId'],
        data['targetBusinessId'],
      ]),
      businessOwnerUid: _first([
        data['businessOwnerUid'],
        data['ownerUid'],
        data['createdBy'],
        data['userId'],
      ]),
      businessName: _first([
        data['businessName'],
        data['name'],
        'Kurumsal Kullanıcı',
      ], 'Kurumsal Kullanıcı'),
      businessLogoUrl: _first([
        data['businessLogoUrl'],
        data['logoUrl'],
        data['photoUrl'],
      ]),
      category: _first([
        data['category'],
        data['businessCategory'],
        'Genel',
      ], 'Genel'),
      mediaUrl: _first([data['mediaUrl'], data['imageUrl'], data['photoUrl']]),
      thumbnailUrl: _first([data['thumbnailUrl'], data['thumbUrl']]),
      mediaType: _first([data['mediaType'], 'image'], 'image'),
      caption: _first([data['caption'], data['text'], data['description']]),
      storyType: _first([data['storyType'], 'normal'], 'normal'),
      campaignId: _first([data['campaignId']]),
      createdAt: _toDate(data['createdAt'] ?? data['createdAtIso']),
      expiresAt: _toDate(data['expiresAt'] ?? data['expiresAtIso']),
      active: data['active'] != false && data['isActive'] != false,
      viewCount: _toInt(data['viewCount']),
    );
  }

  static String _first(List<dynamic> values, [String fallback = '']) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
