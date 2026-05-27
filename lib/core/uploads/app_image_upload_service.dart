import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AppImageUploadService {
  AppImageUploadService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickFromGallery({
    int imageQuality = 82,
    double? maxWidth = 1600,
    double? maxHeight = 1600,
  }) async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  static Future<String> uploadBusinessLogo({
    required String businessId,
    required XFile file,
  }) {
    return _uploadImage(
      storagePath: 'business_logos/$businessId/logo.jpg',
      file: file,
    );
  }

  static Future<String> uploadBusinessCover({
    required String businessId,
    required XFile file,
  }) {
    return _uploadImage(
      storagePath: 'business_covers/$businessId/cover.jpg',
      file: file,
    );
  }

  static Future<String> uploadBusinessCampaignImage({
    required String businessId,
    required XFile file,
    String? fileName,
  }) {
    final safeName =
        fileName ?? DateTime.now().millisecondsSinceEpoch.toString();

    return _uploadImage(
      storagePath: 'business_campaigns/$businessId/$safeName.jpg',
      file: file,
    );
  }

  static Future<String> uploadBusinessStoryImage({
    required String businessId,
    required XFile file,
    String? fileName,
  }) {
    final safeName =
        fileName ?? DateTime.now().millisecondsSinceEpoch.toString();

    return _uploadImage(
      storagePath: 'business_stories/$businessId/$safeName.jpg',
      file: file,
    );
  }

  static Future<String> uploadBusinessIntroImage({
    required String businessId,
    required XFile file,
    String? fileName,
  }) {
    final safeName =
        fileName ?? DateTime.now().millisecondsSinceEpoch.toString();

    return _uploadImage(
      storagePath: 'business_intro/$businessId/$safeName.jpg',
      file: file,
    );
  }

  static Future<String> uploadUserAvatar({
    required String uid,
    required XFile file,
  }) {
    return _uploadImage(
      storagePath: 'user_profiles/$uid/avatar.jpg',
      file: file,
    );
  }

  static Future<String> _uploadImage({
    required String storagePath,
    required XFile file,
  }) async {
    final ref = FirebaseStorage.instance.ref(storagePath);

    final metadata = SettableMetadata(
      contentType: _guessContentType(file.path),
      cacheControl: 'public,max-age=3600',
    );

    final task = await ref.putFile(File(file.path), metadata);

    return task.ref.getDownloadURL();
  }

  static String _guessContentType(String path) {
    final lower = path.toLowerCase();

    if (lower.endsWith('.png')) {
      return 'image/png';
    }

    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }

    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }

    return 'image/jpeg';
  }
}
