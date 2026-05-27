import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class BusinessServicesRepository {
  const BusinessServicesRepository();

  CollectionReference<Map<String, dynamic>> get _services => FirebaseFirestore
      .instance
      .collection(FirestoreCollections.businessServices);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchBusinessServices(
    String businessId,
  ) {
    final cleanBusinessId = businessId.trim();

    if (cleanBusinessId.isEmpty) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _services
        .where(FirestoreFields.businessId, isEqualTo: cleanBusinessId)
        .snapshots();
  }

  Future<void> setServiceBookingEnabled({
    required String serviceId,
    required bool enabled,
  }) async {
    final cleanServiceId = serviceId.trim();

    if (cleanServiceId.isEmpty) {
      throw ArgumentError.value(serviceId, 'serviceId', 'must not be empty');
    }

    await _services.doc(cleanServiceId).set(<String, dynamic>{
      FirestoreFields.bookingEnabled: enabled,
      FirestoreFields.isActive: enabled,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteBusinessService(String serviceId) async {
    final cleanServiceId = serviceId.trim();

    if (cleanServiceId.isEmpty) {
      throw ArgumentError.value(serviceId, 'serviceId', 'must not be empty');
    }

    await _services.doc(cleanServiceId).delete();
  }

  Future<void> saveBusinessService({
    String? serviceId,
    required Map<String, dynamic> payload,
  }) async {
    final cleanServiceId = serviceId?.trim();

    final data = <String, dynamic>{
      ...payload,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };

    if (cleanServiceId == null || cleanServiceId.isEmpty) {
      await _services.add(<String, dynamic>{
        ...data,
        FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    await _services.doc(cleanServiceId).set(data, SetOptions(merge: true));
  }
}
