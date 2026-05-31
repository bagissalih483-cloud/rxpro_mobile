import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

import 'app_role.dart';
import 'app_session.dart';
import 'data/app_session_repository.dart';
import 'session_role_policy.dart';

/// 50C-Q1: App session Firestore collection/query literals use
/// FirestoreCollections/FirestoreFields constants. Session behavior is unchanged.
class AppSessionController {
  const AppSessionController._();

  static const Duration _sessionResolveTimeout = Duration(seconds: 8);
  static const Duration _businessLookupTimeout = Duration(seconds: 3);
  static final AppSessionRepository _repository = AppSessionRepository();

  static Stream<AppSession> watchForUser(User user) {
    return _repository
        .watchUserDocument(user.uid)
        .asyncMap(
          (snapshot) =>
              resolveFromUserDoc(user: user, snapshot: snapshot).timeout(
                _sessionResolveTimeout,
                onTimeout: () =>
                    _timeoutFallbackSession(user: user, snapshot: snapshot),
              ),
        );
  }

  static Future<AppSession> resolveFromUserDoc({
    required User user,
    required AppSessionUserDocument snapshot,
  }) async {
    final data = snapshot.data;

    if (!snapshot.exists || data.isEmpty) {
      return AppSession.invalid(
        uid: user.uid,
        email: user.email ?? '',
        message:
            'Kullanıcı rol belgesi bulunamadı. Lütfen çıkış yapıp tekrar giriş yapın.',
      );
    }

    final canonicalRole = _resolveCanonicalRole(data);

    if (canonicalRole == AppRole.individual) {
      return AppSession(
        role: AppRole.individual,
        isAuthenticated: true,
        uid: user.uid,
        email: user.email ?? data['email']?.toString() ?? '',
        displayName: _displayName(user, data, fallback: 'Bireysel Kullanıcı'),
        businessId: '',
        businessName: '',
        userData: data,
        businessData: const {},
        permissions: const {},
        message: '',
      );
    }

    if (canonicalRole == AppRole.corporateOwner ||
        canonicalRole == AppRole.corporateStaff) {
      final business = await _resolveBusiness(user.uid, data);
      final effectiveRole =
          _hasOwnerAuthority(
            uid: user.uid,
            userData: data,
            businessData: business.data,
          )
          ? AppRole.corporateOwner
          : canonicalRole;

      return AppSession(
        role: effectiveRole,
        isAuthenticated: true,
        uid: user.uid,
        email: user.email ?? data['email']?.toString() ?? '',
        displayName: _displayName(user, data, fallback: 'Kurumsal Kullanıcı'),
        businessId: business.id,
        businessName: business.name,
        userData: data,
        businessData: business.data,
        permissions: Map<String, dynamic>.from(data['permissions'] ?? {}),
        message: '',
      );
    }

    return AppSession.invalid(
      uid: user.uid,
      email: user.email ?? data['email']?.toString() ?? '',
      userData: data,
      message:
          'Kullanıcı rolü çözümlenemedi. users/{uid} belgesinde accountKind/role alanı eksik veya çelişkili.',
    );
  }

  static AppRole _resolveCanonicalRole(Map<String, dynamic> data) {
    return SessionRolePolicy.resolveCanonicalRole(data);
  }

  static String _displayName(
    User user,
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final values = [
      user.displayName,
      data['displayName'],
      data['fullName'],
      data['ownerName'],
      data[FirestoreFields.businessName],
      fallback,
    ];

    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }

    return fallback;
  }

  static Future<_ResolvedBusiness> _resolveBusiness(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final candidateIds = _candidateBusinessIds(data);

    for (final id in candidateIds) {
      final doc = await _safeGetBusinessDoc(id);
      if (doc == null) continue;

      return _ResolvedBusiness(
        id: doc.id,
        name: _businessName(
          doc.data,
          fallback: data[FirestoreFields.businessName],
        ),
        data: doc.data,
      );
    }

    final ownedBusiness = await _safeGetOwnedBusiness(uid);

    if (ownedBusiness != null) {
      return _ResolvedBusiness(
        id: ownedBusiness.id,
        name: _businessName(
          ownedBusiness.data,
          fallback: data[FirestoreFields.businessName],
        ),
        data: ownedBusiness.data,
      );
    }

    final fallbackId = candidateIds.isNotEmpty
        ? candidateIds.first
        : 'business_$uid';

    return _ResolvedBusiness(
      id: fallbackId,
      name: _businessName(data, fallback: 'Kurumsal Kullanıcı'),
      data: data,
    );
  }

  static bool _hasOwnerAuthority({
    required String uid,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> businessData,
  }) {
    return SessionRolePolicy.hasOwnerAuthority(
      uid: uid,
      userData: userData,
      businessData: businessData,
    );
  }

  static String _businessName(Map<String, dynamic> data, {Object? fallback}) {
    final values = [
      data[FirestoreFields.businessName],
      data[FirestoreFields.name],
      data[FirestoreFields.title],
      data['displayName'],
      fallback,
      'Kurumsal Kullanıcı',
    ];

    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }

    return 'Kurumsal Kullanıcı';
  }

  static List<String> _candidateBusinessIds(Map<String, dynamic> data) {
    return <String>[
      data[FirestoreFields.activeBusinessId]?.toString() ?? '',
      data[FirestoreFields.ownedBusinessId]?.toString() ?? '',
      data[FirestoreFields.businessId]?.toString() ?? '',
      data[FirestoreFields.selectedBusinessId]?.toString() ?? '',
      data['staffBusinessId']?.toString() ?? '',
      data['linkedBusinessId']?.toString() ?? '',
    ].where((item) => item.trim().isNotEmpty).toSet().toList();
  }

  static Future<AppSessionBusinessDocument?> _safeGetBusinessDoc(
    String id,
  ) async {
    try {
      return await _repository.loadBusinessById(
        id,
        timeout: _businessLookupTimeout,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<AppSessionBusinessDocument?> _safeGetOwnedBusiness(
    String uid,
  ) async {
    try {
      return await _repository.loadFirstOwnedBusiness(
        uid,
        timeout: _businessLookupTimeout,
      );
    } catch (_) {
      return null;
    }
  }

  static AppSession _timeoutFallbackSession({
    required User user,
    required AppSessionUserDocument snapshot,
  }) {
    final data = snapshot.data;

    if (!snapshot.exists || data.isEmpty) {
      return AppSession.invalid(
        uid: user.uid,
        email: user.email ?? '',
        message:
            'Oturum bilgileri beklenenden uzun sürdü. Lütfen tekrar deneyin.',
      );
    }

    final canonicalRole = _resolveCanonicalRole(data);

    if (canonicalRole == AppRole.individual) {
      return AppSession(
        role: AppRole.individual,
        isAuthenticated: true,
        uid: user.uid,
        email: user.email ?? data['email']?.toString() ?? '',
        displayName: _displayName(user, data, fallback: 'Bireysel Kullanıcı'),
        businessId: '',
        businessName: '',
        userData: data,
        businessData: const {},
        permissions: const {},
        message: '',
      );
    }

    if (canonicalRole == AppRole.corporateOwner ||
        canonicalRole == AppRole.corporateStaff) {
      final candidateIds = _candidateBusinessIds(data);
      final fallbackId = candidateIds.isNotEmpty
          ? candidateIds.first
          : 'business_${user.uid}';

      return AppSession(
        role: canonicalRole,
        isAuthenticated: true,
        uid: user.uid,
        email: user.email ?? data['email']?.toString() ?? '',
        displayName: _displayName(user, data, fallback: 'Kurumsal Kullanıcı'),
        businessId: fallbackId,
        businessName: _businessName(data, fallback: 'Kurumsal Kullanıcı'),
        userData: data,
        businessData: data,
        permissions: Map<String, dynamic>.from(data['permissions'] ?? {}),
        message: '',
      );
    }

    return AppSession.invalid(
      uid: user.uid,
      email: user.email ?? data['email']?.toString() ?? '',
      userData: data,
      message: 'Kullanıcı rolü zamanında çözümlenemedi. Lütfen tekrar deneyin.',
    );
  }
}

class _ResolvedBusiness {
  const _ResolvedBusiness({
    required this.id,
    required this.name,
    required this.data,
  });

  final String id;
  final String name;
  final Map<String, dynamic> data;
}
