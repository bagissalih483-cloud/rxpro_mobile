import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';

class BusinessAnalysisRepository {
  BusinessAnalysisRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int _analysisLegacyWindow = 365;

  final FirebaseFirestore _firestore;

  Future<BusinessAnalysisSnapshot> fetchBusinessAnalysisSnapshot({
    required String businessId,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final appointments = await fetchAppointmentDocuments(
      businessId: businessId,
      startAt: startAt,
      endAt: endAt,
    );

    final productSales = await fetchProductSaleDocuments(
      businessId: businessId,
      startAt: startAt,
      endAt: endAt,
    );

    final productPurchases = await fetchProductPurchaseDocuments(
      businessId: businessId,
      startAt: startAt,
      endAt: endAt,
    );

    return BusinessAnalysisSnapshot(
      businessId: businessId,
      appointments: appointments,
      productSales: productSales,
      productPurchases: productPurchases,
      generatedAt: DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> fetchAppointmentDocuments({
    required String businessId,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.appointments)
        .where(FirestoreFields.businessId, isEqualTo: businessId);

    query = _applyDateRange(query, startAt: startAt, endAt: endAt);

    final snapshot = await query.get();
    return _withDocumentIds(snapshot);
  }

  Future<List<Map<String, dynamic>>> fetchProductSaleDocuments({
    required String businessId,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.businessProductSales)
        .where(FirestoreFields.businessId, isEqualTo: businessId);

    query = _applyDateRange(query, startAt: startAt, endAt: endAt);

    final snapshot = await query.get();
    return _withDocumentIds(snapshot);
  }

  Future<List<Map<String, dynamic>>> fetchProductPurchaseDocuments({
    required String businessId,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.businessProductPurchases)
        .where(FirestoreFields.businessId, isEqualTo: businessId);

    query = _applyDateRange(query, startAt: startAt, endAt: endAt);

    final snapshot = await query.get();
    return _withDocumentIds(snapshot);
  }

  Future<List<Map<String, dynamic>>> fetchAppointmentDocumentsForAnalysis({
    required String businessId,
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.appointments)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .limit(_analysisLegacyWindow)
        .get();

    return _withDocumentIds(snapshot);
  }

  Future<List<Map<String, dynamic>>> safeFetchProductSaleDocumentsForAnalysis({
    required String businessId,
  }) async {
    return _safeFetchDocumentsByBusinessId(
      collectionPath: FirestoreCollections.businessProductSales,
      businessId: businessId,
    );
  }

  Future<List<Map<String, dynamic>>>
  safeFetchProductPurchaseDocumentsForAnalysis({
    required String businessId,
  }) async {
    return _safeFetchDocumentsByBusinessId(
      collectionPath: FirestoreCollections.businessProductPurchases,
      businessId: businessId,
    );
  }

  Future<List<Map<String, dynamic>>> _safeFetchDocumentsByBusinessId({
    required String collectionPath,
    required String businessId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(collectionPath)
          .where(FirestoreFields.businessId, isEqualTo: businessId)
          .limit(_analysisLegacyWindow)
          .get();

      return _withDocumentIds(snapshot);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Query<Map<String, dynamic>> _applyDateRange(
    Query<Map<String, dynamic>> query, {
    DateTime? startAt,
    DateTime? endAt,
  }) {
    if (startAt != null) {
      query = query.where(
        FirestoreFields.createdAt,
        isGreaterThanOrEqualTo: Timestamp.fromDate(startAt),
      );
    }

    if (endAt != null) {
      query = query.where(
        FirestoreFields.createdAt,
        isLessThanOrEqualTo: Timestamp.fromDate(endAt),
      );
    }

    return query;
  }

  List<Map<String, dynamic>> _withDocumentIds(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) {
          return <String, dynamic>{FirestoreFields.id: doc.id, ...doc.data()};
        })
        .toList(growable: false);
  }
}

class BusinessAnalysisSnapshot {
  const BusinessAnalysisSnapshot({
    required this.businessId,
    required this.appointments,
    required this.productSales,
    required this.productPurchases,
    required this.generatedAt,
  });

  final String businessId;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> productSales;
  final List<Map<String, dynamic>> productPurchases;
  final DateTime generatedAt;

  int get appointmentCount => appointments.length;
  int get productSaleCount => productSales.length;
  int get productPurchaseCount => productPurchases.length;

  double get productSalesTotal => _sumAmount(productSales);
  double get productPurchasesTotal => _sumAmount(productPurchases);

  double get productNetTotal => productSalesTotal - productPurchasesTotal;

  static double _sumAmount(List<Map<String, dynamic>> rows) {
    var total = 0.0;

    for (final row in rows) {
      final value =
          row[FirestoreFields.totalAmount] ??
          row[FirestoreFields.amount] ??
          row[FirestoreFields.price] ??
          row['total'] ??
          row['value'];

      if (value is num) {
        total += value.toDouble();
      } else if (value is String) {
        total += double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
      }
    }

    return total;
  }
}
