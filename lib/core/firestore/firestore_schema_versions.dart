/// 50B Firestore Schema Versions Foundation.
///
/// Yeni yazımlarda kullanılacak şema sürümleri için merkezi referans.
/// İlk aşamada davranış değiştirmez.
abstract final class FirestoreSchemaVersions {
  FirestoreSchemaVersions._();

  static const role49dC = '49D-C';
  static const serviceStaffRelation49bC = '49B-C';

  static const dataDictionaryV1 = '50A-V1';
  static const firestoreConstants50b = '50B';

  // Gelecek standart alanlar için önerilen değerler.
  static const appointmentV1 = 'appointment-v1';
  static const notificationV1 = 'notification-v1';
  static const businessStaffV1 = 'business-staff-v1';
  static const walletV1 = 'wallet-v1';

  // Messaging / chat schema versions.
  // 51C-C foundation only; no production data migration is performed here.
  static const messagingV1 = 'messaging-v1';
  static const messageThreadV1 = 'message-thread-v1';
  static const messagePayloadV1 = 'message-payload-v1';
  static const messagingConstants51cC = '51C-C';
  static const roleStandardization50c = '50C';
}
