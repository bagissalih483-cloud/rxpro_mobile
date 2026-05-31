import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

class BusinessServiceFormPolicy {
  const BusinessServiceFormPolicy._();

  static const single = 'single';
  static const package = 'package';
  static const sessionPackage = 'sessionPackage';

  static String clean(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static String serviceNameOf(Map<String, dynamic> data) {
    final name = clean(
      data[FirestoreFields.serviceName] ?? data[FirestoreFields.name],
    );
    return name.isEmpty ? 'Hizmet' : name;
  }

  static String categoryOf(
    Map<String, dynamic> data, {
    String fallback = 'Genel',
  }) {
    final category = clean(data[FirestoreFields.category]);
    return category.isEmpty ? fallback : category;
  }

  static String normalizedType(Object? value) {
    final type = clean(value);
    if (type == package || type == sessionPackage) return type;
    return single;
  }

  static String typeOf(Map<String, dynamic> data) {
    return normalizedType(data[FirestoreFields.serviceType] ?? data['type']);
  }

  static String typeLabel(String type) {
    switch (normalizedType(type)) {
      case package:
        return 'Paket Hizmet';
      case sessionPackage:
        return 'Seanslı Paket';
      default:
        return 'Tekil Hizmet';
    }
  }

  static String typeLabelOf(Map<String, dynamic> data) {
    final label = clean(data[FirestoreFields.serviceTypeLabel]);
    return label.isEmpty ? typeLabel(typeOf(data)) : label;
  }

  static bool isActive(Map<String, dynamic> data) {
    return data[FirestoreFields.bookingEnabled] != false &&
        data[FirestoreFields.isActive] != false;
  }

  static String sortKey(Map<String, dynamic> data) {
    return serviceNameOf(data).toLowerCase();
  }

  static double parsePrice(String value) {
    final parsed = double.tryParse(clean(value).replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  static int parseDuration(String value) {
    final parsed = int.tryParse(clean(value));
    if (parsed == null) return 45;
    return parsed.clamp(5, 480).toInt();
  }

  static int parseSessionCount(String value) {
    final parsed = int.tryParse(clean(value));
    if (parsed == null) return 1;
    return parsed.clamp(1, 120).toInt();
  }

  static String? validateName(String? value) {
    if (clean(value).isEmpty) return 'Hizmet adı gerekli';
    return null;
  }

  static String? validatePrice(String? value) {
    final text = clean(value);
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return 'Geçerli fiyat girin';
    return null;
  }

  static String? validateDuration(String? value) {
    final text = clean(value);
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 5) return 'Geçerli süre girin';
    return null;
  }

  static String? validateSessionCount(String? value, String type) {
    if (normalizedType(type) != sessionPackage) return null;
    final parsed = int.tryParse(clean(value));
    if (parsed == null || parsed < 1) return 'Geçerli seans sayısı girin';
    return null;
  }

  static Map<String, dynamic> buildPayload({
    required String businessId,
    required String name,
    required String price,
    required String duration,
    required String description,
    required String category,
    required String type,
    required String sessionCount,
    required bool active,
  }) {
    final normalized = normalizedType(type);
    final parsedPrice = parsePrice(price);
    final parsedDuration = parseDuration(duration);
    final parsedSessionCount = parseSessionCount(sessionCount);
    final cleanName = clean(name);
    final cleanCategory = clean(category).isEmpty ? 'Genel' : clean(category);
    final isPackage = normalized == package || normalized == sessionPackage;
    final isSessionPackage = normalized == sessionPackage;

    return <String, dynamic>{
      FirestoreFields.businessId: businessId,
      FirestoreFields.serviceName: cleanName,
      FirestoreFields.name: cleanName,
      FirestoreFields.price: parsedPrice,
      FirestoreFields.servicePrice: parsedPrice,
      FirestoreFields.durationMinutes: parsedDuration,
      FirestoreFields.description: clean(description),
      FirestoreFields.category: cleanCategory,
      'type': normalized,
      FirestoreFields.serviceType: normalized,
      FirestoreFields.serviceTypeLabel: typeLabel(normalized),
      'isPackage': isPackage,
      'isSessionPackage': isSessionPackage,
      FirestoreFields.sessionCount: isSessionPackage
          ? parsedSessionCount
          : null,
      'remainingSessionDefault': isSessionPackage ? parsedSessionCount : null,
      FirestoreFields.bookingEnabled: active,
      FirestoreFields.isActive: active,
    };
  }
}
