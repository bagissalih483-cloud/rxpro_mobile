import '../business_product_movement_models.dart';
import '../data/business_product_movement_repository.dart';

class BusinessProductMovementService {
  BusinessProductMovementService({
    BusinessProductMovementRepository? repository,
  }) : _repository = repository ?? BusinessProductMovementRepository();

  final BusinessProductMovementRepository _repository;

  Future<void> createMovement(BusinessProductMovementCreateInput input) {
    final productName = input.productName.trim();
    if (productName.isEmpty) {
      throw ArgumentError.value(input.productName, 'productName');
    }

    return _repository.createMovement(
      BusinessProductMovementCreateInput(
        businessId: input.businessId.trim(),
        businessName: input.businessName.trim(),
        productName: productName,
        quantity: input.quantity <= 0 ? 1 : input.quantity,
        amount: input.amount < 0 ? 0 : input.amount,
        note: input.note.trim(),
        type: input.type,
      ),
    );
  }

  Stream<List<BusinessProductMovementRecord>> watchRecentMovements({
    required String businessId,
    required BusinessProductMovementType type,
  }) {
    return _repository.watchRecentMovements(
      businessId: businessId.trim(),
      type: type,
    );
  }
}
