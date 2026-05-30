import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';

import '../domain/home_explore_category_counts.dart';
import '../domain/home_explore_filter_policy.dart';
import '../domain/home_explore_location_policy.dart';

abstract class HomeExploreDataSource {
  Future<List<BusinessDirectoryItem>> loadBusinesses({
    required Position? position,
    required double radiusKm,
    required String categoryLabel,
    required bool forceRefresh,
  });
}

class HomeExploreController extends ChangeNotifier {
  HomeExploreController({HomeExploreDataSource? dataSource})
    : _dataSource = dataSource ?? _BusinessDirectoryHomeExploreDataSource();

  final HomeExploreDataSource _dataSource;

  List<BusinessDirectoryItem> _businesses = <BusinessDirectoryItem>[];
  Object? _businessLoadError;
  Position? _lastLocationQueryPosition;
  String _detectedCity = '';
  String _detectedDistrict = '';
  bool _loadingBusinesses = false;
  bool _loadingLocation = false;
  bool _hasCompletedInitialBusinessLoad = false;
  int _businessLoadTicket = 0;

  List<BusinessDirectoryItem> get businesses => _businesses;
  Object? get businessLoadError => _businessLoadError;
  String get detectedCity => _detectedCity;
  String get detectedDistrict => _detectedDistrict;
  bool get loadingBusinesses => _loadingBusinesses;
  bool get loadingLocation => _loadingLocation;
  bool get hasCompletedInitialBusinessLoad => _hasCompletedInitialBusinessLoad;

  bool get waitingForManualLoad {
    return !_hasCompletedInitialBusinessLoad &&
        !_loadingBusinesses &&
        _businesses.isEmpty;
  }

  void resetLocationContext() {
    _lastLocationQueryPosition = null;
    _detectedCity = '';
    _detectedDistrict = '';
    if (_loadingLocation) {
      _loadingLocation = false;
    }
    notifyListeners();
  }

  void setLocationLoading(bool value) {
    if (_loadingLocation == value) return;
    _loadingLocation = value;
    notifyListeners();
  }

  bool shouldRunLocationQuery(Position position) {
    return HomeExploreLocationPolicy.shouldRunLocationQuery(
      latitude: position.latitude,
      longitude: position.longitude,
      previousLatitude: _lastLocationQueryPosition?.latitude,
      previousLongitude: _lastLocationQueryPosition?.longitude,
    );
  }

  void markLocationQueryApplied(Position position) {
    _lastLocationQueryPosition = position;
    notifyListeners();
  }

  Future<bool> reloadBusinesses({
    required Position? position,
    required double radiusKm,
    required String categoryLabel,
    bool forceRefresh = false,
    bool replaceWithEmpty = false,
  }) async {
    final ticket = ++_businessLoadTicket;
    final stopwatch = Stopwatch()..start();

    _loadingBusinesses = true;
    _businessLoadError = null;
    notifyListeners();

    debugPrint(
      'FIX_EXPLORE_LOAD_START ticket=$ticket '
      'category="$categoryLabel" radiusKm=${radiusKm.round()} '
      'hasPosition=${position != null} force=$forceRefresh',
    );

    try {
      final items = await _dataSource
          .loadBusinesses(
            position: position,
            radiusKm: radiusKm,
            categoryLabel: categoryLabel,
            forceRefresh: forceRefresh,
          )
          .timeout(const Duration(seconds: 12));

      if (ticket != _businessLoadTicket) return false;

      final area = HomeExploreFilterPolicy.detectNearestArea(
        items: items,
        position: position,
      );

      if (replaceWithEmpty || items.isNotEmpty || _businesses.isEmpty) {
        _businesses = items;
      }

      if (area != null) {
        _detectedCity = area.city;
        _detectedDistrict = area.district;
      } else if (position == null) {
        _detectedCity = '';
        _detectedDistrict = '';
      }

      _hasCompletedInitialBusinessLoad = true;

      debugPrint(
        'FIX_EXPLORE_LOAD_DONE ticket=$ticket count=${items.length} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint(
        'FIX_EXPLORE_LOAD_FAILED ticket=$ticket '
        'elapsedMs=${stopwatch.elapsedMilliseconds} error=$error',
      );

      if (ticket != _businessLoadTicket) return false;

      _businessLoadError = error;
      _hasCompletedInitialBusinessLoad = true;
      notifyListeners();
      return true;
    } finally {
      if (ticket == _businessLoadTicket) {
        _loadingBusinesses = false;
        notifyListeners();
      }
    }
  }

  List<BusinessDirectoryItem> filteredBusinesses({
    required String queryText,
    required String selectedCategory,
    required Position? currentPosition,
    required double radiusKm,
    required HomeExploreSortMode sortMode,
  }) {
    return HomeExploreFilterPolicy.filterAndSort(
      items: _businesses,
      queryText: queryText,
      selectedCategory: selectedCategory,
      currentPosition: currentPosition,
      radiusKm: radiusKm,
      sortMode: sortMode,
    );
  }

  Map<String, int> categoryCounts({
    required List<String> categories,
    required String queryText,
    required Position? currentPosition,
    required double radiusKm,
  }) {
    return HomeExploreCategoryCounts.build(
      items: _businesses,
      categories: categories,
      queryText: queryText,
      currentPosition: currentPosition,
      radiusKm: radiusKm,
    );
  }
}

class _BusinessDirectoryHomeExploreDataSource implements HomeExploreDataSource {
  @override
  Future<List<BusinessDirectoryItem>> loadBusinesses({
    required Position? position,
    required double radiusKm,
    required String categoryLabel,
    required bool forceRefresh,
  }) {
    return BusinessDirectoryCacheService.instance.getBusinessesForExplore(
      position: position,
      radiusKm: radiusKm,
      categoryLabel: categoryLabel,
      forceRefresh: forceRefresh,
    );
  }
}
