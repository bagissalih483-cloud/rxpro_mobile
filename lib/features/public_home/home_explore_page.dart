import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/app_routes.dart';
import '../../core/businesses/business_directory_cache_service.dart';
import '../../core/businesses/business_directions_service.dart';
import '../../core/businesses/business_category.dart';
import '../../core/diagnostics/rx_runtime_diagnostics.dart';
import '../../core/services/app_observability_service.dart';
import '../../core/session/app_session_scope.dart';
import '../guest/guest_required_sheet.dart';
import 'domain/home_explore_category_counts.dart';
import 'domain/home_explore_location_policy.dart';
import 'presentation/widgets/home_explore_content_list.dart';
import 'presentation/widgets/home_explore_filter_widgets.dart';
import 'presentation/widgets/home_explore_shell_widgets.dart';
import 'data/home_explore_badge_repository.dart';
import 'data/home_explore_claim_repository.dart';
import 'data/home_explore_session_repository.dart';

enum _ExploreSortMode { recommended, distance, rating, category, name }

class _DetectedExploreArea {
  const _DetectedExploreArea({required this.city, required this.district});

  final String city;
  final String district;
}

/// Public home/explore UI keeps Firebase badge and auth access behind
/// repository boundaries.
class HomeExplorePage extends StatefulWidget {
  const HomeExplorePage({
    super.key,
    this.previewMode = false,
    this.notificationBusinessId,
    this.notificationBusinessName,
  });

  final bool previewMode;
  final String? notificationBusinessId;
  final String? notificationBusinessName;

  @override
  State<HomeExplorePage> createState() => _HomeExplorePageState();
}

class _HomeExplorePageState extends State<HomeExplorePage> {
  final HomeExploreBadgeRepository _badgeRepository =
      HomeExploreBadgeRepository();
  final HomeExploreSessionRepository _sessionRepository =
      HomeExploreSessionRepository();
  final HomeExploreClaimRepository _claimRepository =
      HomeExploreClaimRepository();
  final BusinessDirectionsService _directionsService =
      const BusinessDirectionsService();
  final TextEditingController searchController = TextEditingController();
  final ScrollController _exploreScrollController = ScrollController(
    keepScrollOffset: false,
  );

  StreamSubscription<String?>? _authSub;
  String? _lastUid;

  List<BusinessDirectoryItem> _businesses = <BusinessDirectoryItem>[];
  bool _loadingBusinesses = false;
  Object? _businessLoadError;
  int _businessLoadTicket = 0;
  bool _hasCompletedInitialBusinessLoad = false;

  Position? currentPosition;
  Position? _lastLocationQueryPosition;
  String _detectedCity = '';
  String _detectedDistrict = '';
  bool loadingLocation = false;

  String selectedCategory = BusinessCategories.allLabel;
  double radiusKm = 10;
  _ExploreSortMode sortMode = _ExploreSortMode.recommended;

  @override
  void initState() {
    super.initState();

    _lastUid = _sessionRepository.currentUid();
    _authSub = _sessionRepository.watchUid().listen((nextUid) {
      if (nextUid == _lastUid) return;
      _lastUid = nextUid;

      if (!mounted) return;

      setState(() {
        searchController.clear();
        selectedCategory = BusinessCategories.allLabel;
        radiusKm = 10;
        sortMode = _ExploreSortMode.recommended;
        currentPosition = null;
        _detectedCity = '';
        _detectedDistrict = '';
      });

      _startInitialExploreLoadIfEnabled(reason: 'auth_change');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialExploreLoadIfEnabled(reason: 'post_frame');
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _exploreScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<List<BusinessDirectoryItem>> _loadExploreBusinesses({
    Position? position,
    bool forceRefresh = false,
  }) {
    final targetPosition = position ?? currentPosition;
    return BusinessDirectoryCacheService.instance.getBusinessesForExplore(
      position: targetPosition,
      radiusKm: radiusKm,
      categoryLabel: selectedCategory,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _startInitialExploreLoad({bool forceRefresh = false}) async {
    await _reloadExploreBusinesses(forceRefresh: forceRefresh);
  }

  void _startInitialExploreLoadIfEnabled({required String reason}) {
    if (RxRuntimeDiagnostics.disableExploreAutoLoad) {
      debugPrint('FIX_EXPLORE_AUTO_LOAD_DISABLED reason=$reason');
      return;
    }

    unawaited(_startInitialExploreLoad());
  }

  Future<bool> _reloadExploreBusinesses({
    Position? position,
    bool forceRefresh = false,
    bool replaceWithEmpty = false,
  }) async {
    final ticket = ++_businessLoadTicket;
    final targetPosition = position ?? currentPosition;
    final stopwatch = Stopwatch()..start();

    if (mounted) {
      setState(() {
        _loadingBusinesses = true;
        _businessLoadError = null;
      });
    }

    debugPrint(
      'FIX_EXPLORE_LOAD_START ticket=$ticket '
      'category="$selectedCategory" radiusKm=${radiusKm.round()} '
      'hasPosition=${targetPosition != null} force=$forceRefresh',
    );

    try {
      final items = await _loadExploreBusinesses(
        position: targetPosition,
        forceRefresh: forceRefresh,
      ).timeout(const Duration(seconds: 12));

      if (!mounted || ticket != _businessLoadTicket) return false;

      final area = _detectAreaFromNearestBusiness(
        items: items,
        position: targetPosition,
      );

      setState(() {
        if (replaceWithEmpty || items.isNotEmpty || _businesses.isEmpty) {
          _businesses = items;
        }
        if (area != null) {
          _detectedCity = area.city;
          _detectedDistrict = area.district;
        } else if (targetPosition == null) {
          _detectedCity = '';
          _detectedDistrict = '';
        }
        _hasCompletedInitialBusinessLoad = true;
      });

      debugPrint(
        'FIX_EXPLORE_LOAD_DONE ticket=$ticket count=${items.length} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      return true;
    } catch (error) {
      debugPrint(
        'FIX_EXPLORE_LOAD_FAILED ticket=$ticket '
        'elapsedMs=${stopwatch.elapsedMilliseconds} error=$error',
      );

      if (!mounted || ticket != _businessLoadTicket) return false;

      setState(() {
        _businessLoadError = error;
        _hasCompletedInitialBusinessLoad = true;
      });
      return true;
    } finally {
      if (mounted && ticket == _businessLoadTicket) {
        setState(() => _loadingBusinesses = false);
      }
    }
  }

  Future<void> _requestLocation() async {
    if (loadingLocation) return;

    setState(() => loadingLocation = true);

    try {
      final enabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (!enabled) {
        unawaited(
          AppObservabilityService.instance.logLocationPermissionResult(
            status: 'service_disabled',
          ),
        );
        _snack('Telefon konum servisi kapalı. Lütfen konumu açın.');
        return;
      }

      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 2),
      );

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        unawaited(
          AppObservabilityService.instance.logLocationPermissionResult(
            status: permission.name,
          ),
        );
        _snack('Konum izni verilmedi.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      unawaited(
        AppObservabilityService.instance.logLocationPermissionResult(
          status: 'granted',
        ),
      );
      setState(() {
        currentPosition = position;
        if (sortMode == _ExploreSortMode.distance) {
          sortMode = _ExploreSortMode.recommended;
        }
      });
      if (!_shouldRunLocationQuery(position) && _businesses.isNotEmpty) {
        _snack(
          'Konumun 1 km içinde değişmedi. Mevcut yakın işletme listesi gösteriliyor.',
        );
        _scrollExploreToTop();
        return;
      }

      await _reloadExploreBusinesses(
        position: position,
        forceRefresh: true,
        replaceWithEmpty: true,
      ).then((applied) {
        if (applied) {
          _lastLocationQueryPosition = position;
          _scrollExploreToTop();
        }
      });

      if (!mounted) return;
      final count = _filteredBusinesses(_businesses).length;
      _snack(
        count == 0
            ? 'Bu kilometre aralığında işletme bulunamadı. Mesafeyi artırmayı deneyin.'
            : '$count yakın işletme listelendi.',
      );
    } catch (e) {
      _snack('Konum alınamadı: $e');
    } finally {
      if (mounted) {
        setState(() => loadingLocation = false);
      }
    }
  }

  Future<void> _refreshBusinesses() async {
    if (currentPosition != null) {
      await _requestLocation();
      return;
    }

    await _reloadExploreBusinesses(forceRefresh: true, replaceWithEmpty: true);
  }

  bool _shouldRunLocationQuery(Position position) =>
      HomeExploreLocationPolicy.shouldRunLocationQuery(
        latitude: position.latitude,
        longitude: position.longitude,
        previousLatitude: _lastLocationQueryPosition?.latitude,
        previousLongitude: _lastLocationQueryPosition?.longitude,
      );

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollExploreToTop() {
    if (!_exploreScrollController.hasClients) return;

    unawaited(
      _exploreScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _openBusiness(BusinessDirectoryItem item) {
    unawaited(
      AppObservabilityService.instance.logExploreBusinessOpen(
        businessId: item.id,
        category: item.category,
        isMember: item.isMember,
      ),
    );

    if (!item.isMember) {
      _openDirections(item);
      return;
    }

    if (!_sessionRepository.isSignedIn) {
      GuestRequiredSheet.show(
        context,
        title: 'Üyelik gerekiyor',
        message:
            'Kurumsal profili görüntülemek ve randevu almak için bireysel hesapla giriş yapmanız gerekir.',
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.businessProfile,
      arguments: BusinessProfileRouteArgs(
        businessId: item.id,
        businessName: item.name,
        category: item.category,
      ),
    );
  }

  Future<void> _openDirections(BusinessDirectoryItem item) async {
    final opened = await _directionsService.openDirections(
      business: item,
      origin: currentPosition,
    );

    if (!opened) {
      _snack('Yol tarifi açılmadı. İşletmenin konum veya adres bilgisi eksik.');
    }
  }

  Future<void> _claimBusiness(BusinessDirectoryItem item) async {
    if (item.isMember) return;

    if (!_sessionRepository.isSignedIn) {
      GuestRequiredSheet.show(
        context,
        title: 'İşletme sahiplenme',
        message:
            'Bu işletmenin size ait olduğunu bildirmek için önce hesapla giriş yapmanız gerekir.',
      );
      return;
    }

    try {
      await _claimRepository.submitClaimRequest(item);
      unawaited(
        AppObservabilityService.instance.logBusinessClaimSubmitted(
          placeId: item.placeId,
          category: item.category,
        ),
      );
      _snack(
        'Sahiplenme talebin alındı. Doğrulama sonrası işletme tam profile çevrilecek.',
      );
    } on HomeExploreClaimException catch (e) {
      if (e.code == 'missingPlaceId') {
        _snack('Bu işletme için doğrulanabilir Google placeId bulunamadı.');
        return;
      }
      _snack('Sahiplenme talebi oluşturulamadı.');
    } catch (e) {
      _snack('Sahiplenme talebi oluşturulamadı: $e');
    }
  }

  void _openMessages() {
    if (!_sessionRepository.isSignedIn) {
      GuestRequiredSheet.show(
        context,
        title: 'Giriş yapmanız gerekiyor',
        message:
            'Mesajlarınızı görüntülemek için bireysel veya kurumsal hesapla giriş yapmanız gerekir.',
      );
      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.messagesInbox);
  }

  void _openNotifications() {
    if (!_sessionRepository.isSignedIn) {
      GuestRequiredSheet.show(
        context,
        title: 'Giriş yapmanız gerekiyor',
        message:
            'Bildirimlerinizi görüntülemek ve randevu güncellemelerini takip etmek için giriş yapmanız gerekir.',
      );
      return;
    }

    final session = AppSessionScope.maybeOf(context);
    final sessionBusinessId = session?.isCorporate == true
        ? session!.businessId.trim()
        : '';
    final widgetBusinessId = (widget.notificationBusinessId ?? '').trim();
    final bid = widgetBusinessId.isNotEmpty
        ? widgetBusinessId
        : sessionBusinessId;
    final widgetBusinessName = widget.notificationBusinessName?.trim();
    final businessName = widgetBusinessName?.isNotEmpty == true
        ? widgetBusinessName
        : session?.businessName;

    Navigator.of(context).pushNamed(
      AppRoutes.notificationCenter,
      arguments: NotificationCenterRouteArgs(
        businessId: bid.isEmpty ? null : bid,
        businessName: businessName,
      ),
    );
  }

  Stream<int> _liveUnreadMessagesCountStream() {
    final uid = _sessionRepository.currentUid();
    if (uid == null) return Stream<int>.value(0);

    final session = AppSessionScope.maybeOf(context);
    final sessionBusinessId = session?.isCorporate == true
        ? session!.businessId.trim()
        : '';
    final widgetBusinessId = (widget.notificationBusinessId ?? '').trim();
    final businessId = widgetBusinessId.isNotEmpty
        ? widgetBusinessId
        : sessionBusinessId;
    final useBusinessBadge =
        (widget.previewMode || session?.isCorporate == true) &&
        businessId.isNotEmpty;

    return _badgeRepository.watchUnreadMessagesCount(
      uid: uid,
      previewMode: useBusinessBadge,
      businessId: businessId,
    );
  }

  Stream<int> _liveUnreadNotificationsCountStream() {
    final uid = _sessionRepository.currentUid();
    if (uid == null) return Stream<int>.value(0);

    final session = AppSessionScope.maybeOf(context);
    final sessionBusinessId = session?.isCorporate == true
        ? session!.businessId.trim()
        : '';
    final widgetBusinessId = (widget.notificationBusinessId ?? '').trim();
    final businessId = widgetBusinessId.isNotEmpty
        ? widgetBusinessId
        : sessionBusinessId;
    final useBusinessBadge =
        (widget.previewMode || session?.isCorporate == true) &&
        businessId.isNotEmpty;

    return _badgeRepository.watchUnreadNotificationsCount(
      uid: uid,
      previewMode: useBusinessBadge,
      businessId: businessId,
    );
  }

  List<BusinessDirectoryItem> _filteredBusinesses(
    List<BusinessDirectoryItem> items,
  ) {
    final query = searchController.text.trim().toLowerCase();

    final filtered = items.where((item) {
      if (!item.visible) return false;

      if (!BusinessCategories.matches(
        selectedLabel: selectedCategory,
        businessCategory: item.category,
      )) {
        return false;
      }

      if (query.isNotEmpty) {
        final searchable = [
          item.name,
          item.category,
          item.description,
          item.city,
          item.district,
          item.neighborhood,
        ].join(' ').toLowerCase();

        if (!searchable.contains(query)) return false;
      }

      if (currentPosition != null) {
        if (!item.hasCoordinate) return false;
        final distance = item.distanceKmFrom(currentPosition);
        if (distance.isFinite && distance > radiusKm) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (sortMode) {
        case _ExploreSortMode.distance:
          return _compareDistance(a, b);
        case _ExploreSortMode.rating:
          return _compareRating(a, b);
        case _ExploreSortMode.category:
          final category = a.category.compareTo(b.category);
          if (category != 0) return category;
          return _compareDistance(a, b);
        case _ExploreSortMode.name:
          return a.name.compareTo(b.name);
        case _ExploreSortMode.recommended:
          if (currentPosition != null) return _compareDistance(a, b);

          final score = _businessScore(b).compareTo(_businessScore(a));
          if (score != 0) return score;
          return _compareDistance(a, b);
      }
    });

    return filtered;
  }

  _DetectedExploreArea? _detectAreaFromNearestBusiness({
    required List<BusinessDirectoryItem> items,
    required Position? position,
  }) {
    if (position == null) return null;

    BusinessDirectoryItem? nearest;
    var nearestDistance = double.infinity;
    for (final item in items) {
      if (!item.visible || !item.hasCoordinate) continue;
      if (item.district.trim().isEmpty && item.city.trim().isEmpty) continue;

      final distance = item.distanceKmFrom(position);
      if (!distance.isFinite || distance >= nearestDistance) continue;

      nearest = item;
      nearestDistance = distance;
    }

    if (nearest == null) return null;

    return _DetectedExploreArea(
      city: nearest.city.trim(),
      district: nearest.district.trim(),
    );
  }

  int _compareDistance(BusinessDirectoryItem a, BusinessDirectoryItem b) {
    final distance = a
        .distanceKmFrom(currentPosition)
        .compareTo(b.distanceKmFrom(currentPosition));
    if (distance != 0) return distance;

    if (a.isMember != b.isMember) return a.isMember ? -1 : 1;

    return _compareRating(a, b);
  }

  int _compareRating(BusinessDirectoryItem a, BusinessDirectoryItem b) {
    final ratingCompare = b.ratingAvg.compareTo(a.ratingAvg);
    if (ratingCompare != 0) return ratingCompare;

    final followerCompare = b.followerCount.compareTo(a.followerCount);
    if (followerCompare != 0) return followerCompare;

    return a.name.compareTo(b.name);
  }

  double _businessScore(BusinessDirectoryItem item) {
    final distance = item.distanceKmFrom(currentPosition);
    final distanceScore = distance.isFinite
        ? 60 - (distance > 60 ? 60 : distance)
        : 0;
    final memberBoost = item.isMember ? 35 : 0;
    final ratingScore = item.ratingAvg * 8;
    final popularityScore = item.followerCount > 500
        ? 20
        : item.followerCount / 25;
    final coordinateBoost = item.hasCoordinate ? 5 : 0;

    return distanceScore +
        memberBoost +
        ratingScore +
        popularityScore +
        coordinateBoost;
  }

  List<String> _categories() {
    return <String>[BusinessCategories.allLabel, ...BusinessCategories.labels];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7FBFC),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Builder(
                builder: (context) {
                  final allItems = _businesses;
                  final filtered = _filteredBusinesses(allItems);
                  final categories = _categories();
                  final categoryCounts = HomeExploreCategoryCounts.build(
                    items: allItems,
                    categories: categories,
                    queryText: searchController.text,
                    currentPosition: currentPosition,
                    radiusKm: radiusKm,
                  );
                  final waitingForManualLoad =
                      RxRuntimeDiagnostics.disableExploreAutoLoad &&
                      !_hasCompletedInitialBusinessLoad &&
                      !_loadingBusinesses &&
                      allItems.isEmpty;
                  if (RxRuntimeDiagnostics.verboseExploreRender) {
                    debugPrint(
                      'FIX_EXPLORE_RENDER all=${allItems.length} '
                      'filtered=${filtered.length} loading=$_loadingBusinesses '
                      'done=$_hasCompletedInitialBusinessLoad '
                      'manualWait=$waitingForManualLoad '
                      'detectedCity=$_detectedCity '
                      'detectedDistrict=$_detectedDistrict '
                      'error=${_businessLoadError != null} '
                      'screen=${MediaQuery.sizeOf(context)}',
                    );
                  }

                  return HomeExploreContentList(
                    loadingBusinesses: _loadingBusinesses,
                    hasCompletedInitialBusinessLoad:
                        _hasCompletedInitialBusinessLoad,
                    businessLoadError: _businessLoadError,
                    waitingForManualLoad: waitingForManualLoad,
                    allItems: allItems,
                    filteredItems: filtered,
                    categories: categories,
                    categoryCounts: categoryCounts,
                    searchController: searchController,
                    selectedCategory: selectedCategory,
                    currentPosition: currentPosition,
                    radiusKm: radiusKm,
                    filterPanel: _buildFilterPanel(),
                    scrollController: _exploreScrollController,
                    onRefresh: _refreshBusinesses,
                    onSearchChanged: () => setState(() {}),
                    onSearchCleared: () {
                      searchController.clear();
                      setState(() {});
                    },
                    onCategorySelected: (category) {
                      setState(() => selectedCategory = category);
                      unawaited(
                        _reloadExploreBusinesses(
                          position: currentPosition,
                          forceRefresh: true,
                          replaceWithEmpty: true,
                        ),
                      );
                    },
                    onManualLoad: () => unawaited(
                      _reloadExploreBusinesses(
                        forceRefresh: true,
                        replaceWithEmpty: true,
                      ),
                    ),
                    onResetFilters: () {
                      setState(() {
                        searchController.clear();
                        selectedCategory = BusinessCategories.allLabel;
                        radiusKm = 10;
                      });
                      unawaited(
                        _reloadExploreBusinesses(
                          forceRefresh: true,
                          replaceWithEmpty: true,
                        ),
                      );
                    },
                    onOpenBusiness: _openBusiness,
                    onOpenDirections: _openDirections,
                    onClaimBusiness: _claimBusiness,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final session = AppSessionScope.maybeOf(context);
    final businessPhotoUrl =
        (session?.businessData['logoUrl'] ??
                session?.businessData['photoUrl'] ??
                session?.businessData['imageUrl'] ??
                '')
            .toString()
            .trim();
    final userPhotoUrl =
        (session?.userData['photoUrl'] ??
                session?.userData['imageUrl'] ??
                session?.userData['avatarUrl'] ??
                '')
            .toString()
            .trim();
    final photoUrl = businessPhotoUrl.isNotEmpty
        ? businessPhotoUrl
        : userPhotoUrl;
    final sessionBusinessName = session?.businessName.trim() ?? '';
    final displayName = widget.previewMode
        ? (sessionBusinessName.isNotEmpty ? sessionBusinessName : 'fix')
        : session?.isAuthenticated == true
        ? session!.displayName
        : 'Misafir';

    return ExploreHomeHeader(
      displayName: displayName,
      photoUrl: photoUrl,
      showName: !(widget.previewMode || session?.isCorporate == true),
      messagesButton: StreamBuilder<int>(
        stream: _liveUnreadMessagesCountStream(),
        builder: (context, snapshot) {
          return ExploreHeaderIconButton(
            icon: Icons.chat_bubble_outline,
            count: snapshot.data ?? 0,
            onTap: _openMessages,
          );
        },
      ),
      notificationsButton: StreamBuilder<int>(
        stream: _liveUnreadNotificationsCountStream(),
        builder: (context, snapshot) {
          return ExploreHeaderIconButton(
            icon: Icons.notifications_none_rounded,
            count: snapshot.data ?? 0,
            onTap: _openNotifications,
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel() {
    return HomeExploreControlPanel<_ExploreSortMode>(
      hasPosition: currentPosition != null,
      loadingLocation: loadingLocation,
      radiusKm: radiusKm,
      onLocationPressed: _requestLocation,
      onRadiusChanged: (value) => setState(() => radiusKm = value),
      onRadiusChangeEnd: (_) {
        if (currentPosition != null) {
          unawaited(
            _reloadExploreBusinesses(
              position: currentPosition,
              forceRefresh: true,
              replaceWithEmpty: true,
            ).then((applied) {
              if (applied) _lastLocationQueryPosition = currentPosition;
            }),
          );
          return;
        }

        unawaited(
          _reloadExploreBusinesses(forceRefresh: true, replaceWithEmpty: true),
        );
      },
      sortModes: const [
        _ExploreSortMode.recommended,
        _ExploreSortMode.rating,
        _ExploreSortMode.category,
        _ExploreSortMode.name,
      ],
      selectedSortMode: sortMode,
      sortLabelBuilder: _sortModeLabel,
      sortIconBuilder: _sortModeIcon,
      onSortSelected: (value) => setState(() => sortMode = value),
    );
  }

  static IconData _sortModeIcon(_ExploreSortMode mode) {
    switch (mode) {
      case _ExploreSortMode.recommended:
        return Icons.auto_awesome_outlined;
      case _ExploreSortMode.distance:
        return Icons.near_me_outlined;
      case _ExploreSortMode.rating:
        return Icons.star_outline_rounded;
      case _ExploreSortMode.category:
        return Icons.category_outlined;
      case _ExploreSortMode.name:
        return Icons.sort_by_alpha_rounded;
    }
  }

  static String _sortModeLabel(_ExploreSortMode mode) {
    switch (mode) {
      case _ExploreSortMode.recommended:
        return 'Akıllı';
      case _ExploreSortMode.distance:
        return 'Yakınlık';
      case _ExploreSortMode.rating:
        return 'Puan';
      case _ExploreSortMode.category:
        return 'Kategori';
      case _ExploreSortMode.name:
        return 'A-Z';
    }
  }
}
