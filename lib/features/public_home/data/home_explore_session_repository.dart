import 'package:firebase_auth/firebase_auth.dart';

class HomeExploreSessionRepository {
  HomeExploreSessionRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  String? currentUid() => _auth.currentUser?.uid;

  bool get isSignedIn => _auth.currentUser != null;

  Stream<String?> watchUid() {
    return _auth.authStateChanges().map((user) => user?.uid);
  }
}
