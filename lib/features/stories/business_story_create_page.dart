import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/responsive/rx_desktop_layout.dart';
import '../../core/uploads/app_image_upload_service.dart';
import 'business_story_create_controller.dart';
import 'business_story_service.dart';

part 'business_story_create_desktop_part.dart';
part 'business_story_create_desktop_form_part.dart';
part 'business_story_create_desktop_preview_part.dart';

class BusinessStoryCreatePage extends StatefulWidget {
  const BusinessStoryCreatePage({
    super.key,
    required this.businessId,
    required this.businessName,
    this.businessLogoUrl = '',
    this.category = 'Genel',
  });

  final String businessId;
  final String businessName;
  final String businessLogoUrl;
  final String category;

  @override
  State<BusinessStoryCreatePage> createState() =>
      _BusinessStoryCreatePageState();
}

class _BusinessStoryCreatePageState extends State<BusinessStoryCreatePage> {
  final TextEditingController captionController = TextEditingController();
  final BusinessStoryCreateController _controller =
      BusinessStoryCreateController();
  final ValueNotifier<int> _captionRevision = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    captionController.addListener(_handleCaptionChanged);
  }

  void _handleCaptionChanged() {
    _captionRevision.value++;
  }

  @override
  void dispose() {
    captionController.removeListener(_handleCaptionChanged);
    _captionRevision.dispose();
    _controller.dispose();
    captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await AppImageUploadService.pickFromGallery(
      imageQuality: 84,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (file == null) return;

    _controller.selectImage(file);
  }

  Future<void> _publish() async {
    if (_controller.publishing) return;

    final file = _controller.selectedImage;
    if (file == null) {
      _snack('Önce bir görsel seçmelisiniz.');
      return;
    }

    _controller.setPublishing(true);

    try {
      await BusinessStoryService.createImageStory(
        businessId: widget.businessId,
        businessName: widget.businessName,
        businessLogoUrl: widget.businessLogoUrl,
        category: widget.category,
        file: file,
        caption: captionController.text,
      );

      if (!mounted) return;

      _snack('Hikaye paylaşıldı.');
      Navigator.of(context).pop(true);
    } catch (e) {
      _snack('Hikaye paylaşılamadı: $e');
    } finally {
      if (mounted) {
        _controller.setPublishing(false);
      }
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    final useDesktopToast = MediaQuery.sizeOf(context).width >= 900;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        width: useDesktopToast ? 420 : null,
        margin: useDesktopToast ? null : const EdgeInsets.fromLTRB(16, 0, 16, 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessName = widget.businessName.trim().isEmpty
        ? 'Kurumsal Kullanıcı'
        : widget.businessName;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _captionRevision]),
      builder: (context, _) {
        final selectedImage = _controller.selectedImage;
        final publishing = _controller.publishing;

        if (wide) {
          return this._buildDesktopStoryComposer(
            businessName: businessName,
            selectedImage: selectedImage,
            publishing: publishing,
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7FBFC),
          appBar: AppBar(
            title: const Text('Hikaye Paylaş'),
            backgroundColor: const Color(0xFFF7FBFC),
            elevation: 0,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width >= 600
                    ? 640
                    : double.infinity,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDFF5FF), Color(0xFFE9FFF5)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFCDEAE4)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      backgroundImage: widget.businessLogoUrl.trim().isEmpty
                          ? null
                          : NetworkImage(widget.businessLogoUrl),
                      child: widget.businessLogoUrl.trim().isEmpty
                          ? Text(
                              businessName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF17384A),
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        businessName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF17384A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _pickImage,
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE4EBEA)),
                  ),
                  child: selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 46,
                              color: Color(0xFF4AB4C4),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Story görseli seç',
                              style: TextStyle(
                                color: Color(0xFF17384A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '24 saat boyunca Keşfet hikayelerinde görünür',
                              style: TextStyle(
                                color: Color(0xFF7A8990),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _StorySelectedImage(file: selectedImage),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: captionController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Bugüne özel kampanya, duyuru veya kısa mesaj...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hikayeler 24 saat sonra otomatik olarak görünmez hale gelir. İleride kampanya ve randevu yönlendirmeleri bu alana bağlanabilir.',
                style: TextStyle(
                  color: Color(0xFF7A8990),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width >= 600
                      ? 640
                      : double.infinity,
                ),
                child: FilledButton.icon(
              onPressed: publishing ? null : _publish,
              icon: publishing
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(publishing ? 'Yayınlanıyor...' : 'Hikayeyi Yayınla'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}
