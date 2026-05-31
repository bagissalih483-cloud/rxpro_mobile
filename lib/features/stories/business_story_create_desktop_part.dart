part of 'business_story_create_page.dart';

extension _BusinessStoryCreateDesktop on _BusinessStoryCreatePageState {
  Widget _buildDesktopStoryComposer({
    required String businessName,
    required XFile? selectedImage,
    required bool publishing,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      body: Column(
        children: [
          RxDesktopCommandBar(
            title: 'Hikaye Paylaş',
            subtitle:
                '24 saatlik vitrin yayını için görsel, açıklama ve önizlemeyi tek ekranda yönetin.',
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Geri',
            ),
            actions: [
              FilledButton.icon(
                onPressed: publishing ? null : _publish,
                icon: publishing
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  publishing ? 'Yayınlanıyor...' : 'Hikayeyi Yayınla',
                ),
              ),
            ],
          ),
          Expanded(
            child: RxDesktopWorkArea(
              maxWidth: 1280,
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 520,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _StoryBusinessHeader(
                          businessName: businessName,
                          logoUrl: widget.businessLogoUrl,
                        ),
                        const SizedBox(height: 14),
                        _StoryImagePickerPanel(
                          selectedImage: selectedImage,
                          onTap: _pickImage,
                        ),
                        const SizedBox(height: 14),
                        _StoryCaptionField(controller: captionController),
                        const SizedBox(height: 12),
                        const _StoryPublishNote(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _StoryPreviewPanel(
                      businessName: businessName,
                      selectedImage: selectedImage,
                      caption: captionController.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
