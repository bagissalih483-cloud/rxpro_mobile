import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';
import '../business_product_movement_models.dart';

class BusinessProductMovementRepository {
  BusinessProductMovementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createMovement(BusinessProductMovementCreateInput input) async {
    await _firestore.collection(_collectionFor(input.type)).add({
      FirestoreFields.businessId: input.businessId,
      FirestoreFields.businessName: input.businessName,
      FirestoreFields.productName: input.productName,
      FirestoreFields.quantity: input.quantity,
      FirestoreFields.amount: input.amount,
      FirestoreFields.totalAmount: input.amount,
      FirestoreFields.note: input.note,
      'movementType': input.type.firestoreValue,
      FirestoreFields.source: 'business_product_movement_service_64C',
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      if (input.type == BusinessProductMovementType.sale)
        FirestoreFields.saleDate: FieldValue.serverTimestamp(),
      if (input.type == BusinessProductMovementType.purchase)
        'purchaseDate': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<BusinessProductMovementRecord>> watchRecentMovements({
    required String businessId,
    required BusinessProductMovementType type,
    int limit = 30,
  }) {
    return _firestore
        .collection(_collectionFor(type))
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BusinessProductMovementRecord.fromMap(
                  id: doc.id,
                  data: doc.data(),
                ),
              )
              .toList(growable: false),
        );
  }

  String _collectionFor(BusinessProductMovementType type) {
    return switch (type) {
      BusinessProductMovementType.sale =>
        FirestoreCollections.businessProductSales,
      BusinessProductMovementType.purchase =>
        FirestoreCollections.businessProductPurchases,
    };
  }
}
