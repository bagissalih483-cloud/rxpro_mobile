import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/businesses/business_category.dart';

class RegisteredBusinessGatewayRepository {
  RegisteredBusinessGatewayRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  bool get hasCurrentUser => _auth.currentUser != null;

  Future<List<RegisteredBusinessGatewayItem>> fetchGatewayItems() async {
    final user = _auth.currentUser;
    if (user == null) return <RegisteredBusinessGatewayItem>[];

    final items = <RegisteredBusinessGatewayItem>[];
    final seen = <String>{};

    Future<void> addOwnerDocs(String collection, String field) async {
      try {
        final snap = await _firestore
            .collection(collection)
            .where(field, isEqualTo: user.uid)
            .limit(20)
            .get();

        for (final doc in snap.docs) {
          final key = '$collection/${doc.id}';
          if (seen.contains(key)) continue;
          seen.add(key);

          final data = Map<String, dynamic>.from(doc.data());
          data[RegisteredBusinessGatewayFieldNames.businessId] ??= doc.id;

          items.add(
            RegisteredBusinessGatewayItem(
              id: doc.id,
              title: _businessTitle(data),
              subtitle: 'Kurumsal kullanıcı yönetimi',
              type: RegisteredBusinessGatewayItemType.owner,
              data: data,
            ),
          );
        }
      } catch (_) {}
    }

    Future<void> addStaffDocs(String field) async {
      try {
        final snap = await _firestore
            .collection(RegisteredBusinessGatewayCollections.businessStaff)
            .where(field, isEqualTo: user.uid)
            .limit(20)
            .get();

        for (final doc in snap.docs) {
          final key = 'staff/${doc.id}';
          if (seen.contains(key)) continue;
          seen.add(key);

          final data = Map<String, dynamic>.from(doc.data());
          data[RegisteredBusinessGatewayFieldNames.staffId] ??= doc.id;

          final businessId =
              (data[RegisteredBusinessGatewayFieldNames.businessId] ?? '')
                  .toString();

          if ((data[RegisteredBusinessGatewayFieldNames.businessName] ?? '')
                  .toString()
                  .trim()
                  .isEmpty &&
              businessId.isNotEmpty) {
            try {
              final businessDoc = await _firestore
                  .collection(RegisteredBusinessGatewayCollections.businesses)
                  .doc(businessId)
                  .get();

              final businessData = Map<String, dynamic>.from(
                businessDoc.data() ?? <String, dynamic>{},
              );

              final name = _businessTitle(businessData, fallback: '').trim();

              if (name.isNotEmpty) {
                data[RegisteredBusinessGatewayFieldNames.businessName] = name;
              }
            } catch (_) {}
          }

          final title =
              (data[RegisteredBusinessGatewayFieldNames.businessName] ??
                      'Personel Paneli')
                  .toString();

          final role =
              (data[RegisteredBusinessGatewayFieldNames.roleLabel] ??
                      data[RegisteredBusinessGatewayFieldNames.role] ??
                      'Personel')
                  .toString();

          items.add(
            RegisteredBusinessGatewayItem(
              id: doc.id,
              title: title,
              subtitle: role,
              type: RegisteredBusinessGatewayItemType.staff,
              data: data,
            ),
          );
        }
      } catch (_) {}
    }

    await addOwnerDocs(
      RegisteredBusinessGatewayCollections.businesses,
      RegisteredBusinessGatewayFieldNames.ownerUid,
    );
    await addOwnerDocs(
      RegisteredBusinessGatewayCollections.businesses,
      RegisteredBusinessGatewayFieldNames.uid,
    );
    await addOwnerDocs(
      RegisteredBusinessGatewayCollections.businessProfiles,
      RegisteredBusinessGatewayFieldNames.ownerUid,
    );
    await addOwnerDocs(
      RegisteredBusinessGatewayCollections.businessProfiles,
      RegisteredBusinessGatewayFieldNames.uid,
    );
    await addOwnerDocs(
      RegisteredBusinessGatewayCollections.registeredBusinesses,
      RegisteredBusinessGatewayFieldNames.ownerUid,
    );
    await addOwnerDocs(
      RegisteredBusinessGatewayCollections.registeredBusinesses,
      RegisteredBusinessGatewayFieldNames.uid,
    );

    await addStaffDocs(RegisteredBusinessGatewayFieldNames.linkedUid);
    await addStaffDocs(RegisteredBusinessGatewayFieldNames.staffUid);
    await addStaffDocs(RegisteredBusinessGatewayFieldNames.userId);

    return items;
  }

  Future<ResolvedRegisteredBusiness?> resolveOwnerHubBusiness({
    String? businessId,
    Map<String, dynamic>? initialData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final initialId =
        (businessId ??
                initialData?[RegisteredBusinessGatewayFieldNames.businessId] ??
                initialData?['id'] ??
                initialData?['sourceDocId'] ??
                '')
            .toString()
            .trim();

    if (initialData != null && initialId.isNotEmpty) {
      final data = Map<String, dynamic>.from(initialData);
      data[RegisteredBusinessGatewayFieldNames.businessId] = initialId;

      return ResolvedRegisteredBusiness(
        id: initialId,
        title: _businessTitle(data),
        data: data,
        source: (data['sourceCollection'] ?? 'initialData').toString(),
      );
    }

    final directIds = <String>[
      if (initialId.isNotEmpty) initialId,
      'business_${user.uid}',
      user.uid,
    ];

    for (final id in directIds) {
      for (final collection in const <String>[
        RegisteredBusinessGatewayCollections.businesses,
        RegisteredBusinessGatewayCollections.businessProfiles,
        RegisteredBusinessGatewayCollections.registeredBusinesses,
      ]) {
        try {
          final doc = await _firestore.collection(collection).doc(id).get();
          if (!doc.exists) continue;

          final data = Map<String, dynamic>.from(
            doc.data() ?? <String, dynamic>{},
          );
          final resolvedId =
              (data[RegisteredBusinessGatewayFieldNames.businessId] ?? doc.id)
                  .toString();
          data[RegisteredBusinessGatewayFieldNames.businessId] = resolvedId;

          return ResolvedRegisteredBusiness(
            id: resolvedId,
            title: _businessTitle(data),
            data: data,
            source: collection,
          );
        } catch (_) {}
      }
    }

    for (final collection in const <String>[
      RegisteredBusinessGatewayCollections.businesses,
      RegisteredBusinessGatewayCollections.businessProfiles,
      RegisteredBusinessGatewayCollections.registeredBusinesses,
    ]) {
      for (final field in const <String>[
        RegisteredBusinessGatewayFieldNames.ownerUid,
        RegisteredBusinessGatewayFieldNames.uid,
        'ownerId',
        RegisteredBusinessGatewayFieldNames.userId,
        'businessOwnerUid',
      ]) {
        try {
          final snap = await _firestore
              .collection(collection)
              .where(field, isEqualTo: user.uid)
              .limit(1)
              .get();

          if (snap.docs.isEmpty) continue;

          final doc = snap.docs.first;
          final data = Map<String, dynamic>.from(doc.data());
          final resolvedId =
              (data[RegisteredBusinessGatewayFieldNames.businessId] ?? doc.id)
                  .toString();
          data[RegisteredBusinessGatewayFieldNames.businessId] = resolvedId;

          return ResolvedRegisteredBusiness(
            id: resolvedId,
            title: _businessTitle(data),
            data: data,
            source: collection,
          );
        } catch (_) {}
      }
    }

    return null;
  }

  Future<void> updateBusinessCategory({
    required String collection,
    required String businessId,
    required BusinessCategoryOption category,
  }) async {
    final cleanCollection = collection.trim().isEmpty
        ? RegisteredBusinessGatewayCollections.businesses
        : collection.trim();
    final cleanBusinessId = businessId.trim();

    if (cleanBusinessId.isEmpty) {
      throw ArgumentError.value(businessId, 'businessId', 'must not be empty');
    }

    await _firestore.collection(cleanCollection).doc(cleanBusinessId).set(
      <String, dynamic>{
        ...category.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> syncStaffSessionCache({
    required RegisteredBusinessGatewayItem item,
    required Map<String, dynamic> permissions,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = item.data;
    final businessId =
        (data[RegisteredBusinessGatewayFieldNames.businessId] ?? '')
            .toString()
            .trim();

    if (businessId.isEmpty) return;

    final businessName = _businessTitle(data);

    await _firestore
        .collection(RegisteredBusinessGatewayCollections.users)
        .doc(user.uid)
        .set(<String, dynamic>{
          RegisteredBusinessGatewayFieldNames.uid: user.uid,
          RegisteredBusinessGatewayFieldNames.email:
              user.email ??
              data[RegisteredBusinessGatewayFieldNames.staffEmail] ??
              data[RegisteredBusinessGatewayFieldNames.email] ??
              '',
          RegisteredBusinessGatewayFieldNames.displayName:
              user.displayName ??
              data[RegisteredBusinessGatewayFieldNames.staffName] ??
              data[RegisteredBusinessGatewayFieldNames.name] ??
              'Personel',
          RegisteredBusinessGatewayFieldNames.accountKind: 'corporate',
          RegisteredBusinessGatewayFieldNames.userType: 'corporate',
          RegisteredBusinessGatewayFieldNames.activeRole: 'linkedStaff',
          RegisteredBusinessGatewayFieldNames.accountType: 'linkedStaff',
          RegisteredBusinessGatewayFieldNames.role: 'linkedStaff',
          RegisteredBusinessGatewayFieldNames.legacyRole: 'staff',
          RegisteredBusinessGatewayFieldNames.roleSchemaVersion: '49D-C',
          RegisteredBusinessGatewayFieldNames.roleUpdatedAt:
              FieldValue.serverTimestamp(),
          RegisteredBusinessGatewayFieldNames.isBusiness: true,
          RegisteredBusinessGatewayFieldNames.businessAccount: true,
          RegisteredBusinessGatewayFieldNames.isBusinessOwner: false,
          RegisteredBusinessGatewayFieldNames.businessId: businessId,
          RegisteredBusinessGatewayFieldNames.activeBusinessId: businessId,
          RegisteredBusinessGatewayFieldNames.selectedBusinessId: businessId,
          RegisteredBusinessGatewayFieldNames.staffBusinessId: businessId,
          RegisteredBusinessGatewayFieldNames.businessName: businessName,
          RegisteredBusinessGatewayFieldNames.staffId: item.id,
          RegisteredBusinessGatewayFieldNames.businessStaffId: item.id,
          RegisteredBusinessGatewayFieldNames.permissions: permissions,
          RegisteredBusinessGatewayFieldNames.updatedAt:
              FieldValue.serverTimestamp(),
          RegisteredBusinessGatewayFieldNames.staffSessionSyncedAt:
              FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static String _businessTitle(
    Map<String, dynamic> data, {
    String fallback = 'Kurumsal Kullanıcı',
  }) {
    return (data[RegisteredBusinessGatewayFieldNames.businessName] ??
            data[RegisteredBusinessGatewayFieldNames.name] ??
            data[RegisteredBusinessGatewayFieldNames.title] ??
            data[RegisteredBusinessGatewayFieldNames.displayName] ??
            fallback)
        .toString();
  }
}

class ResolvedRegisteredBusiness {
  const ResolvedRegisteredBusiness({
    required this.id,
    required this.title,
    required this.data,
    required this.source,
  });

  final String id;
  final String title;
  final Map<String, dynamic> data;
  final String source;
}

enum RegisteredBusinessGatewayItemType { owner, staff }

class RegisteredBusinessGatewayItem {
  const RegisteredBusinessGatewayItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.data,
  });

  final String id;
  final String title;
  final String subtitle;
  final RegisteredBusinessGatewayItemType type;
  final Map<String, dynamic> data;
}

class RegisteredBusinessGatewayCollections {
  const RegisteredBusinessGatewayCollections._();

  static const businesses = 'businesses';
  static const businessProfiles = 'businessProfiles';
  static const registeredBusinesses = 'registeredBusinesses';
  static const businessStaff = 'businessStaff';
  static const users = 'users';
}

class RegisteredBusinessGatewayFieldNames {
  const RegisteredBusinessGatewayFieldNames._();

  static const uid = 'uid';
  static const email = 'email';
  static const displayName = 'displayName';
  static const name = 'name';
  static const title = 'title';

  static const businesses = 'businesses';
  static const businessId = 'businessId';
  static const businessName = 'businessName';
  static const activeBusinessId = 'activeBusinessId';
  static const selectedBusinessId = 'selectedBusinessId';
  static const staffBusinessId = 'staffBusinessId';

  static const ownerUid = 'ownerUid';
  static const linkedUid = 'linkedUid';
  static const staffUid = 'staffUid';
  static const userId = 'userId';

  static const role = 'role';
  static const roleLabel = 'roleLabel';
  static const legacyRole = 'legacyRole';
  static const activeRole = 'activeRole';
  static const accountKind = 'accountKind';
  static const accountType = 'accountType';
  static const userType = 'userType';
  static const roleSchemaVersion = 'roleSchemaVersion';
  static const roleUpdatedAt = 'roleUpdatedAt';

  static const isBusiness = 'isBusiness';
  static const businessAccount = 'businessAccount';
  static const isBusinessOwner = 'isBusinessOwner';

  static const staffId = 'staffId';
  static const businessStaffId = 'businessStaffId';
  static const staffEmail = 'staffEmail';
  static const staffName = 'staffName';
  static const permissions = 'permissions';
  static const updatedAt = 'updatedAt';
  static const staffSessionSyncedAt = 'staffSessionSyncedAt';
}
