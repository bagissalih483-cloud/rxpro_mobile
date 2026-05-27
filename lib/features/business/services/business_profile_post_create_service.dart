import 'package:firebase_auth/firebase_auth.dart';

import '../data/business_profile_post_create_repository.dart';

class BusinessProfilePostCreateService {
  BusinessProfilePostCreateService({
    FirebaseAuth? auth,
    BusinessProfilePostCreateRepository? repository,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _repository = repository ?? BusinessProfilePostCreateRepository();

  final FirebaseAuth _auth;
  final BusinessProfilePostCreateRepository _repository;

  void ensureSignedIn() {
    if (_auth.currentUser == null) {
      throw const BusinessProfilePostCreateException(
        'Paylaşım yapmak için giriş yapın.',
      );
    }
  }

  Future<void> createPost(BusinessProfilePostCreateInput input) {
    final user = _auth.currentUser;
    if (user == null) {
      throw const BusinessProfilePostCreateException(
        'Paylaşım yapmak için giriş yapın.',
      );
    }

    final text = input.text.trim();
    final imageUrl = input.imageUrl.trim();
    if (text.isEmpty && imageUrl.isEmpty) {
      throw const BusinessProfilePostCreateException(
        'Yazı veya fotoğraf ekleyin.',
      );
    }

    return _repository.createPost(
      businessId: input.businessId.trim(),
      businessName: input.businessName.trim(),
      ownerUid: user.uid,
      text: text,
      imageUrl: imageUrl,
    );
  }
}

class BusinessProfilePostCreateInput {
  const BusinessProfilePostCreateInput({
    required this.businessId,
    required this.businessName,
    required this.text,
    required this.imageUrl,
  });

  final String businessId;
  final String businessName;
  final String text;
  final String imageUrl;
}

class BusinessProfilePostCreateException implements Exception {
  const BusinessProfilePostCreateException(this.message);

  final String message;

  @override
  String toString() => message;
}
