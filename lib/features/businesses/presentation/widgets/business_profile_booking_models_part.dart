part of '../../business_profile_page.dart';

class _InlineService {
  final String id;
  final String name;
  final String price;
  final String duration;

  const _InlineService({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
  });

  int get durationMinutes =>
      BusinessProfileBookingPolicy.durationMinutes(duration);
}

class _InlineStaff {
  final String id;
  final String name;
  final String uid;
  final String email;
  final List<String> serviceIds;

  const _InlineStaff({
    required this.id,
    required this.name,
    this.uid = '',
    this.email = '',
    this.serviceIds = const <String>[],
  });

  bool canProvideService(String serviceId) {
    return BusinessProfileBookingPolicy.staffCanProvideService(
      serviceId: serviceId,
      staffServiceIds: serviceIds,
    );
  }
}
