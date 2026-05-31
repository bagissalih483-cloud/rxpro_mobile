part of 'home_explore_page.dart';

extension _HomeExploreLogic on _HomeExplorePageState {
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
    final targetPosition = position ?? _exploreController.currentPosition;
    return _exploreController.reloadBusinesses(
      position: targetPosition,
      radiusKm: _exploreController.radiusKm,
      categoryLabel: _exploreController.selectedCategory,
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
      if (!_exploreController.shouldRunLocationQuery(position) &&
          _exploreController.businesses.isNotEmpty) {
        _exploreController.setCurrentPosition(position);
        _snack(
          'Konumun 1 km içinde değişmedi. Mevcut yakın işletme listesi gösteriliyor.',
        );
        _scrollExploreToTop();
        return;
      }

      _exploreController.setCurrentPosition(position, notify: false);
      await _reloadExploreBusinesses(
        position: position,
        forceRefresh: true,
        replaceWithEmpty: false,
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
    if (_exploreController.currentPosition != null) {
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
      origin: _exploreController.currentPosition,
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
}
