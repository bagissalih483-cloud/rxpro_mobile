import 'package:firebase_auth/firebase_auth.dart';

class BusinessProfilePostSessionRepository {
  BusinessProfilePostSessionRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  String? currentUid() => _auth.currentUser?.uid;
}
