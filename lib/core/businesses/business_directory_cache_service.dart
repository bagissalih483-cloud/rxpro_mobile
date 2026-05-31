import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

import 'data/business_directory_firestore_repository.dart';
import 'business_category.dart';
import 'business_directory_query_budget_policy.dart';
import 'business_geo_index.dart';
import 'business_location_data.dart';

/// 50C-K1: Business directory cache Firestore collection/field literals use
/// FirestoreCollections/FirestoreFields constants. Cache/discovery behavior is unchanged.
class BusinessDirectoryCacheService {
  BusinessDirectoryCacheService._();

  static final BusinessDirectoryCacheService instance =
      BusinessDirectoryCacheService._();

  List<BusinessDirectoryItem>? _cache;
  DateTime? _lastLoadedAt;
  Future<List<BusinessDirectoryItem>>? _activeLoad;
  final BusinessDirectoryFirestoreRepository _repository =
      BusinessDirectoryFirestoreRepository();

  static const Duration cacheTtl = Duration(minutes: 5);
  static const Duration _firestoreTimeout = Duration(seconds: 5);
  static const int _businessPageSize =
      BusinessDirectoryQueryBudgetPolicy.starterPageSize;
  static const int _businessPageCap =
      BusinessDirectoryQueryBudgetPolicy.starterPageCap;

  bool get _isFresh {
    final last = _lastLoadedAt;
    if (last == null) return false;

    return DateTime.now().difference(last) < cacheTtl;
  }

  Future<List<BusinessDirectoryItem>> getBusinesses({
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _cache != null && _isFresh) {
      return Future.value(_cache);
    }

    if (!forceRefresh && _activeLoad != null) {
      return _activeLoad!;
    }

    _activeLoad = _loadBusinesses();

    return _activeLoad!;
  }

  Future<List<BusinessDirectoryItem>> refresh() {
    _cache = null;
    _lastLoadedAt = null;
    _activeLoad = null;

    return getBusinesses(forceRefresh: true);
  }

  Future<List<BusinessDirectoryItem>> getBusinessesForExplore({
    Position? position,
    double radiusKm = 25,
    String categoryLabel = BusinessCategories.allLabel,
    bool forceRefresh = false,
  }) async {
    if (position == null) {
      return _loadStarterBusinesses(forceRefresh: forceRefresh);
    }

    final local = await _loadNearbyBusinesses(
      position: position,
      radiusKm: radiusKm,
    ).catchError((_) => <BusinessDirectoryItem>[]);
    if (local.length >=
        BusinessDirectoryQueryBudgetPolicy.nearbyFallbackMinLocalResults) {
      debugPrint(
        'FIX_EXPLORE_DIRECTORY_LOCAL_ONLY local=${local.length} '
        'fallback=skipped merged=${local.length}',
      );
      return local;
    }

    final fallback = await _loadNearbyFallbackBusinesses(
      position: position,
      radiusKm: radiusKm,
      forceRefresh: forceRefresh,
    ).catchError((_) => <BusinessDirectoryItem>[]);
    final localWithFallback = _mergeNearbyBusinesses(
      local: local,
      fallback: fallback,
      position: position,
    );

    debugPrint(
      'FIX_EXPLORE_DIRECTORY_LOCAL_ONLY local=${local.length} '
      'fallback=${fallback.length} merged=${localWithFallback.length}',
    );

    return localWithFallback;
  }

  Future<List<BusinessDirectoryItem>> _loadStarterBusinesses({
    required bool forceRefresh,
  }) async {
    final stopwatch = Stopwatch()..start();
    final local = await getBusinesses(
      forceRefresh: forceRefresh,
    ).catchError((_) => <BusinessDirectoryItem>[]);

    if (!forceRefresh) {
      debugPrint(
        'FIX_EXPLORE_DIRECTORY_STARTER local=${local.length} '
        'directory=0 merged=${local.length} mode=localOnly '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      return local;
    }

    debugPrint(
      'FIX_EXPLORE_DIRECTORY_STARTER local=${local.length} '
      'directory=0 merged=${local.length} mode=registeredOnly '
      'elapsedMs=${stopwatch.elapsedMilliseconds}',
    );

    return local;
  }

  Future<List<BusinessDirectoryItem>> _loadBusinesses() async {
    try {
      final docs = await _repository.loadBusinessDocs(
        pageSize: _businessPageSize,
        pageCap: _businessPageCap,
        timeout: _firestoreTimeout,
      );
      final list = docs
          .map(
            (doc) =>
                BusinessDirectoryItem.fromMap(doc.data, fallbackId: doc.id),
          )
          .toList();

      list.sort((a, b) => a.name.compareTo(b.name));

      _cache = list;
      _lastLoadedAt = DateTime.now();

      return list;
    } finally {
      _activeLoad = null;
    }
  }

  Future<List<BusinessDirectoryItem>> _loadNearbyBusinesses({
    required Position position,
    required double radiusKm,
  }) async {
    final results = await Future.wait<List<BusinessDirectoryItem>>([
      _loadNearbyCollection(
        collection: FirestoreCollections.businesses,
        position: position,
        radiusKm: radiusKm,
      ).catchError((_) => <BusinessDirectoryItem>[]),
      _loadNearbyCollection(
        collection: FirestoreCollections.businessPlaceIndex,
        position: position,
        radiusKm: radiusKm,
      ).catchError((_) => <BusinessDirectoryItem>[]),
    ]);
    final memberItems = results[0];
    final directoryItems = results[1];
    final byKey = <String, BusinessDirectoryItem>{};

    for (final item in <BusinessDirectoryItem>[
      ...memberItems,
      ...directoryItems,
    ]) {
      final key = item.placeId.trim().isNotEmpty
          ? 'place:${item.placeId.trim()}'
          : 'id:${item.id.trim()}';
      final existing = byKey[key];
      if (existing == null || (!existing.isMember && item.isMember)) {
        byKey[key] = item;
      }
    }

    return byKey.values.toList()..sort(
      (a, b) =>
          a.distanceKmFrom(position).compareTo(b.distanceKmFrom(position)),
    );
  }

  Future<List<BusinessDirectoryItem>> _loadNearbyFallbackBusinesses({
    required Position position,
    required double radiusKm,
    required bool forceRefresh,
  }) async {
    final items = await getBusinesses(forceRefresh: forceRefresh);
    final list = <BusinessDirectoryItem>[];

    for (final item in items) {
      if (!item.visible || !item.hasCoordinate) continue;

      final distance = item.distanceKmFrom(position);
      if (distance.isFinite && distance <= radiusKm) {
        list.add(item);
      }
    }

    list.sort(
      (a, b) =>
          a.distanceKmFrom(position).compareTo(b.distanceKmFrom(position)),
    );

    return list;
  }

  Future<List<BusinessDirectoryItem>> _loadNearbyCollection({
    required String collection,
    required Position position,
    required double radiusKm,
  }) async {
    final prefixField = BusinessGeoIndex.fieldForRadiusKm(radiusKm);
    final prefixes = BusinessGeoIndex.nearbyPrefixes(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusKm: radiusKm,
    );

    final docs = await _repository.loadNearbyDocs(
      collection: collection,
      prefixField: prefixField,
      prefixes: prefixes,
      limit: BusinessDirectoryQueryBudgetPolicy.nearbyCollectionLimit,
      timeout: _firestoreTimeout,
    );

    final byId = <String, BusinessDirectoryItem>{};
    for (final doc in docs) {
      final item = BusinessDirectoryItem.fromMap(doc.data, fallbackId: doc.id);
      if (!item.visible || !item.hasCoordinate) continue;
      final distance = item.distanceKmFrom(position);
      if (distance.isFinite && distance <= radiusKm) {
        byId[item.id] = item;
      }
    }

    final list = byId.values.toList()
      ..sort(
        (a, b) =>
            a.distanceKmFrom(position).compareTo(b.distanceKmFrom(position)),
      );

    return list;
  }

  List<BusinessDirectoryItem> _mergeNearbyBusinesses({
    required List<BusinessDirectoryItem> local,
    required List<BusinessDirectoryItem> fallback,
    required Position position,
  }) {
    final byKey = <String, BusinessDirectoryItem>{};

    void put(BusinessDirectoryItem item) {
      final key = item.placeId.trim().isNotEmpty
          ? 'place:${item.placeId.trim()}'
          : 'id:${item.id.trim()}';
      final existing = byKey[key];

      if (existing == null) {
        byKey[key] = item;
        return;
      }

      if (existing.isMember) return;
      if (item.isMember || existing.name.trim().isEmpty) {
        byKey[key] = item;
      }
    }

    for (final item in local) {
      put(item);
    }
    for (final item in fallback) {
      put(item);
    }

    return byKey.values.toList()..sort((a, b) {
      final distance = a
          .distanceKmFrom(position)
          .compareTo(b.distanceKmFrom(position));
      if (distance != 0) return distance;

      if (a.isMember != b.isMember) return a.isMember ? -1 : 1;
      return a.name.compareTo(b.name);
    });
  }
}

enum BusinessDirectoryMembership { member, directoryOnly }

class BusinessDirectoryItem {
  const BusinessDirectoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.phone,
    required this.city,
    required this.district,
    required this.neighborhood,
    required this.logoUrl,
    required this.mapsUrl,
    required this.placeId,
    required this.membership,
    required this.source,
    required this.lat,
    required this.lng,
    required this.visible,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.followerCount = 0,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final String phone;
  final String city;
  final String district;
  final String neighborhood;
  final String logoUrl;
  final String mapsUrl;
  final String placeId;
  final BusinessDirectoryMembership membership;
  final String source;
  final double? lat;
  final double? lng;
  final bool visible;
  final double ratingAvg;
  final int ratingCount;
  final int followerCount;

  bool get hasCoordinate => lat != null && lng != null;
  bool get isMember => membership == BusinessDirectoryMembership.member;

  String get locationLabel {
    final area = [
      neighborhood,
      district,
      city,
    ].where((e) => e.trim().isNotEmpty).join(' / ');
    if (area.isNotEmpty) return area;

    return address;
  }

  String get mapsDestination {
    if (hasCoordinate) {
      return '${lat!.toStringAsFixed(7)},${lng!.toStringAsFixed(7)}';
    }

    return address.trim().isNotEmpty ? address.trim() : name;
  }

  double distanceKmFrom(Position? position) {
    if (position == null || lat == null || lng == null) {
      return double.infinity;
    }

    return BusinessLocationParser.distanceKm(
      fromLat: position.latitude,
      fromLng: position.longitude,
      toLat: lat!,
      toLng: lng!,
    );
  }

  factory BusinessDirectoryItem.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    final location = BusinessLocationParser.fromMap(data);
    final category = _firstNonEmpty([
      _categoryFromDirectoryKey(data['category_key']),
      data[FirestoreFields.categoryLabel],
      data[FirestoreFields.category],
      data[FirestoreFields.businessCategory],
      _categoryFromGoogleTypes(data['types']),
    ]);

    final status = data[FirestoreFields.status]?.toString() ?? '';
    final accountStatus = data[FirestoreFields.accountStatus]?.toString() ?? '';
    final isActive = data[FirestoreFields.isActive];

    final visible =
        isActive == true ||
        status.isEmpty ||
        status == 'active' ||
        accountStatus == 'active';

    return BusinessDirectoryItem(
      id: _firstNonEmpty([
        data[FirestoreFields.id],
        data[FirestoreFields.businessId],
        data['doc_id'],
        data['placeId'],
        data['source_place_id'],
        fallbackId,
      ]),
      name: _firstNonEmpty([
        data[FirestoreFields.businessName],
        data[FirestoreFields.name],
        data[FirestoreFields.title],
        data['displayName'] is Map ? data['displayName']['text'] : null,
        'İşletme',
      ]),
      category: category,
      description: _firstNonEmpty([
        data[FirestoreFields.description],
        data[FirestoreFields.about],
        data['editorialSummary'],
        data['editorial_summary'],
      ]),
      address: location.address,
      phone: _firstNonEmpty([
        data[FirestoreFields.phone],
        data[FirestoreFields.phoneNumber],
        data['phone_national'],
        data['phone_international'],
        data['formattedPhoneNumber'],
        data['formatted_phone_number'],
        data['internationalPhoneNumber'],
        data['international_phone_number'],
        data['nationalPhoneNumber'],
      ]),
      city: _firstNonEmpty([
        data[FirestoreFields.city],
        data[FirestoreFields.province],
        data[FirestoreFields.il],
      ]),
      district: _firstNonEmpty([
        data[FirestoreFields.district],
        data[FirestoreFields.ilce],
      ]),
      neighborhood: _firstNonEmpty([
        data[FirestoreFields.neighborhood],
        data[FirestoreFields.mahalle],
        data['areaLabel'],
      ]),
      logoUrl: _firstNonEmpty([
        data[FirestoreFields.logoUrl],
        data[FirestoreFields.photoUrl],
        data[FirestoreFields.imageUrl],
      ]),
      mapsUrl: location.googleMapsUri,
      placeId: location.placeId,
      membership: _membership(data),
      source: _firstNonEmpty([
        data[FirestoreFields.source],
        data['provider'],
        data['sourceType'],
      ]),
      lat: location.lat,
      lng: location.lng,
      visible: visible,
      ratingAvg:
          _toDouble(data[FirestoreFields.ratingAvg]) ??
          _toDouble(data[FirestoreFields.rating]) ??
          0,
      ratingCount: _toInt(
        data[FirestoreFields.ratingCount] ?? data['user_rating_count'],
      ),
      followerCount: _toInt(data[FirestoreFields.followerCount]),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '');
  }

  static BusinessDirectoryMembership _membership(Map<String, dynamic> data) {
    bool truthy(dynamic value) {
      if (value is bool) return value;
      final text = value?.toString().trim().toLowerCase() ?? '';
      return text == 'true' ||
          text == '1' ||
          text == 'active' ||
          text == 'approved' ||
          text == 'member' ||
          text == 'claimed';
    }

    final ownerSignals = <dynamic>[
      data[FirestoreFields.ownerUid],
      data[FirestoreFields.businessOwnerUid],
      data[FirestoreFields.ownerId],
    ].where((value) => value?.toString().trim().isNotEmpty == true);

    if (ownerSignals.isNotEmpty) return BusinessDirectoryMembership.member;

    final listSignals = <dynamic>[
      data[FirestoreFields.ownerUids],
      data[FirestoreFields.owners],
      data[FirestoreFields.adminUids],
    ].where((value) => value is Iterable && value.isNotEmpty);

    if (listSignals.isNotEmpty) return BusinessDirectoryMembership.member;

    if (truthy(data['isRxProMember']) ||
        truthy(data['isMember']) ||
        truthy(data['member']) ||
        truthy(data['isClaimed']) ||
        truthy(data['claimed']) ||
        truthy(data['membershipStatus']) ||
        truthy(data['subscriptionStatus']) ||
        truthy(data[FirestoreFields.adminApproved])) {
      return BusinessDirectoryMembership.member;
    }

    return BusinessDirectoryMembership.directoryOnly;
  }

  static String _categoryFromGoogleTypes(dynamic value) {
    if (value is! Iterable) return '';

    final types = value
        .map((item) => item.toString().trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();

    if (types.any(
      (type) =>
          type.contains('beauty') ||
          type.contains('hair') ||
          type.contains('barber') ||
          type.contains('nail') ||
          type.contains('skin') ||
          type.contains('spa') ||
          type.contains('massage'),
    )) {
      return 'Güzellik & Bakım';
    }

    if (types.any(
      (type) =>
          type.contains('clinic') ||
          type.contains('medical') ||
          type.contains('health') ||
          type.contains('doctor') ||
          type.contains('dental') ||
          type.contains('dentist') ||
          type.contains('physiotherapist'),
    )) {
      return 'Sağlık & Klinik';
    }

    if (types.any(
      (type) =>
          type.contains('gym') ||
          type.contains('fitness') ||
          type.contains('sport') ||
          type.contains('yoga') ||
          type.contains('pilates'),
    )) {
      return 'Spor & Fitness';
    }

    if (types.any(
      (type) => type.contains('school') || type.contains('course'),
    )) {
      return 'Eğitim';
    }

    return '';
  }

  static String _categoryFromDirectoryKey(dynamic value) {
    final key = value?.toString().trim().toLowerCase() ?? '';
    if (key.isEmpty) return '';

    switch (key) {
      case 'beauty_care':
        return BusinessCategories.byId('beauty_care')?.label ?? '';
      case 'clinic_health':
      case 'health_clinic':
        return BusinessCategories.byId('health_clinic')?.label ?? '';
      case 'sport':
      case 'sport_fitness':
        return BusinessCategories.byId('sport_fitness')?.label ?? '';
      default:
        return '';
    }
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return _cleanLegacyEncoding(text);
    }

    return '';
  }

  static String _cleanLegacyEncoding(String text) {
    return text
        .replaceAll('Ä°', 'İ')
        .replaceAll('Ä±', 'ı')
        .replaceAll('ÄŸ', 'ğ')
        .replaceAll('Äž', 'Ğ')
        .replaceAll('Ã¼', 'ü')
        .replaceAll('Ãœ', 'Ü')
        .replaceAll('ÅŸ', 'ş')
        .replaceAll('Åž', 'Ş')
        .replaceAll('Ã¶', 'ö')
        .replaceAll('Ã–', 'Ö')
        .replaceAll('Ã§', 'ç')
        .replaceAll('Ã‡', 'Ç')
        .replaceAll('â€™', '’')
        .replaceAll('â€¢', '•');
  }
}
