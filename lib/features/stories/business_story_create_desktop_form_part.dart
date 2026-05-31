part of 'business_story_create_page.dart';

class _StoryBusinessHeader extends StatelessWidget {
  const _StoryBusinessHeader({
    required this.businessName,
    required this.logoUrl,
  });

  final String businessName;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    return RxDesktopPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFFE9FFF5),
            backgroundImage: logoUrl.trim().isEmpty ? null : NetworkImage(logoUrl),
            child: logoUrl.trim().isEmpty
                ? Text(
                    businessName.isEmpty ? 'F' : businessName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF17384A),
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF17384A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Keşfet hikayelerinde 24 saat görünür.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryImagePickerPanel extends StatelessWidget {
  const _StoryImagePickerPanel({
    required this.selectedImage,
    required this.onTap,
  });

  final XFile? selectedImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: RxDesktopPanel(
        padding: EdgeInsets.zero,
        radius: 18,
        child: SizedBox(
          height: 260,
          child: selectedImage == null
              ? const _StoryPickerEmptyState()
              : ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _StorySelectedImage(file: selectedImage!),
                ),
        ),
      ),
    );
  }
}

class _StoryPickerEmptyState extends StatelessWidget {
  const _StoryPickerEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 44,
            color: Color(0xFF0891B2),
          ),
          SizedBox(height: 10),
          Text(
            'Hikaye görseli seç',
            style: TextStyle(
              color: Color(0xFF17384A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Dikey 9:16 görsel en iyi sonucu verir.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCaptionField extends StatelessWidget {
  const _StoryCaptionField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 4,
      maxLines: 6,
      decoration: InputDecoration(
        labelText: 'Açıklama',
        hintText: 'Bugüne özel kampanya, duyuru veya kısa mesaj...',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
      ),
    );
  }
}

class _StoryPublishNote extends StatelessWidget {
  const _StoryPublishNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Hikayeler 24 saat sonra otomatik olarak görünmez hale gelir. Kampanya ve randevu yönlendirmeleri sonraki sürümde bu alana bağlanabilir.',
      style: TextStyle(
        color: Color(0xFF64748B),
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
