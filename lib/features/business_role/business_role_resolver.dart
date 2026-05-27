import 'data/business_role_repository.dart';
import 'business_role_result.dart';

export 'business_role_result.dart';

/// Legacy entry pages still consume BusinessRoleResolver.
/// Role decision and business document lookups are handled by the repository.
class BusinessRoleResolver {
  const BusinessRoleResolver._();

  static final BusinessRoleRepository _repository = BusinessRoleRepository();

  static Future<BusinessRoleResult> resolveCurrentUser() {
    return _repository.resolveCurrentUser();
  }

  static Future<BusinessRoleResult> resolveByUid(String uid) {
    return _repository.resolveByUid(uid);
  }
}
