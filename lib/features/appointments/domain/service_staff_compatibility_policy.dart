import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

class ServiceStaffCompatibilityResult {
  const ServiceStaffCompatibilityResult({
    required this.valid,
    required this.message,
    this.staffServiceIds = const <String>[],
  });

  final bool valid;
  final String message;
  final List<String> staffServiceIds;

  const ServiceStaffCompatibilityResult.ok({
    this.staffServiceIds = const <String>[],
  }) : valid = true,
       message = '';

  const ServiceStaffCompatibilityResult.failure(
    this.message, {
    this.staffServiceIds = const <String>[],
  }) : valid = false;
}

/// 49B-C:
/// Personel-hizmet uyumluluk kuralı UI veya AppointmentBookingService içinde
/// dağınık kalmasın diye tek policy sınıfında toplandı.
///
/// Standart:
/// - businessStaffId = businessStaff doküman ID'si.
/// - serviceIds boşsa eski kayıt uyumluluğu için geçici olarak izin verilir.
/// - serviceIds doluysa seçili serviceId kesinlikle listede olmalıdır.
/// 50C-F1: Service/staff compatibility field literals now use
/// FirestoreFields constants. Compatibility behavior is unchanged.
class ServiceStaffCompatibilityPolicy {
  const ServiceStaffCompatibilityPolicy();

  ServiceStaffCompatibilityResult validate({
    required Map<String, dynamic>? staffData,
    required String expectedBusinessId,
    required String selectedServiceId,
  }) {
    if (staffData == null) {
      return const ServiceStaffCompatibilityResult.failure(
        'Seçilen personel bulunamadı.',
      );
    }

    final staffBusinessId = (staffData['businessId'] ?? '').toString();
    if (staffBusinessId != expectedBusinessId) {
      return const ServiceStaffCompatibilityResult.failure(
        'Seçilen personel bu kurumsal kullanıcıya ait değil.',
      );
    }

    if (staffData['isActive'] == false) {
      return const ServiceStaffCompatibilityResult.failure(
        'Seçilen personel aktif değil.',
      );
    }

    final serviceIds = stringList(
      staffData[FirestoreFields.serviceIds] ??
          staffData[FirestoreFields.staffServiceIds] ??
          staffData[FirestoreFields.allowedServiceIds],
    );

    if (serviceIds.isNotEmpty && !serviceIds.contains(selectedServiceId)) {
      return ServiceStaffCompatibilityResult.failure(
        'Seçilen personel bu hizmeti veremiyor.',
        staffServiceIds: serviceIds,
      );
    }

    return ServiceStaffCompatibilityResult.ok(staffServiceIds: serviceIds);
  }

  static List<String> stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }
}
