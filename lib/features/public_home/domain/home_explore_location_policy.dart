import '../../../core/businesses/business_location_data.dart';

class HomeExploreLocationPolicy {
  const HomeExploreLocationPolicy._();

  static const double liveQueryRadiusKm = 50;
  static const double minimumLocationQueryDeltaKm = 1;

  static bool shouldRunLocationQuery({
    required double latitude,
    required double longitude,
    double? previousLatitude,
    double? previousLongitude,
  }) {
    if (previousLatitude == null || previousLongitude == null) return true;

    final distance = BusinessLocationParser.distanceKm(
      fromLat: previousLatitude,
      fromLng: previousLongitude,
      toLat: latitude,
      toLng: longitude,
    );

    return distance >= minimumLocationQueryDeltaKm;
  }
}
