import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'business_directory_cache_service.dart';

class BusinessDirectionsService {
  const BusinessDirectionsService();

  Future<bool> openDirections({
    required BusinessDirectoryItem business,
    Position? origin,
  }) async {
    final destination = business.mapsDestination.trim();
    if (destination.isEmpty) return false;

    final query = <String, String>{
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
      if (origin != null)
        'origin':
            '${origin.latitude.toStringAsFixed(7)},${origin.longitude.toStringAsFixed(7)}',
    };

    final uri = Uri.https('www.google.com', '/maps/dir/', query);

    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    return launchUrl(uri);
  }

  Future<bool> openNearbySearch({
    required Position origin,
    String categoryLabel = '',
    String district = '',
  }) async {
    final cleanCategory = categoryLabel.trim();
    final cleanDistrict = district.trim();
    final queryText = [
      if (cleanCategory.isNotEmpty) cleanCategory,
      if (cleanDistrict.isNotEmpty) cleanDistrict,
      'isletme',
    ].join(' ');

    final uri = Uri.https('www.google.com', '/maps/search/', <String, String>{
      'api': '1',
      'query': queryText,
      'center':
          '${origin.latitude.toStringAsFixed(7)},${origin.longitude.toStringAsFixed(7)}',
    });

    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    return launchUrl(uri);
  }
}
