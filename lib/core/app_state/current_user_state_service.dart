import 'dart:async';

import '../app_cache/app_cache_service.dart';
import '../firestore/firestore_fields.dart';
import '../session/app_role.dart';
import '../session/session_role_policy.dart';
import 'data/current_user_state_repository.dart';

/// 49D-D2: Legacy CurrentUserState output is kept, but Firestore role resolution
/// now delegates to SessionRolePolicy so old Home/Explore state does not
/// drift away from AppSession/AppRole decisions.
class CurrentUserStateService {
  CurrentUserStateService({
    CurrentUserStateRepository? repository,
    AppCacheService? cache,
  }) : _repository = repository ?? CurrentUserStateRepository(),
       _cache = cache ?? AppCacheService();

  final CurrentUserStateRepository _repository;
  final AppCacheService _cache;

  Future<CurrentUserState> getInitialState() async {
    final firebaseUser = _repository.currentUser;
    final cachedCounts = await _cache.getUnreadCounts();

    if (firebaseUser == null) {
      await _cache.clearUserSnapshot();
      return CurrentUserState.guest();
    }

    final cached = await _cache.getUserSnapshot();

    if (cached != null && cached.uid == firebaseUser.uid) {
      final role = _normalizeRole(cached.role);

      return CurrentUserState(
        uid: cached.uid,
        email: _firstNonEmpty([firebaseUser.email, cached.email]),
        displayName: cached.safeDisplayName,
        role: role,
        isLoggedIn: true,
        isBusinessOwner: _isBusinessOwnerRole(role),
        accountStatus: 'cached',
        phone: '',
        phoneVerified: false,
        unreadMessages: cachedCounts.unreadMessages,
        unreadNotifications: cachedCounts.unreadNotifications,
        source: CurrentUserStateSource.cache,
      );
    }

    return CurrentUserState(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: _safeDisplayName(
        firebaseUser.displayName,
        firebaseUser.email,
      ),
      role: '',
      isLoggedIn: true,
      isBusinessOwner: false,
      accountStatus: 'loading',
      phone: '',
      phoneVerified: false,
      unreadMessages: cachedCounts.unreadMessages,
      unreadNotifications: cachedCounts.unreadNotifications,
      source: CurrentUserStateSource.authOnly,
    );
  }

  Stream<CurrentUserState> watch() {
    late StreamController<CurrentUserState> controller;
    StreamSubscription<CurrentUserAuthSnapshot?>? authSub;
    StreamSubscription<CurrentUserDocumentSnapshot>? userDocSub;

    Future<void> emitInitialForUser(
      CurrentUserAuthSnapshot firebaseUser,
    ) async {
      final cached = await _cache.getUserSnapshot();
      final cachedCounts = await _cache.getUnreadCounts();

      if (cached != null && cached.uid == firebaseUser.uid) {
        final role = _normalizeRole(cached.role);

        if (!controller.isClosed) {
          controller.add(
            CurrentUserState(
              uid: cached.uid,
              email: _firstNonEmpty([firebaseUser.email, cached.email]),
              displayName: cached.safeDisplayName,
              role: role,
              isLoggedIn: true,
              isBusinessOwner: _isBusinessOwnerRole(role),
              accountStatus: 'cached',
              phone: '',
              phoneVerified: false,
              unreadMessages: cachedCounts.unreadMessages,
              unreadNotifications: cachedCounts.unreadNotifications,
              source: CurrentUserStateSource.cache,
            ),
          );
        }

        return;
      }

      if (!controller.isClosed) {
        controller.add(
          CurrentUserState(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: _safeDisplayName(
              firebaseUser.displayName,
              firebaseUser.email,
            ),
            role: '',
            isLoggedIn: true,
            isBusinessOwner: false,
            accountStatus: 'loading',
            phone: '',
            phoneVerified: false,
            unreadMessages: cachedCounts.unreadMessages,
            unreadNotifications: cachedCounts.unreadNotifications,
            source: CurrentUserStateSource.authOnly,
          ),
        );
      }
    }

    controller = StreamController<CurrentUserState>.broadcast(
      onListen: () {
        authSub = _repository.watchAuthState().listen(
          (firebaseUser) async {
            await userDocSub?.cancel();
            userDocSub = null;

            if (firebaseUser == null) {
              await _cache.clearUserSnapshot();

              if (!controller.isClosed) {
                controller.add(CurrentUserState.guest());
              }

              return;
            }

            await emitInitialForUser(firebaseUser);

            userDocSub = _repository
                .watchUserDocument(firebaseUser.uid)
                .listen(
                  (snapshot) async {
                    final data = snapshot.data;

                    final displayName = _firstNonEmpty([
                      data[FirestoreFields.displayName],
                      data[FirestoreFields.fullName],
                      data[FirestoreFields.name],
                      firebaseUser.displayName,
                      firebaseUser.email,
                      'Aktif Kullanıcı',
                    ]);

                    final role = _roleFromUserData(data);

                    final accountStatus = _firstNonEmpty([
                      data[FirestoreFields.accountStatus],
                      data[FirestoreFields.status],
                      'active',
                    ]);

                    final email = _firstNonEmpty([
                      firebaseUser.email,
                      data[FirestoreFields.email],
                    ]);

                    final phone = _firstNonEmpty([
                      data[FirestoreFields.phone],
                      data[FirestoreFields.phoneNumber],
                    ]);

                    final unreadMessages = _toInt(
                      data[FirestoreFields.unreadMessageCount],
                    );
                    final unreadNotifications = _toInt(
                      data[FirestoreFields.unreadNotificationCount],
                    );

                    await _cache.saveUserSnapshot(
                      uid: firebaseUser.uid,
                      displayName: displayName,
                      role: role,
                      email: email,
                    );

                    await _cache.saveUnreadCounts(
                      unreadMessages: unreadMessages,
                      unreadNotifications: unreadNotifications,
                    );

                    if (!controller.isClosed) {
                      controller.add(
                        CurrentUserState(
                          uid: firebaseUser.uid,
                          email: email,
                          displayName: displayName,
                          role: role,
                          isLoggedIn: true,
                          isBusinessOwner: _isBusinessOwnerRole(role),
                          accountStatus: accountStatus,
                          phone: phone,
                          phoneVerified:
                              data[FirestoreFields.phoneVerified] == true,
                          unreadMessages: unreadMessages,
                          unreadNotifications: unreadNotifications,
                          source: CurrentUserStateSource.firestore,
                        ),
                      );
                    }
                  },
                  onError: (Object error) {
                    if (!controller.isClosed) {
                      controller.addError(error);
                    }
                  },
                );
          },
          onError: (Object error) {
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
        );
      },
      onCancel: () async {
        await userDocSub?.cancel();
        await authSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> clearLocalState() async {
    await _cache.clearUserSnapshot();
  }

  Future<void> refreshCacheOnce() async {
    final firebaseUser = _repository.currentUser;

    if (firebaseUser == null) {
      await _cache.clearUserSnapshot();
      return;
    }

    final snapshot = await _repository.loadUserDocument(firebaseUser.uid);
    final data = snapshot.data;

    final displayName = _firstNonEmpty([
      data[FirestoreFields.displayName],
      data[FirestoreFields.fullName],
      data[FirestoreFields.name],
      firebaseUser.displayName,
      firebaseUser.email,
      'Aktif Kullanıcı',
    ]);

    final role = _roleFromUserData(data);
    final email = _firstNonEmpty([
      firebaseUser.email,
      data[FirestoreFields.email],
    ]);

    await _cache.saveUserSnapshot(
      uid: firebaseUser.uid,
      displayName: displayName,
      role: role,
      email: email,
    );

    await _cache.saveUnreadCounts(
      unreadMessages: _toInt(data[FirestoreFields.unreadMessageCount]),
      unreadNotifications: _toInt(
        data[FirestoreFields.unreadNotificationCount],
      ),
    );
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return '';
  }

  static String _safeDisplayName(String? name, String? email) {
    final cleanName = name?.trim() ?? '';
    if (cleanName.isNotEmpty) return cleanName;

    final cleanEmail = email?.trim() ?? '';
    if (cleanEmail.isNotEmpty) return cleanEmail;

    return 'Aktif Kullanıcı';
  }

  static String _roleFromUserData(Map<String, dynamic> data) {
    final canonical = SessionRolePolicy.resolveCanonicalRole(data);
    final legacyCompatibleRole = _legacyRoleFromAppRole(canonical);

    if (legacyCompatibleRole.isNotEmpty) {
      return legacyCompatibleRole;
    }

    return _normalizeRole(
      _firstNonEmpty([
        data[FirestoreFields.role],
        data[FirestoreFields.legacyRole],
        data[FirestoreFields.activeRole],
        data[FirestoreFields.accountType],
        data[FirestoreFields.userType],
        data[FirestoreFields.accountKind],
      ]),
    );
  }

  static String _legacyRoleFromAppRole(AppRole role) {
    switch (role) {
      case AppRole.guest:
        return 'guest';
      case AppRole.individual:
        return 'customer';
      case AppRole.corporateOwner:
        return 'businessOwner';
      case AppRole.corporateStaff:
        return 'staff';
      case AppRole.admin:
        return 'admin';
      case AppRole.invalid:
        return '';
    }
  }

  static String _normalizeRole(String role) {
    final clean = role.trim();
    final normalized = clean.toLowerCase().replaceAll('_', '');

    if (normalized == 'corporateowner' ||
        normalized == 'businessowner' ||
        normalized == 'owner' ||
        normalized == 'business' ||
        normalized == 'kurumsal' ||
        normalized == 'kurumsalkullanici' ||
        normalized == 'kurumsalkullanıcı' ||
        normalized == 'isletmesahibi' ||
        normalized == 'işletmesahibi') {
      return 'businessOwner';
    }

    if (normalized == 'individual' ||
        normalized == 'customer' ||
        normalized == 'client' ||
        normalized == 'user' ||
        normalized == 'musteri' ||
        normalized == 'müşteri' ||
        normalized == 'bireysel' ||
        normalized == 'bireyselkullanici' ||
        normalized == 'bireyselkullanıcı') {
      return 'customer';
    }

    if (normalized == 'corporatestaff' ||
        normalized == 'linkedstaff' ||
        normalized == 'businessstaff' ||
        normalized == 'staff' ||
        normalized == 'personel') {
      return 'staff';
    }

    if (normalized == 'admin') {
      return 'admin';
    }

    if (normalized == 'guest' || normalized == 'misafir') {
      return 'guest';
    }

    return clean;
  }

  static bool _isBusinessOwnerRole(String role) {
    return _normalizeRole(role) == 'businessOwner';
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CurrentUserState {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final bool isLoggedIn;
  final bool isBusinessOwner;
  final String accountStatus;
  final String phone;
  final bool phoneVerified;
  final int unreadMessages;
  final int unreadNotifications;
  final CurrentUserStateSource source;

  const CurrentUserState({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isLoggedIn,
    required this.isBusinessOwner,
    required this.accountStatus,
    required this.phone,
    required this.phoneVerified,
    required this.unreadMessages,
    required this.unreadNotifications,
    required this.source,
  });

  factory CurrentUserState.guest() {
    return const CurrentUserState(
      uid: '',
      email: '',
      displayName: 'Misafir',
      role: 'guest',
      isLoggedIn: false,
      isBusinessOwner: false,
      accountStatus: 'guest',
      phone: '',
      phoneVerified: false,
      unreadMessages: 0,
      unreadNotifications: 0,
      source: CurrentUserStateSource.guest,
    );
  }

  String get roleLabel {
    switch (role) {
      case 'customer':
        return 'Bireysel Kullanıcı';
      case 'businessOwner':
        return 'Kurumsal Kullanıcı';
      case 'staff':
        return 'Personel';
      case 'admin':
        return 'Admin';
      case 'guest':
        return 'Misafir';
      default:
        return isLoggedIn ? 'Aktif Kullanıcı' : 'Misafir';
    }
  }

  String get accountStatusLabel {
    switch (accountStatus) {
      case 'pendingVerification':
        return 'Doğrulama Bekliyor';
      case 'active':
        return 'Aktif Hesap';
      case 'blocked':
        return 'Engelli';
      case 'cached':
        return 'Önbellekten Hazırlanıyor';
      case 'loading':
        return 'Hesap Bilgileri Hazırlanıyor';
      case 'guest':
        return 'Misafir';
      default:
        return isLoggedIn ? 'Aktif Hesap' : 'Misafir';
    }
  }

  String get safeEmail {
    final clean = email.trim();
    return clean.isEmpty ? '-' : clean;
  }

  String get safePhone {
    final clean = phone.trim();
    return clean.isEmpty ? '-' : clean;
  }
}

enum CurrentUserStateSource { guest, authOnly, cache, firestore }
