import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_fields.dart';
import '../data/business_products_repository.dart';

class BusinessProductsService {
  BusinessProductsService({BusinessProductsRepository? repository})
    : _repository = repository ?? BusinessProductsRepository();

  final BusinessProductsRepository _repository;

  Future<BusinessProductContext> resolveBusinessContext() {
    return _repository.resolveBusinessContext();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProducts(String businessId) {
    return _repository.watchProducts(businessId);
  }

  Future<void> setProductActive({
    required DocumentReference<Map<String, dynamic>> productRef,
    required bool active,
  }) {
    return _repository.setProductActive(productRef: productRef, active: active);
  }

  Future<void> setProductPublic({
    required DocumentReference<Map<String, dynamic>> productRef,
    required bool isPublic,
  }) {
    return _repository.setProductPublic(
      productRef: productRef,
      isPublic: isPublic,
    );
  }

  Future<void> deleteProduct(
    DocumentReference<Map<String, dynamic>> productRef,
  ) {
    return _repository.deleteProduct(productRef);
  }

  Future<void> saveProduct({
    DocumentReference<Map<String, dynamic>>? productRef,
    required BusinessProductSaveInput input,
  }) {
    final name = input.name.trim();
    if (name.isEmpty) {
      throw StateError('Urun adi bos olamaz.');
    }

    final nowIso = DateTime.now().toIso8601String();

    return _repository.upsertProduct(
      productRef: productRef,
      data: <String, dynamic>{
        FirestoreFields.businessId: input.businessId.trim(),
        FirestoreFields.businessName: input.businessName.trim(),
        FirestoreFields.name: name,
        FirestoreFields.productName: name,
        FirestoreFields.category: input.category.trim(),
        FirestoreFields.barcode: input.barcode.trim(),
        FirestoreFields.purchasePrice: input.purchasePrice,
        FirestoreFields.salePrice: input.salePrice,
        FirestoreFields.stockQuantity: input.stockQuantity,
        FirestoreFields.minStockQuantity: input.minStockQuantity,
        FirestoreFields.isPublic: input.isPublic,
        FirestoreFields.isActive: input.isActive,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.updatedAtLocalIso: nowIso,
        FirestoreFields.source: input.source.trim().isEmpty
            ? 'business_products_service'
            : input.source.trim(),
      },
    );
  }
}

class BusinessProductSaveInput {
  const BusinessProductSaveInput({
    required this.businessId,
    required this.businessName,
    required this.name,
    required this.category,
    required this.barcode,
    required this.purchasePrice,
    required this.salePrice,
    required this.stockQuantity,
    required this.minStockQuantity,
    required this.isPublic,
    required this.isActive,
    this.source = 'business_products_service',
  });

  final String businessId;
  final String businessName;
  final String name;
  final String category;
  final String barcode;
  final double purchasePrice;
  final double salePrice;
  final double stockQuantity;
  final double minStockQuantity;
  final bool isPublic;
  final bool isActive;
  final String source;
}
