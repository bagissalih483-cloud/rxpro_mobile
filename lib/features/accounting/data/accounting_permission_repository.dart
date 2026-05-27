import 'package:cloud_firestore/cloud_firestore.dart';

class AccountingPermissionRepository {
  AccountingPermissionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<Map<String, dynamic>> watchUserPermissions(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      final rawPermissions = data == null ? null : data['permissions'];
      if (rawPermissions is Map) {
        return Map<String, dynamic>.from(rawPermissions);
      }
      return <String, dynamic>{};
    });
  }

  Stream<Map<String, dynamic>> watchUserPermissionData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return <String, dynamic>{};
      }
      return Map<String, dynamic>.from(data);
    });
  }
}
