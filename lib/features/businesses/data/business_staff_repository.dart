import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

class BusinessStaffRepository {
  BusinessStaffRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> businessStaffCollection() {
    return _firestore.collection('businessStaff');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchBusinessStaff(
    String businessId,
  ) {
    return businessStaffCollection()
        .where('businessId', isEqualTo: businessId)
        .snapshots();
  }

  Future<String> ensureBusinessAccessCode({
    required String businessId,
    Map<String, dynamic> businessData = const <String, dynamic>{},
  }) async {
    final ref = _firestore.collection('businesses').doc(businessId);

    try {
      final doc = await ref.get();
      final data = doc.exists ? (doc.data() ?? businessData) : businessData;

      final existing =
          (data['businessAccessCode'] ??
                  data['accessCode'] ??
                  data['staffAccessCode'] ??
                  '')
              .toString()
              .trim();

      if (existing.isNotEmpty) {
        return existing;
      }

      final name = (data['businessName'] ?? data['name'] ?? 'ISLETME')
          .toString();
      final clean = name
          .toUpperCase()
          .replaceAll('İ', 'I')
          .replaceAll('Ğ', 'G')
          .replaceAll('Ü', 'U')
          .replaceAll('Ş', 'S')
          .replaceAll('Ö', 'O')
          .replaceAll('Ç', 'C')
          .replaceAll(RegExp(r'[^A-Z0-9]'), '');

      final prefix = clean.padRight(4, 'X').substring(0, 4);
      final digits = (businessId.hashCode.abs() % 9000) + 1000;
      final code = '$prefix-$digits';

      await ref.set(<String, dynamic>{
        'businessId': businessId,
        'businessAccessCode': code,
        'accessCode': code,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return code;
    } catch (_) {
      final digits = (businessId.hashCode.abs() % 9000) + 1000;
      return 'ISLT-$digits';
    }
  }

  Future<DocumentReference<Map<String, dynamic>>> upsertBusinessStaff({
    required String businessId,
    String? staffId,
    required Map<String, dynamic> payload,
    bool addCreatedAt = true,
  }) async {
    final normalizedPayload = Map<String, dynamic>.from(payload);
    normalizedPayload['businessId'] = businessId;
    normalizedPayload['updatedAt'] = FieldValue.serverTimestamp();
    if (normalizedPayload.containsKey('serviceMatchMode') ||
        normalizedPayload.containsKey('serviceMatchWarning')) {
      normalizedPayload['serviceMatchUpdatedAt'] = FieldValue.serverTimestamp();
    }

    if (staffId == null || staffId.trim().isEmpty) {
      if (addCreatedAt) {
        normalizedPayload['createdAt'] = FieldValue.serverTimestamp();
      }
      return businessStaffCollection().add(normalizedPayload);
    }

    final ref = businessStaffCollection().doc(staffId);
    await ref.set(normalizedPayload, SetOptions(merge: true));
    return ref;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchBusinessActivityLogs({
    required String businessId,
    int limit = 50,
  }) {
    return _firestore
        .collection('businessActivityLogs')
        .where('businessId', isEqualTo: businessId)
        .limit(limit)
        .snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> addBusinessStaffActivityLog({
    required String businessId,
    required String type,
    required String title,
    String? staffName,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final payload = <String, dynamic>{
      ...extra,
      'businessId': businessId,
      'type': type,
      'title': title,
      if (staffName != null && staffName.trim().isNotEmpty)
        'staffName': staffName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    return _firestore.collection('businessActivityLogs').add(payload);
  }

  Future<void> deleteStaff(String staffId) async {
    if (staffId.trim().isEmpty) {
      return;
    }
    await businessStaffCollection().doc(staffId).delete();
  }

  Future<void> deleteStaffDocument(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    await reference.delete();
  }

  Future<void> setStaffActive({
    required String staffId,
    required bool isActive,
  }) async {
    if (staffId.trim().isEmpty) return;

    await businessStaffCollection().doc(staffId).set({
      FirestoreFields.isActive: isActive,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<BusinessStaffServiceOption>> fetchActiveServiceOptions({
    required String businessId,
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.businessServices)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .get();

    final list =
        snapshot.docs
            .where((doc) {
              final data = doc.data();
              return data[FirestoreFields.bookingEnabled] != false &&
                  data[FirestoreFields.isActive] != false;
            })
            .map((doc) {
              final data = doc.data();
              return BusinessStaffServiceOption(
                id: doc.id,
                name:
                    (data[FirestoreFields.serviceName] ??
                            data[FirestoreFields.name] ??
                            'Hizmet')
                        .toString(),
                duration:
                    (data[FirestoreFields.durationMinutes] ??
                            data[FirestoreFields.duration] ??
                            '')
                        .toString(),
                price:
                    (data[FirestoreFields.price] ??
                            data[FirestoreFields.servicePrice] ??
                            '')
                        .toString(),
              );
            })
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return list;
  }
}

class BusinessStaffServiceOption {
  const BusinessStaffServiceOption({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
  });

  final String id;
  final String name;
  final String duration;
  final String price;
}
