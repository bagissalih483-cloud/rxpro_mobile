import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/firestore/firestore_schema_versions.dart';

class StaffTasksEntryRepository {
  StaffTasksEntryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<List<StaffTaskAccount>> loadStaffAccounts() async {
    final user = _auth.currentUser;
    if (user == null) return <StaffTaskAccount>[];

    final items = <StaffTaskAccount>[];
    final seen = <String>{};

    Future<void> addStaffDocsBy(String field) async {
      try {
        final snap = await _firestore
            .collection(FirestoreCollections.businessStaff)
            .where(field, isEqualTo: user.uid)
            .limit(20)
            .get();

        for (final doc in snap.docs) {
          final key = 'staff/${doc.id}';
          if (seen.contains(key)) continue;
          seen.add(key);

          final data = Map<String, dynamic>.from(doc.data());
          data[FirestoreFields.staffId] ??= doc.id;
          data[FirestoreFields.businessStaffId] ??= doc.id;

          final businessId = (data[FirestoreFields.businessId] ?? '')
              .toString()
              .trim();
          var businessName = (data[FirestoreFields.businessName] ?? '')
              .toString()
              .trim();

          if (businessName.isEmpty && businessId.isNotEmpty) {
            try {
              final businessDoc = await _firestore
                  .collection(FirestoreCollections.businesses)
                  .doc(businessId)
                  .get();
              final businessData = Map<String, dynamic>.from(
                businessDoc.data() ?? {},
              );
              businessName =
                  (businessData[FirestoreFields.businessName] ??
                          businessData[FirestoreFields.name] ??
                          businessData[FirestoreFields.title] ??
                          '')
                      .toString()
                      .trim();
              if (businessName.isNotEmpty) {
                data[FirestoreFields.businessName] = businessName;
              }
            } catch (_) {}
          }

          items.add(
            StaffTaskAccount(
              id: doc.id,
              businessName: businessName.isEmpty
                  ? 'Kurumsal kullanıcı'
                  : businessName,
              staffName:
                  (data[FirestoreFields.staffName] ??
                          data[FirestoreFields.name] ??
                          user.displayName ??
                          '')
                      .toString(),
              role:
                  (data[FirestoreFields.roleLabel] ??
                          data[FirestoreFields.role] ??
                          'Personel')
                      .toString(),
              data: data,
            ),
          );
        }
      } catch (_) {}
    }

    Future<void> addOwnerBusinessesBy(String field) async {
      try {
        final snap = await _firestore
            .collection(FirestoreCollections.businesses)
            .where(field, isEqualTo: user.uid)
            .limit(20)
            .get();

        for (final doc in snap.docs) {
          final key = 'owner/${doc.id}';
          if (seen.contains(key)) continue;
          seen.add(key);

          final businessData = Map<String, dynamic>.from(doc.data());
          final businessName =
              (businessData[FirestoreFields.businessName] ??
                      businessData[FirestoreFields.name] ??
                      businessData[FirestoreFields.title] ??
                      'Kurumsal kullanıcı')
                  .toString()
                  .trim();

          final data = <String, dynamic>{
            ...businessData,
            FirestoreFields.businessId: doc.id,
            FirestoreFields.ownedBusinessId: doc.id,
            FirestoreFields.activeBusinessId: doc.id,
            FirestoreFields.selectedBusinessId: doc.id,
            FirestoreFields.businessName: businessName.isEmpty
                ? 'Kurumsal kullanıcı'
                : businessName,
            'staffId': 'owner_${doc.id}',
            'businessStaffId': 'owner_${doc.id}',
            FirestoreFields.staffName: user.displayName ?? 'Kurumsal yetkili',
            FirestoreFields.role: 'corporateOwner',
            FirestoreFields.legacyRole: 'businessOwner',
            FirestoreFields.roleLabel: 'Kurumsal yetkili',
            FirestoreFields.accountKind: 'corporate',
            FirestoreFields.userType: 'corporate',
            FirestoreFields.accountType: 'corporateOwner',
            FirestoreFields.activeRole: 'owner',
            FirestoreFields.isBusiness: true,
            FirestoreFields.businessAccount: true,
            FirestoreFields.roleSchemaVersion: FirestoreSchemaVersions.role49dC,
            FirestoreFields.roleUpdatedAt: FieldValue.serverTimestamp(),
            FirestoreFields.isOwner: true,
            FirestoreFields.owner: true,
            FirestoreFields.isBusinessOwner: true,
            FirestoreFields.permissions: <String, dynamic>{
              'viewAppointments': true,
              'workAssignedAppointments': true,
              'canWorkAssignedAppointments': true,
              'appointmentWork': true,
              'appointmentStartFinish': true,
              'completeAssignedAppointments': true,
              'completeAnyAppointments': true,
              'manageAppointmentChanges': true,
              'canManageAppointmentChanges': true,
              'appointmentReschedule': true,
              'appointmentCancel': true,
              'canRescheduleAppointments': true,
              'canCancelAppointments': true,
              'updateAppointments': true,
              'cancelAppointments': true,
              'manageStaff': true,
              'managePermissions': true,
            },
          };

          items.add(
            StaffTaskAccount(
              id: doc.id,
              businessName: data[FirestoreFields.businessName].toString(),
              staffName: data[FirestoreFields.staffName].toString(),
              role: 'Kurumsal yetkili',
              data: data,
            ),
          );
        }
      } catch (_) {}
    }

    await addStaffDocsBy(FirestoreFields.linkedUid);
    await addStaffDocsBy(FirestoreFields.staffUid);
    await addStaffDocsBy(FirestoreFields.userId);

    await addOwnerBusinessesBy(FirestoreFields.ownerUid);
    await addOwnerBusinessesBy(FirestoreFields.ownerId);
    await addOwnerBusinessesBy(FirestoreFields.userId);
    await addOwnerBusinessesBy(FirestoreFields.uid);
    await addOwnerBusinessesBy(FirestoreFields.createdByUid);

    items.sort((a, b) => a.businessName.compareTo(b.businessName));
    return items;
  }

  Future<void> syncSession(StaffTaskAccount account) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = account.data;
    final businessId = (data[FirestoreFields.businessId] ?? '')
        .toString()
        .trim();

    final rawPermissions = data[FirestoreFields.permissions];
    final permissions = <String, dynamic>{
      if (rawPermissions is Map) ...Map<String, dynamic>.from(rawPermissions),
    };

    final canWorkAssigned =
        permissions['workAssignedAppointments'] == true ||
        permissions['canWorkAssignedAppointments'] == true ||
        permissions['appointmentWork'] == true ||
        permissions['appointmentStartFinish'] == true ||
        permissions['completeAssignedAppointments'] == true ||
        data['workAssignedAppointments'] == true ||
        data['canWorkAssignedAppointments'] == true ||
        data['appointmentWork'] == true ||
        data['appointmentStartFinish'] == true ||
        data['completeAssignedAppointments'] == true ||
        data['canManageAppointments'] == true;

    final canManageChanges =
        permissions['manageAppointmentChanges'] == true ||
        permissions['canManageAppointmentChanges'] == true ||
        permissions['appointmentReschedule'] == true ||
        permissions['appointmentCancel'] == true ||
        permissions['canRescheduleAppointments'] == true ||
        permissions['canCancelAppointments'] == true ||
        data['manageAppointmentChanges'] == true ||
        data['canManageAppointmentChanges'] == true ||
        data['appointmentReschedule'] == true ||
        data['appointmentCancel'] == true ||
        data['canRescheduleAppointments'] == true ||
        data['canCancelAppointments'] == true;

    await _firestore.collection(FirestoreCollections.users).doc(user.uid).set(
      <String, dynamic>{
        FirestoreFields.uid: user.uid,
        FirestoreFields.email:
            user.email ??
            data[FirestoreFields.staffEmail] ??
            data[FirestoreFields.email] ??
            '',
        FirestoreFields.displayName:
            user.displayName ??
            data[FirestoreFields.staffName] ??
            data[FirestoreFields.name] ??
            'Personel',
        FirestoreFields.accountKind: 'corporate',
        FirestoreFields.userType: 'corporate',
        FirestoreFields.activeRole: 'linkedStaff',
        FirestoreFields.accountType: 'linkedStaff',
        FirestoreFields.role: 'linkedStaff',
        FirestoreFields.legacyRole: 'staff',
        FirestoreFields.roleSchemaVersion: FirestoreSchemaVersions.role49dC,
        FirestoreFields.roleUpdatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.isBusiness: true,
        FirestoreFields.businessAccount: true,
        FirestoreFields.isBusinessOwner: false,
        FirestoreFields.businessId: businessId,
        FirestoreFields.activeBusinessId: businessId,
        FirestoreFields.selectedBusinessId: businessId,
        FirestoreFields.staffBusinessId: businessId,
        FirestoreFields.businessName: account.businessName,
        FirestoreFields.staffId: account.id,
        FirestoreFields.businessStaffId: account.id,
        FirestoreFields.permissions: <String, dynamic>{
          ...permissions,
          'workAssignedAppointments': canWorkAssigned,
          'canWorkAssignedAppointments': canWorkAssigned,
          'appointmentWork': canWorkAssigned,
          'appointmentStartFinish': canWorkAssigned,
          'completeAssignedAppointments': canWorkAssigned,
          'viewAppointments': canWorkAssigned,
          'manageAppointmentChanges': canManageChanges,
          'canManageAppointmentChanges': canManageChanges,
          'appointmentReschedule': canManageChanges,
          'appointmentCancel': canManageChanges,
          'canRescheduleAppointments': canManageChanges,
          'canCancelAppointments': canManageChanges,
          'updateAppointments': canManageChanges,
          'cancelAppointments': canManageChanges,
        },
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.staffTasksSyncedAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

class StaffTaskAccount {
  const StaffTaskAccount({
    required this.id,
    required this.businessName,
    required this.staffName,
    required this.role,
    required this.data,
  });

  final String id;
  final String businessName;
  final String staffName;
  final String role;
  final Map<String, dynamic> data;
}
