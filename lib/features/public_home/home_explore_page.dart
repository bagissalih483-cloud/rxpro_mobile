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
import 'domain/home_explore_filter_policy.dart';
import 'presentation/widgets/home_explore_content_list.dart';
import 'presentation/widgets/home_explore_filter_widgets.dart';
import 'presentation/widgets/home_explore_shell_widgets.dart';
import 'presentation/home_explore_controller.dart';
import 'data/home_explore_badge_repository.dart';
import 'data/home_explore_claim_repository.dart';
import 'data/home_explore_session_repository.dart';

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
  late final HomeExploreController _exploreController;
  final ScrollController _exploreScrollController = ScrollController(
    keepScrollOffset: false,
  );

  StreamSubscription<String?>? _authSub;
  String? _lastUid;

  Position? currentPosition;

  String selectedCategory = BusinessCategories.allLabel;
  double radiusKm = 10;
  HomeExploreSortMode sortMode = HomeExploreSortMode.recommended;

  @override
  void initState() {
    super.initState();

    _exploreController = HomeExploreController()
      ..addListener(_handleExploreControllerChanged);

    _lastUid = _sessionRepository.currentUid();
    _authSub = _sessionRepository.watchUid().listen((nextUid) {
      if (nextUid == _lastUid) return;
      _lastUid = nextUid;

      if (!mounted) return;

      setState(() {
        searchController.clear();
        selectedCategory = BusinessCategories.allLabel;
        radiusKm = 10;
        sortMode = HomeExploreSortMode.recommended;
        currentPosition = null;
      });
      _exploreController.resetLocationContext();

      _startInitialExploreLoadIfEnabled(reason: 'auth_change');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialExploreLoadIfEnabled(reason: 'post_frame');
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _exploreController.removeListener(_handleExploreControllerChanged);
    _exploreController.dispose();
    _exploreScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _handleExploreControllerChanged() {
    if (mounted) {
      setState(() {});
    }
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
    final targetPosition = position ?? currentPosition;
    return _exploreController.reloadBusinesses(
      position: targetPosition,
      radiusKm: radiusKm,
      categoryLabel: selectedCategory,
      forceRefresh: forceRefresh,
      replaceWithEmpty: replaceWithEmpty,
    );
  }

  Future<void> _requestLocation() async {
    if (_exploreController.loadingLocation) return;

    _exploreController.setLocationLoading(true);

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
        if (sortMode == HomeExploreSortMode.distance) {
          sortMode = HomeExploreSortMode.recommended;
        }
      });
      if (!_exploreController.shouldRunLocationQuery(position) &&
          _exploreController.businesses.isNotEmpty) {
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
          _exploreController.markLocationQueryApplied(position);
          _scrollExploreToTop();
        }
      });

      if (!mounted) return;
      final count = _filteredBusinesses().length;
      _snack(
        count == 0
            ? 'Bu kilometre aralığında işletme bulunamadı. Mesafeyi artırmayı deneyin.'
            : '$count yakın işletme listelendi.',
      );
    } catch (e) {
      _snack('Konum alınamadı: $e');
    } finally {
      if (mounted) {
        _exploreController.setLocationLoading(false);
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

  List<BusinessDirectoryItem> _filteredBusinesses() {
    return _exploreController.filteredBusinesses(
      queryText: searchController.text,
      selectedCategory: selectedCategory,
      currentPosition: currentPosition,
      radiusKm: radiusKm,
      sortMode: sortMode,
    );
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
                  final allItems = _exploreController.businesses;
                  final filtered = _filteredBusinesses();
                  final categories = _categories();
                  final categoryCounts = _exploreController.categoryCounts(
                    categories: categories,
                    queryText: searchController.text,
                    currentPosition: currentPosition,
                    radiusKm: radiusKm,
                  );
                  final waitingForManualLoad =
                      RxRuntimeDiagnostics.disableExploreAutoLoad &&
                      _exploreController.waitingForManualLoad;
                  if (RxRuntimeDiagnostics.verboseExploreRender) {
                    debugPrint(
                      'FIX_EXPLORE_RENDER all=${allItems.length} '
                      'filtered=${filtered.length} '
                      'loading=${_exploreController.loadingBusinesses} '
                      'done=${_exploreController.hasCompletedInitialBusinessLoad} '
                      'manualWait=$waitingForManualLoad '
                      'detectedCity=${_exploreController.detectedCity} '
                      'detectedDistrict=${_exploreController.detectedDistrict} '
                      'error=${_exploreController.businessLoadError != null} '
                      'screen=${MediaQuery.sizeOf(context)}',
                    );
                  }

                  return HomeExploreContentList(
                    loadingBusinesses: _exploreController.loadingBusinesses,
                    hasCompletedInitialBusinessLoad:
                        _exploreController.hasCompletedInitialBusinessLoad,
                    businessLoadError: _exploreController.businessLoadError,
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
    return HomeExploreControlPanel<HomeExploreSortMode>(
      hasPosition: currentPosition != null,
      loadingLocation: _exploreController.loadingLocation,
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
              final position = currentPosition;
              if (applied && position != null) {
                _exploreController.markLocationQueryApplied(position);
              }
            }),
          );
          return;
        }

        unawaited(
          _reloadExploreBusinesses(forceRefresh: true, replaceWithEmpty: true),
        );
      },
      sortModes: const [
        HomeExploreSortMode.recommended,
        HomeExploreSortMode.rating,
        HomeExploreSortMode.category,
        HomeExploreSortMode.name,
      ],
      selectedSortMode: sortMode,
      sortLabelBuilder: _sortModeLabel,
      sortIconBuilder: _sortModeIcon,
      onSortSelected: (value) => setState(() => sortMode = value),
    );
  }

  static IconData _sortModeIcon(HomeExploreSortMode mode) {
    switch (mode) {
      case HomeExploreSortMode.recommended:
        return Icons.auto_awesome_outlined;
      case HomeExploreSortMode.distance:
        return Icons.near_me_outlined;
      case HomeExploreSortMode.rating:
        return Icons.star_outline_rounded;
      case HomeExploreSortMode.category:
        return Icons.category_outlined;
      case HomeExploreSortMode.name:
        return Icons.sort_by_alpha_rounded;
    }
  }

  static String _sortModeLabel(HomeExploreSortMode mode) {
    switch (mode) {
      case HomeExploreSortMode.recommended:
        return 'Akıllı';
      case HomeExploreSortMode.distance:
        return 'Yakınlık';
      case HomeExploreSortMode.rating:
        return 'Puan';
      case HomeExploreSortMode.category:
        return 'Kategori';
      case HomeExploreSortMode.name:
        return 'A-Z';
    }
  }
}
