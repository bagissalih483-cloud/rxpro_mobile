part of '../../business_profile_page.dart';

bool _canEditBusinessProfile(Map<String, dynamic> data) {
  final currentUser = _BusinessHeroCard._authService.currentUser;
  final currentUid = currentUser?.uid;
  final currentEmail = currentUser?.email?.trim().toLowerCase() ?? '';

  String clean(dynamic value) => value?.toString().trim() ?? '';

  bool listContainsUid(dynamic value) {
    if (currentUid == null) return false;
    if (value is Iterable) {
      return value.map((e) => e.toString()).contains(currentUid);
    }
    return false;
  }

  final uidFields = [
    clean(data[FirestoreFields.ownerUid]),
    clean(data[FirestoreFields.ownerId]),
    clean(data[FirestoreFields.userId]),
    clean(data[FirestoreFields.uid]),
    clean(data[FirestoreFields.createdBy]),
    clean(data[FirestoreFields.creatorUid]),
    clean(data[FirestoreFields.businessOwnerUid]),
    clean(data[FirestoreFields.adminUid]),
    clean(data[FirestoreFields.managerUid]),
  ];

  final emailFields = [
    clean(data[FirestoreFields.ownerEmail]).toLowerCase(),
    clean(data[FirestoreFields.businessEmail]).toLowerCase(),
    clean(data[FirestoreFields.createdByEmail]).toLowerCase(),
    clean(data[FirestoreFields.email]).toLowerCase(),
  ];

  return currentUid != null &&
      (uidFields.contains(currentUid) ||
          listContainsUid(data[FirestoreFields.ownerUids]) ||
          listContainsUid(data[FirestoreFields.owners]) ||
          listContainsUid(data[FirestoreFields.adminUids]) ||
          listContainsUid(data[FirestoreFields.admins]) ||
          listContainsUid(data[FirestoreFields.managerUids]) ||
          listContainsUid(data[FirestoreFields.authorizedUids]) ||
          (currentEmail.isNotEmpty && emailFields.contains(currentEmail)));
}