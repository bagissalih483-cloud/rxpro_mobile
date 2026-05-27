import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/account/account_mode.dart';
import 'package:rxpro_mobile/core/account/account_mode_resolver.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/session/app_session.dart';
import 'package:rxpro_mobile/features/public_home/data/account_entry_repository.dart';

class AccountEntryContext {
  const AccountEntryContext({
    required this.user,
    required this.userData,
    required this.isBusiness,
    required this.business,
    this.accountMode = AccountMode.guest,
    this.pending = false,
  });

  final User? user;
  final Map<String, dynamic> userData;
  final bool isBusiness;
  final AccountMode accountMode;
  final AccountEntryBusinessContext? business;
  final bool pending;

  bool get canOpenOwnerManagement => accountMode.isCorporateOwner;

  bool get shouldShowStaffTasks {
    return accountMode.isCorporateOwner || accountMode.isLinkedStaff;
  }

  bool get shouldShowIndividualAccountBody {
    if (pending || user == null) return false;
    return accountMode.isIndividual || accountMode.isLinkedStaff;
  }

  String get accountBadge {
    if (pending) return 'Hesap hazırlanıyor';
    if (user == null) return AccountMode.guest.badgeLabel;
    return accountMode.badgeLabel;
  }

  factory AccountEntryContext.guest() {
    return const AccountEntryContext(
      user: null,
      userData: <String, dynamic>{},
      isBusiness: false,
      business: null,
    );
  }

  factory AccountEntryContext.pending({required User? user}) {
    return AccountEntryContext(
      user: user,
      userData: const <String, dynamic>{},
      isBusiness: false,
      business: null,
      pending: true,
    );
  }

  factory AccountEntryContext.fromSession(AppSession session, User? user) {
    final businessData = Map<String, dynamic>.from(session.businessData);
    final userData = Map<String, dynamic>.from(session.userData);
    if (session.businessId.trim().isNotEmpty) {
      businessData[FirestoreFields.businessId] = session.businessId;
    }

    final business = session.isCorporate
        ? AccountEntryBusinessContext(
            id: session.businessId,
            name: session.businessName.trim().isEmpty
                ? 'Kurumsal Kullanıcı'
                : session.businessName,
            category:
                (businessData[FirestoreFields.categoryLabel] ??
                        businessData[FirestoreFields.category] ??
                        businessData[FirestoreFields.businessCategory] ??
                        businessData['mainCategory'] ??
                        'Genel')
                    .toString(),
            data: businessData,
            source: 'AppSessionScope',
          )
        : null;

    final accountMode = AccountModeResolver.fromSession(session);

    return AccountEntryContext(
      user: user,
      userData: userData,
      isBusiness: accountMode.isCorporate,
      accountMode: accountMode,
      business: business,
    );
  }
}

class AccountEntryBusinessContext {
  const AccountEntryBusinessContext({
    required this.id,
    required this.name,
    required this.category,
    required this.data,
    required this.source,
  });

  factory AccountEntryBusinessContext.fromRepository(AccountEntryBusinessData business) {
    return AccountEntryBusinessContext(
      id: business.id,
      name: business.name,
      category: business.category,
      data: business.data,
      source: business.source,
    );
  }

  final String id;
  final String name;
  final String category;
  final Map<String, dynamic> data;
  final String source;
}
