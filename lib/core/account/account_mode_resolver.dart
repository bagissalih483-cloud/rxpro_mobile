import 'package:rxpro_mobile/core/account/account_mode.dart';
import 'package:rxpro_mobile/core/session/app_role.dart';
import 'package:rxpro_mobile/core/session/app_session.dart';
import 'package:rxpro_mobile/core/session/session_role_policy.dart';

class AccountModeResolver {
  const AccountModeResolver._();

  static AccountMode fromSession(AppSession session) {
    if (!session.isAuthenticated || session.isGuest) {
      return AccountMode.guest;
    }

    if (session.isCorporateStaff) {
      return AccountMode.linkedStaff;
    }

    if (session.isCorporateOwner || session.hasOwnerAuthority) {
      return AccountMode.corporateOwner;
    }

    return AccountMode.individual;
  }

  static AccountMode fromUserData(Map<String, dynamic> data) {
    if (data.isEmpty) return AccountMode.individual;

    final role = SessionRolePolicy.resolveCanonicalRole(data);

    switch (role) {
      case AppRole.guest:
        return AccountMode.guest;
      case AppRole.individual:
        return AccountMode.individual;
      case AppRole.corporateOwner:
      case AppRole.admin:
        return AccountMode.corporateOwner;
      case AppRole.corporateStaff:
        return AccountMode.linkedStaff;
      case AppRole.invalid:
        return AccountMode.individual;
    }
  }
}
