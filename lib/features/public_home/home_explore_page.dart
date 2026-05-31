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

part 'home_explore_logic_part.dart';
part 'home_explore_badges_part.dart';
part 'home_explore_filter_data_part.dart';
part 'home_explore_header_filter_part.dart';
part 'home_explore_scope_part.dart';

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
  String? _unreadMessagesStreamKey;
  Stream<int>? _unreadMessagesStream;
  String? _unreadNotificationsStreamKey;
  Stream<int>? _unreadNotificationsStream;

  @override
  void initState() {
    super.initState();

    _exploreController = HomeExploreController();

    _lastUid = _sessionRepository.currentUid();
    _authSub = _sessionRepository.watchUid().listen((nextUid) {
      if (nextUid == _lastUid) return;
      _lastUid = nextUid;

      if (!mounted) return;

      searchController.clear();
      _clearBadgeStreams();
      _exploreController.resetSessionState();

      _startInitialExploreLoadIfEnabled(reason: 'auth_change');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialExploreLoadIfEnabled(reason: 'post_frame');
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _clearBadgeStreams();
    _exploreController.dispose();
    _exploreScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exploreController,
      builder: (context, _) {
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
                        queryText: _exploreController.queryText,
                        currentPosition: _exploreController.currentPosition,
                        radiusKm: _exploreController.radiusKm,
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
                        selectedCategory: _exploreController.selectedCategory,
                        currentPosition: _exploreController.currentPosition,
                        radiusKm: _exploreController.radiusKm,
                        filterPanel: _buildFilterPanel(),
                        scrollController: _exploreScrollController,
                        onRefresh: _refreshBusinesses,
                        onSearchChanged: () => _exploreController.setQueryText(
                          searchController.text,
                        ),
                        onSearchCleared: () {
                          searchController.clear();
                          _exploreController.clearQueryText();
                        },
                        onCategorySelected: (category) {
                          _exploreController.setSelectedCategory(category);
                          unawaited(
                            _reloadExploreBusinesses(
                              position: _exploreController.currentPosition,
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
                          searchController.clear();
                          _exploreController.resetFilters();
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
      },
    );
  }
}
