import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as image_tools;
import 'package:image_picker/image_picker.dart';

class AppImageUploadResult {
  const AppImageUploadResult({required this.url, this.thumbnailUrl});

  final String url;
  final String? thumbnailUrl;

  String get thumbnailOrUrl {
    final cleanThumbnail = thumbnailUrl?.trim() ?? '';
    return cleanThumbnail.isEmpty ? url : cleanThumbnail;
  }
}

class AppImageUploadService {
  AppImageUploadService._();

  static const int _maxAvatarOrLogoBytes = 2 * 1024 * 1024;
  static const int _maxStandardImageBytes = 5 * 1024 * 1024;
  static const int _thumbnailMaxDimension = 480;
  static const int _thumbnailJpegQuality = 72;

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
    required String ownerUid,
    required XFile file,
  }) {
    return _uploadImage(
      storagePath: _ownerScopedBusinessPath(
        root: 'business_logos',
        ownerUid: ownerUid,
        businessId: businessId,
        fileName: 'logo.jpg',
      ),
      file: file,
      maxBytes: _maxAvatarOrLogoBytes,
      imageRole: 'business_logo',
    );
  }

  static Future<String> uploadBusinessCover({
    required String businessId,
    required String ownerUid,
    required XFile file,
  }) {
    return _uploadImage(
      storagePath: _ownerScopedBusinessPath(
        root: 'business_covers',
        ownerUid: ownerUid,
        businessId: businessId,
        fileName: 'cover.jpg',
      ),
      file: file,
      maxBytes: _maxStandardImageBytes,
      imageRole: 'business_cover',
    );
  }

  static Future<String> uploadBusinessCampaignImage({
    required String businessId,
    required String ownerUid,
    required XFile file,
    String? fileName,
  }) {
    final safeName =
        fileName ?? DateTime.now().millisecondsSinceEpoch.toString();

    return _uploadImage(
      storagePath: _ownerScopedBusinessPath(
        root: 'business_campaigns',
        ownerUid: ownerUid,
        businessId: businessId,
        fileName: '$safeName.jpg',
      ),
      file: file,
      maxBytes: _maxStandardImageBytes,
      imageRole: 'business_campaign',
    );
  }

  static Future<String> uploadBusinessStoryImage({
    required String businessId,
    required String ownerUid,
    required XFile file,
    String? fileName,
  }) {
    return uploadBusinessStoryImageSet(
      businessId: businessId,
      ownerUid: ownerUid,
      file: file,
      fileName: fileName,
    ).then((result) => result.url);
  }

  static Future<AppImageUploadResult> uploadBusinessStoryImageSet({
    required String businessId,
    required String ownerUid,
    required XFile file,
    String? fileName,
  }) {
    final safeName =
        fileName ?? DateTime.now().millisecondsSinceEpoch.toString();

    return _uploadImageSet(
      storagePath: _ownerScopedBusinessPath(
        root: 'business_stories',
        ownerUid: ownerUid,
        businessId: businessId,
        fileName: '$safeName.jpg',
      ),
      file: file,
      maxBytes: _maxStandardImageBytes,
      imageRole: 'business_story',
      createThumbnail: true,
    );
  }

  static Future<String> uploadBusinessIntroImage({
    required String businessId,
    required String ownerUid,
    required XFile file,
    String? fileName,
  }) {
    return uploadBusinessIntroImageSet(
      businessId: businessId,
      ownerUid: ownerUid,
      file: file,
      fileName: fileName,
    ).then((result) => result.url);
  }

  static Future<AppImageUploadResult> uploadBusinessIntroImageSet({
    required String businessId,
    required String ownerUid,
    required XFile file,
    String? fileName,
  }) {
    final safeName =
        fileName ?? DateTime.now().millisecondsSinceEpoch.toString();

    return _uploadImageSet(
      storagePath: _ownerScopedBusinessPath(
        root: 'business_intro',
        ownerUid: ownerUid,
        businessId: businessId,
        fileName: '$safeName.jpg',
      ),
      file: file,
      maxBytes: _maxStandardImageBytes,
      imageRole: 'business_intro',
      createThumbnail: true,
    );
  }

  static Future<String> uploadUserAvatar({
    required String uid,
    required XFile file,
  }) {
    return _uploadImage(
      storagePath: 'user_profiles/$uid/avatar.jpg',
      file: file,
      maxBytes: _maxAvatarOrLogoBytes,
      imageRole: 'user_avatar',
    );
  }

  static Future<String> _uploadImage({
    required String storagePath,
    required XFile file,
    required int maxBytes,
    required String imageRole,
  }) async {
    final result = await _uploadImageSet(
      storagePath: storagePath,
      file: file,
      maxBytes: maxBytes,
      imageRole: imageRole,
    );
    return result.url;
  }

  static Future<AppImageUploadResult> _uploadImageSet({
    required String storagePath,
    required XFile file,
    required int maxBytes,
    required String imageRole,
    bool createThumbnail = false,
  }) async {
    final length = await file.length();
    if (length > maxBytes) {
      throw StateError(
        'Gorsel cok buyuk. Lutfen daha kucuk veya sikistirilmis bir gorsel secin.',
      );
    }

    final ref = FirebaseStorage.instance.ref(storagePath);
    final contentType = _guessContentType(file.path);

    final metadata = SettableMetadata(
      contentType: contentType,
      cacheControl: 'public,max-age=604800',
      customMetadata: {
        'imageRole': imageRole,
        'sourceBytes': length.toString(),
        'uploadedBy': 'rxpro_mobile',
      },
    );

    final task = await ref
        .putFile(File(file.path), metadata)
        .catchError((Object error) {
          throw _mapUploadError(error, storagePath);
        })
        .timeout(const Duration(seconds: 45));

    final url = await task.ref.getDownloadURL().timeout(
      const Duration(seconds: 20),
    );

    if (!createThumbnail) {
      return AppImageUploadResult(url: url);
    }

    final thumbnailUrl = await _tryUploadThumbnail(
      storagePath: storagePath,
      file: file,
      sourceBytes: length,
      imageRole: imageRole,
    );

    return AppImageUploadResult(url: url, thumbnailUrl: thumbnailUrl);
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

  static Future<String?> _tryUploadThumbnail({
    required String storagePath,
    required XFile file,
    required int sourceBytes,
    required String imageRole,
  }) async {
    try {
      final thumbnailBytes = await _createThumbnailBytes(file);
      if (thumbnailBytes == null || thumbnailBytes.isEmpty) {
        return null;
      }

      final ref = FirebaseStorage.instance.ref(_thumbnailPathFor(storagePath));
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=2592000',
        customMetadata: {
          'imageRole': '${imageRole}_thumbnail',
          'sourceBytes': sourceBytes.toString(),
          'thumbnailBytes': thumbnailBytes.length.toString(),
          'uploadedBy': 'rxpro_mobile',
        },
      );

      final task = await ref
          .putData(thumbnailBytes, metadata)
          .catchError((Object error) {
            throw _mapUploadError(error, _thumbnailPathFor(storagePath));
          })
          .timeout(const Duration(seconds: 30));

      return task.ref.getDownloadURL().timeout(const Duration(seconds: 20));
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _createThumbnailBytes(XFile file) async {
    final bytes = await file.readAsBytes();
    final decoded = image_tools.decodeImage(bytes);
    if (decoded == null) return null;

    final resized = decoded.width >= decoded.height
        ? image_tools.copyResize(decoded, width: _thumbnailMaxDimension)
        : image_tools.copyResize(decoded, height: _thumbnailMaxDimension);

    final encoded = image_tools.encodeJpg(
      resized,
      quality: _thumbnailJpegQuality,
    );
    return Uint8List.fromList(encoded);
  }

  static String _thumbnailPathFor(String storagePath) {
    final slash = storagePath.lastIndexOf('/');
    final dot = storagePath.lastIndexOf('.');
    final hasExtension = dot > slash;

    if (!hasExtension) {
      return '${storagePath}_thumb.jpg';
    }

    return '${storagePath.substring(0, dot)}_thumb.jpg';
  }

  static String _ownerScopedBusinessPath({
    required String root,
    required String ownerUid,
    required String businessId,
    required String fileName,
  }) {
    final uid = _safePathSegment(ownerUid);
    final cleanBusinessId = _safePathSegment(businessId);
    final cleanFileName = _safeFileName(fileName);

    if (uid.isEmpty) {
      throw StateError('Gorsel yuklemek icin oturum gerekir.');
    }

    if (cleanBusinessId.isEmpty) {
      throw StateError('Gorsel yuklemek icin isletme bilgisi eksik.');
    }

    return '$root/$uid/$cleanBusinessId/$cleanFileName';
  }

  static Object _mapUploadError(Object error, String storagePath) {
    if (error is FirebaseException &&
        error.plugin == 'firebase_storage' &&
        error.code == 'unauthorized') {
      return StateError(
        'Gorsel yukleme yetkisi reddedildi. Oturum, App Check debug tokeni, '
        'Firebase Storage rules yayini veya sahiplik eslesmesi kontrol edilmeli. '
        'Yol: $storagePath',
      );
    }

    return error;
  }

  static String _safePathSegment(String value) {
    return value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  static String _safeFileName(String value) {
    final clean = _safePathSegment(value);
    return clean.isEmpty
        ? '${DateTime.now().millisecondsSinceEpoch}.jpg'
        : clean;
  }
}
