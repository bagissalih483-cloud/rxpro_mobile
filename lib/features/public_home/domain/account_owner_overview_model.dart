import '../../../core/firestore/firestore_fields.dart';

class AccountOwnerOverviewModel {
  const AccountOwnerOverviewModel({
    required this.profileCompletionPercent,
    required this.statusLabel,
    required this.isActive,
  });

  final int profileCompletionPercent;
  final String statusLabel;
  final bool isActive;

  factory AccountOwnerOverviewModel.fromBusinessData(
    Map<String, dynamic> data,
  ) {
    final score = _profileCompletionPercent(data);
    final active =
        _truthy(data[FirestoreFields.isActive]) ||
        _truthy(data[FirestoreFields.active]) ||
        _text(data[FirestoreFields.status]) == 'active' ||
        _text(data[FirestoreFields.accountStatus]) == 'active' ||
        _text(data[FirestoreFields.businessStatus]) == 'active';

    return AccountOwnerOverviewModel(
      profileCompletionPercent: score,
      isActive: active,
      statusLabel: active ? 'Aktif' : 'Kontrol et',
    );
  }

  static int _profileCompletionPercent(Map<String, dynamic> data) {
    final checks = <bool>[
      _hasAny(data, const [
        FirestoreFields.businessName,
        FirestoreFields.companyName,
        FirestoreFields.name,
      ]),
      _hasAny(data, const [
        FirestoreFields.categoryLabel,
        FirestoreFields.category,
        FirestoreFields.businessCategory,
      ]),
      _hasAny(data, const [
        FirestoreFields.phone,
        FirestoreFields.phoneNumber,
        FirestoreFields.businessEmail,
        FirestoreFields.contactEmail,
      ]),
      _hasAny(data, const [
        FirestoreFields.address,
        FirestoreFields.fullAddress,
        FirestoreFields.city,
        FirestoreFields.district,
      ]),
      _hasAny(data, const [
        FirestoreFields.lat,
        FirestoreFields.lng,
        FirestoreFields.latitude,
        FirestoreFields.longitude,
        FirestoreFields.location,
      ]),
      _hasAny(data, const ['logoUrl', 'photoUrl', 'imageUrl', 'coverUrl']),
      _hasAny(data, const [
        FirestoreFields.openingHour,
        FirestoreFields.closingHour,
      ]),
    ];

    final completed = checks.where((item) => item).length;
    return ((completed / checks.length) * 100).round().clamp(0, 100).toInt();
  }

  static bool _hasAny(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return true;
      if (value is Map && value.isNotEmpty) return true;
      if (value is Iterable && value.isNotEmpty) return true;
      if (value?.toString().trim().isNotEmpty == true) return true;
    }

    return false;
  }

  static bool _truthy(dynamic value) {
    if (value is bool) return value;
    final text = _text(value);
    return text == 'true' || text == '1' || text == 'yes' || text == 'active';
  }

  static String _text(dynamic value) =>
      value?.toString().trim().toLowerCase() ?? '';
}
