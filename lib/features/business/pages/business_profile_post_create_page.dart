import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/uploads/app_image_upload_service.dart';
import '../services/business_profile_post_create_service.dart';

class BusinessProfilePostCreatePage extends StatefulWidget {
  const BusinessProfilePostCreatePage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<BusinessProfilePostCreatePage> createState() =>
      _BusinessProfilePostCreatePageState();
}

class _BusinessProfilePostCreatePageState
    extends State<BusinessProfilePostCreatePage> {
  final BusinessProfilePostCreateService _postCreateService =
      BusinessProfilePostCreateService();
  final textController = TextEditingController();

  XFile? selectedImage;
  bool saving = false;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await AppImageUploadService.pickFromGallery(
      imageQuality: 82,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (file == null) return;

    setState(() => selectedImage = file);
  }

  void _showVideoSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video paylaşımı sonraki kademede açılacak.'),
      ),
    );
  }

  Future<void> _savePost() async {
    final text = textController.text.trim();

    if (text.isEmpty && selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yazı veya fotoğraf ekleyin.')),
      );
      return;
    }

    try {
      _postCreateService.ensureSignedIn();
    } on BusinessProfilePostCreateException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    setState(() => saving = true);

    try {
      String imageUrl = '';
      String thumbnailUrl = '';

      if (selectedImage != null) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();

        final upload = await AppImageUploadService.uploadBusinessIntroImageSet(
          businessId: widget.businessId,
          ownerUid: _postCreateService.requireCurrentUid(),
          file: selectedImage!,
          fileName: fileName,
        );
        imageUrl = upload.url;
        thumbnailUrl = upload.thumbnailUrl ?? '';
      }

      await _postCreateService.createPost(
        BusinessProfilePostCreateInput(
          businessId: widget.businessId,
          businessName: widget.businessName,
          text: text,
          imageUrl: imageUrl,
          thumbnailUrl: thumbnailUrl,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanıtım paylaşımı yayınlandı.')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Paylaşım oluşturulamadı: $e')));
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedImage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanıtım İçeriği Paylaş'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kurumsal tanıtım paylaşımı',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bu paylaşım kurumsal profilinizin Tanıtım sekmesinde bireysel kullanıcılara gösterilir.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    minLines: 4,
                    maxLines: 8,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      labelText: 'Paylaşım yazısı',
                      hintText:
                          'Yeni hizmet, kampanya, kurum ortamı veya duyurunuzu yazın.',
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: hasImage
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 42,
                                    color: Color(0xFF16A34A),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Fotoğraf seçildi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Değiştirmek için tekrar dokunun.',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 42,
                                    color: Color(0xFF6B7280),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Fotoğraf ekle',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Galeriden tanıtım görseli seçin.',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _showVideoSoon,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('Video ekle - yakında'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: saving ? null : _savePost,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish_rounded),
                label: Text(saving ? 'Yayınlanıyor...' : 'Paylaşımı Yayınla'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
